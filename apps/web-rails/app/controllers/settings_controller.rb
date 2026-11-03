# frozen_string_literal: true

# The preferences of the reader: the interface language and the theme.
#
# Both are stored in a cookie and both are applied by the server, so the
# application works without any client side script.
class SettingsController < ApplicationController
  # Switch the interface language.
  def language
    code = params[:lang].to_s.downcase
    code = corpus.default_language unless available_languages.include?(code)

    cookies[:abook_lang] = {
      value: code,
      expires: PREFERENCE_TTL.from_now,
      same_site: :lax,
      httponly: true
    }

    redirect_to return_path
  end

  # Switch the theme.
  #
  # `light` and `dark` set the manual override; `system` removes it, so that
  # the reader follows the preference of the operating system again.
  def theme
    value = params[:theme].to_s
    value = "light" unless %w[light dark system].include?(value)

    if value == "system"
      cookies.delete(:abook_theme)
    else
      cookies[:abook_theme] = {
        value: value,
        expires: PREFERENCE_TTL.from_now,
        same_site: :lax,
        httponly: true
      }
    end

    redirect_to return_path
  end

  private

  # The page the reader came from.
  #
  # Only a path inside this application is accepted, so that the switcher
  # cannot be used to send the reader to another site.
  #
  # @return [String] the path to redirect to
  def return_path
    target = params[:return_to].to_s
    return root_path unless target.start_with?("/")
    return root_path if target.start_with?("//", "/\\")
    return root_path if target.match?(/[\r\n]/)

    target
  end
end
