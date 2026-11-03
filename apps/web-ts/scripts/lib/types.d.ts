/**
 * Shared types for the build tooling.
 *
 * These live in a declaration file because JSDoc type aliases cannot be
 * recursive, while the value shapes produced by the YAML and TOML readers
 * are.
 */

/** A scalar YAML value. */
export type YamlScalar = string | number | boolean | null;

/** Any value a YAML document can hold. */
export type YamlValue = YamlScalar | YamlValue[] | { [key: string]: YamlValue };

/** A scalar TOML value. */
export type TomlScalar = string | number | boolean;

/** Any value a TOML document can hold. */
export type TomlValue = TomlScalar | TomlValue[] | { [key: string]: TomlValue };
