# frozen_string_literal: true

# A tiny reader for the subset of TOML that `manifest.toml` uses.
#
# The application must run completely offline, so it does not pull in a TOML
# gem. The supported subset is: comments, `[table]` and `[table.sub]` headers,
# basic and literal strings, integers, floats, booleans and (possibly multi
# line) arrays of scalars.
class ManifestReader
  class ParseError < StandardError; end

  BASIC_ESCAPES = {
    "n" => "\n", "t" => "\t", "r" => "\r", "b" => "\b", "f" => "\f",
    '"' => '"', "\\" => "\\"
  }.freeze

  TABLE_HEADER = /\A\[([^\]]+)\]\z/
  KEY_VALUE = /\A([^=]+)=(.*)\z/m

  class << self
    # Parse a TOML document.
    #
    # @param text [String] the document
    # @return [Hash] the parsed tables
    # @raise [ParseError] when the document is malformed
    def parse(text)
      data = {}
      table = data
      pending = nil

      text.to_s.each_line do |raw_line|
        line = raw_line.strip

        if pending
          pending = "#{pending} #{line}"
        elsif line.empty? || line.start_with?("#")
          next
        else
          pending = line
        end

        next unless balanced?(pending)

        table = apply(pending, data, table)
        pending = nil
      end

      raise ParseError, "unterminated value in TOML document" if pending

      data
    end

    # Read and parse a TOML file.
    #
    # @param path [String, Pathname] the file to read
    # @return [Hash] the parsed tables
    def parse_file(path)
      parse(File.read(path.to_s, encoding: "UTF-8"))
    end

    # Whether the value of a key is complete, that is whether every bracket
    # opened in it has been closed again.
    def balanced?(text)
      depth = 0
      in_string = false
      escaped = false

      text.each_char do |char|
        if in_string
          if escaped
            escaped = false
          elsif char == "\\"
            escaped = true
          elsif char == '"'
            in_string = false
          end
          next
        end

        case char
        when '"' then in_string = true
        when "[" then depth += 1
        when "]" then depth -= 1
        end
      end

      depth.zero? && !in_string
    end

    private

    def apply(line, data, table)
      header = TABLE_HEADER.match(line)
      if header
        return descend(data, header[1].split(".").map(&:strip))
      end

      match = KEY_VALUE.match(line)
      unless match
        raise ParseError, "cannot parse TOML line: #{line.inspect}"
      end

      table[match[1].strip] = parse_value(match[2].strip)
      table
    end

    def descend(data, parts)
      parts.reduce(data) do |scope, part|
        scope[part] = {} unless scope[part].is_a?(Hash)
        scope[part]
      end
    end

    def parse_value(text)
      value = text.strip

      case value
      when /\A"(.*)"\z/m then unescape(value[1..-2])
      when /\A'(.*)'\z/m then value[1..-2]
      when /\A\[(.*)\]\z/m then parse_array(value[1..-2])
      when "true" then true
      when "false" then false
      when /\A[+-]?\d+\z/ then value.to_i
      when /\A[+-]?(\d+\.\d*|\.\d+)([eE][+-]?\d+)?\z/ then value.to_f
      when /\A[+-]?\d+[eE][+-]?\d+\z/ then value.to_f
      else value
      end
    end

    def unescape(text)
      text.gsub(/\\(u[0-9A-Fa-f]{4}|.)/) do
        sequence = Regexp.last_match(1)
        if sequence.start_with?("u")
          [sequence[1..].to_i(16)].pack("U")
        else
          BASIC_ESCAPES.fetch(sequence, sequence)
        end
      end
    end

    def parse_array(inner)
      items = []
      current = +""
      depth = 0
      in_string = false
      escaped = false

      inner.each_char do |char|
        if in_string
          current << char
          if escaped
            escaped = false
          elsif char == "\\"
            escaped = true
          elsif char == '"'
            in_string = false
          end
          next
        end

        case char
        when '"'
          in_string = true
          current << char
        when "["
          depth += 1
          current << char
        when "]"
          depth -= 1
          current << char
        when ","
          if depth.zero?
            items << current
            current = +""
          else
            current << char
          end
        else
          current << char
        end
      end

      items << current unless current.strip.empty?
      items.map { |item| parse_value(item) }
    end
  end
end
