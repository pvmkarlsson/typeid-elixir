defmodule TypeID.Error do
  @moduledoc """
  Exception raised for TypeID validation errors.

  This exception provides structured error information for programmatic
  handling while also producing human-readable messages.

  ## Fields

  - `:message` - Human-readable error message
  - `:kind` - Error category atom for pattern matching
  - `:value` - The invalid value that caused the error

  ## Error Kinds

  - `:invalid_prefix` - Prefix contains invalid characters or is too long
  - `:invalid_suffix` - Suffix is not valid base32 or wrong length
  - `:prefix_mismatch` - Parsed prefix doesn't match expected prefix
  - `:parse_error` - General parsing failure

  ## Example

      try do
        TypeID.from_string!("invalid")
      rescue
        e in TypeID.Error ->
          case e.kind do
            :invalid_suffix -> handle_bad_suffix(e.value)
            :invalid_prefix -> handle_bad_prefix(e.value)
            _ -> reraise e, __STACKTRACE__
          end
      end

  """

  defexception [:message, :kind, :value]

  @type kind :: :invalid_prefix | :invalid_suffix | :prefix_mismatch | :parse_error

  @type t :: %__MODULE__{
          message: String.t(),
          kind: kind(),
          value: term()
        }

  @impl true
  def exception(opts) when is_list(opts) do
    kind = Keyword.fetch!(opts, :kind)
    value = Keyword.get(opts, :value)
    message = Keyword.get_lazy(opts, :message, fn -> default_message(kind, value) end)

    %__MODULE__{message: message, kind: kind, value: value}
  end

  defp default_message(:invalid_prefix, prefix) do
    "invalid prefix: #{inspect(prefix)}"
  end

  defp default_message(:invalid_suffix, suffix) do
    "invalid suffix: #{inspect(suffix)}"
  end

  defp default_message(:prefix_mismatch, {expected, actual}) do
    "prefix mismatch: expected #{inspect(expected)}, got #{inspect(actual)}"
  end

  defp default_message(:parse_error, value) do
    "failed to parse TypeID from #{inspect(value)}"
  end

  defp default_message(_kind, _value) do
    "TypeID validation error"
  end
end
