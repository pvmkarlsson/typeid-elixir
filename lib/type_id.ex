defmodule TypeID do
  @moduledoc File.cwd!() |> Path.join("README.md") |> File.read!()

  alias TypeID.Base32
  alias TypeID.UUID

  @enforce_keys [:prefix, :suffix]
  defstruct @enforce_keys

  @typedoc """
  A TypeID struct containing a prefix and base32-encoded suffix.

  The struct fields are accessible for pattern matching:

      case tid do
        %TypeID{prefix: "user"} -> handle_user(tid)
        %TypeID{prefix: "post"} -> handle_post(tid)
      end

  However, use constructor functions (`new/1`, `from_string/1`, etc.) to create
  TypeIDs, as they perform validation.
  """
  @type t() :: %__MODULE__{
          prefix: String.t(),
          suffix: String.t()
        }

  @seperator ?_
  @zero_suffix "00000000000000000000000000"

  # ============================================================================
  # Guards
  # ============================================================================

  @doc """
  Guard clause to check if a term is a TypeID struct.

  ## Example

      defmodule MyApp.Handler do
        import TypeID, only: [is_typeid: 1]

        def process(id) when is_typeid(id), do: TypeID.prefix(id)
        def process(id) when is_binary(id), do: id |> TypeID.from_string!() |> process()
      end

  """
  defguard is_typeid(term) when is_struct(term, TypeID)

  @doc """
  Generates a new `t:t/0` with the given prefix.

  **Optional**: Specify the time of the UUID v7 by passing
  `time: unix_millisecond_time` as the second argument.

  ### Example

      iex> TypeID.new("acct")
      #TypeID<"acct_01h45y0sxkfmntta78gqs1vsw6">

  """
  @spec new(prefix :: String.t()) :: t()
  @spec new(prefix :: String.t(), Keyword.t()) :: t()
  def new(prefix, opts \\ []) do
    suffix =
      UUID.uuid7(opts)
      |> Base32.encode()

    %__MODULE__{prefix: prefix, suffix: suffix}
  end

  @doc """
  Creates a TypeID with the zero suffix (all zeros in the UUID portion).

  Useful for creating placeholder or sentinel TypeIDs.

  ## Examples

      iex> TypeID.zero()
      #TypeID<"00000000000000000000000000">

      iex> TypeID.zero("user")
      #TypeID<"user_00000000000000000000000000">

  """
  @spec zero(String.t()) :: t()
  def zero(prefix \\ "") do
    %__MODULE__{prefix: prefix, suffix: @zero_suffix}
  end

  # ============================================================================
  # Accessors
  # ============================================================================

  @doc """
  Returns the prefix of the given `t:t/0`.

  ### Example

      iex> tid = TypeID.new("doc")
      iex> TypeID.prefix(tid)
      "doc"

  """
  @spec prefix(tid :: t()) :: String.t()
  def prefix(%__MODULE__{prefix: prefix}) do
    prefix
  end

  @doc """
  Returns the base 32 encoded suffix of the given `t:t/0`

  ### Example

      iex> tid = TypeID.from_string!("invite_01h45y3ps9e18adjv9zvx743s2")
      iex> TypeID.suffix(tid)
      "01h45y3ps9e18adjv9zvx743s2"

  """
  @spec suffix(tid :: t()) :: String.t()
  def suffix(%__MODULE__{suffix: suffix}) do
    suffix
  end

  @doc """
  Returns the zero suffix constant: `"00000000000000000000000000"`
  """
  @spec zero_suffix() :: String.t()
  def zero_suffix, do: @zero_suffix

  # ============================================================================
  # Predicates
  # ============================================================================

  @doc """
  Returns `true` if the TypeID has a non-zero suffix.

  ## Examples

      iex> TypeID.has_suffix?(TypeID.zero("user"))
      false

      iex> TypeID.has_suffix?(TypeID.new("user"))
      true

  """
  @spec has_suffix?(t()) :: boolean()
  def has_suffix?(%__MODULE__{suffix: @zero_suffix}), do: false
  def has_suffix?(%__MODULE__{}), do: true

  @doc """
  Returns `true` if the TypeID is completely zero (empty prefix AND zero suffix).

  ## Examples

      iex> TypeID.is_zero?(TypeID.zero())
      true

      iex> TypeID.is_zero?(TypeID.zero("user"))
      false

      iex> TypeID.is_zero?(TypeID.new("user"))
      false

  """
  @spec is_zero?(t()) :: boolean()
  def is_zero?(%__MODULE__{prefix: "", suffix: @zero_suffix}), do: true
  def is_zero?(%__MODULE__{}), do: false

  @doc """
  Returns `true` if the TypeID has the given prefix.

  ## Examples

      iex> tid = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
      iex> TypeID.has_prefix?(tid, "user")
      true
      iex> TypeID.has_prefix?(tid, "post")
      false

  """
  @spec has_prefix?(t(), String.t()) :: boolean()
  def has_prefix?(%__MODULE__{prefix: prefix}, expected), do: prefix == expected

  @doc """
  Returns `true` if the value is a valid TypeID.

  ## Examples

      iex> TypeID.valid?("user_01h45y0sxkfmntta78gqs1vsw6")
      true

      iex> TypeID.valid?("invalid")
      false

      iex> TypeID.valid?(TypeID.new("user"))
      true

  """
  @spec valid?(t() | String.t() | any()) :: boolean()
  def valid?(%__MODULE__{}), do: true
  def valid?(str) when is_binary(str), do: match?({:ok, _}, from_string(str))
  def valid?(_), do: false

  @doc """
  Returns `true` if the string is a valid TypeID with the expected prefix.

  ## Examples

      iex> TypeID.valid?("user_01h45y0sxkfmntta78gqs1vsw6", "user")
      true

      iex> TypeID.valid?("post_01h45y0sxkfmntta78gqs1vsw6", "user")
      false

  """
  @spec valid?(String.t(), String.t()) :: boolean()
  def valid?(str, expected_prefix) when is_binary(str) and is_binary(expected_prefix) do
    match?({:ok, _}, from_string(str, expected_prefix))
  end

  # ============================================================================
  # Comparison
  # ============================================================================

  @doc """
  Compares two TypeIDs for sorting.

  TypeIDs are compared first by prefix (alphabetically), then by suffix.
  Since suffixes encode UUIDv7, same-prefix TypeIDs sort chronologically.

  ## Examples

      iex> tid1 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
      iex> tid2 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw7")
      iex> TypeID.compare(tid1, tid2)
      :lt

  ## Sorting

      Enum.sort(type_ids, TypeID)
      Enum.sort(type_ids, {:desc, TypeID})
      Enum.min(type_ids, TypeID)
      Enum.max(type_ids, TypeID)

  """
  @spec compare(t(), t()) :: :lt | :eq | :gt
  def compare(%__MODULE__{prefix: p, suffix: s1}, %__MODULE__{prefix: p, suffix: s2}) do
    cond do
      s1 < s2 -> :lt
      s1 > s2 -> :gt
      true -> :eq
    end
  end

  def compare(%__MODULE__{prefix: p1}, %__MODULE__{prefix: p2}) when p1 < p2, do: :lt
  def compare(%__MODULE__{prefix: p1}, %__MODULE__{prefix: p2}) when p1 > p2, do: :gt

  # ============================================================================
  # Serialization
  # ============================================================================

  @doc """
  Returns an `t:iodata/0` representation of the given `t:t/0`.

  ### Examples

      iex> tid = TypeID.from_string!("player_01h4rn40ybeqws3gfp073jt81b")
      iex> TypeID.to_iodata(tid)
      ["player", ?_, "01h4rn40ybeqws3gfp073jt81b"]


      iex> tid = TypeID.from_string!("01h4rn40ybeqws3gfp073jt81b")
      iex> TypeID.to_iodata(tid)
      "01h4rn40ybeqws3gfp073jt81b"

  """
  @spec to_iodata(tid :: t()) :: iodata()
  def to_iodata(%__MODULE__{prefix: "", suffix: suffix}) do
    suffix
  end

  def to_iodata(%__MODULE__{prefix: prefix, suffix: suffix}) do
    [prefix, @seperator, suffix]
  end

  @doc """
  Returns a string representation of the given `t:t/0`

  ### Example

      iex> tid = TypeID.from_string!("user_01h45y6thxeyg95gnpgqqefgpa")
      iex> TypeID.to_string(tid)
      "user_01h45y6thxeyg95gnpgqqefgpa"

  """
  @spec to_string(tid :: t()) :: String.t()
  def to_string(%__MODULE__{} = tid) do
    tid
    |> to_iodata()
    |> IO.iodata_to_binary()
  end

  @doc """
  Returns the raw binary representation of the `t:t/0`'s UUID.

  ### Example

      iex> tid = TypeID.from_string!("order_01h45y849qfqvbeayxmwkxg5x9")
      iex> TypeID.uuid_bytes(tid)
      <<1, 137, 11, 228, 17, 55, 125, 246, 183, 43, 221, 167, 39, 216, 23, 169>>

  """
  @spec uuid_bytes(tid :: t()) :: binary()
  def uuid_bytes(%__MODULE__{suffix: suffix}) do
    Base32.decode!(suffix)
  end

  @doc """
  Returns `t:t/0`'s UUID as a string.

  ### Example

      iex> tid = TypeID.from_string!("item_01h45ybmy7fj7b4r9vvp74ms6k")
      iex> TypeID.uuid(tid)
      "01890be5-d3c7-7c8e-b261-3bdd8e4a64d3"

  """
  @spec uuid(tid :: t()) :: String.t()
  def uuid(%__MODULE__{} = tid) do
    tid
    |> uuid_bytes()
    |> UUID.binary_to_string()
  end

  @doc """
  Like `from/2` but raises an error if the `prefix` or `suffix` are invalid.
  """
  @spec from!(prefix :: String.t(), suffix :: String.t()) :: t() | no_return()
  def from!(prefix, suffix) do
    validate_prefix!(prefix)
    validate_suffix!(suffix)

    %__MODULE__{prefix: prefix, suffix: suffix}
  end

  @doc """
  Parses a `t:t/0` from a prefix and suffix. 

  ### Example

      iex> {:ok, tid} = TypeID.from("invoice", "01h45ydzqkemsb9x8gq2q7vpvb")
      iex> tid
      #TypeID<"invoice_01h45ydzqkemsb9x8gq2q7vpvb">

  """
  @spec from(prefix :: String.t(), suffix :: String.t()) :: {:ok, t()} | :error
  def from(prefix, suffix) do
    {:ok, from!(prefix, suffix)}
  rescue
    ArgumentError -> :error
  end

  @doc """
  Like `from_string/1` but raises an error if the string is invalid.
  """
  @spec from_string!(String.t()) :: t() | no_return()
  def from_string!(str) when byte_size(str) <= 26, do: from!("", str)

  def from_string!(str) do
    size = byte_size(str)

    prefix =
      str
      |> binary_part(0, size - 26)
      |> String.replace(~r/_$/, "")

    suffix = binary_part(str, size - 26, 26)

    if prefix == "" do
      raise ArgumentError, "A TypeID without a prefix should not have a leading underscore"
    end

    from!(prefix, suffix)
  end

  @doc """
  Parses a `t:t/0` from a string.

  ### Example

      iex> {:ok, tid} = TypeID.from_string("game_01h45yhtgqfhxbcrsfbhxdsdvy")
      iex> tid
      #TypeID<"game_01h45yhtgqfhxbcrsfbhxdsdvy">

  """
  @spec from_string(String.t()) :: {:ok, t()} | :error
  def from_string(str) do
    {:ok, from_string!(str)}
  rescue
    ArgumentError -> :error
  end

  @doc """
  Like `from_string!/1` but also validates that the prefix matches.

  This is the recommended way to parse TypeIDs from external sources.

  ## Examples

      iex> TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6", "user")
      #TypeID<"user_01h45y0sxkfmntta78gqs1vsw6">

      iex> TypeID.from_string!("post_01h45y0sxkfmntta78gqs1vsw6", "user")
      ** (ArgumentError) prefix mismatch: expected "user", got "post"

  ## Use Case: PubSub

      def handle_info(%Broadcast{topic: "users:" <> id}, socket) do
        user_id = TypeID.from_string!(id, "user")
        {:noreply, assign(socket, :user, load_user(user_id))}
      end

  """
  @spec from_string!(String.t(), String.t()) :: t() | no_return()
  def from_string!(str, expected_prefix) when is_binary(str) and is_binary(expected_prefix) do
    tid = from_string!(str)

    if tid.prefix != expected_prefix do
      raise ArgumentError,
        "prefix mismatch: expected #{inspect(expected_prefix)}, got #{inspect(tid.prefix)}"
    end

    tid
  end

  @doc """
  Parses a TypeID from a string, validating that the prefix matches.

  Returns `{:ok, typeid}` if valid and prefix matches, `:error` otherwise.

  ## Examples

      iex> {:ok, tid} = TypeID.from_string("user_01h45y0sxkfmntta78gqs1vsw6", "user")
      iex> TypeID.prefix(tid)
      "user"

      iex> TypeID.from_string("post_01h45y0sxkfmntta78gqs1vsw6", "user")
      :error

  """
  @spec from_string(String.t(), String.t()) :: {:ok, t()} | :error
  def from_string(str, expected_prefix) when is_binary(str) and is_binary(expected_prefix) do
    case from_string(str) do
      {:ok, %__MODULE__{prefix: ^expected_prefix} = tid} -> {:ok, tid}
      {:ok, _} -> :error
      :error -> :error
    end
  end

  @doc """
  Like `from_uuid/2` but raises an error if the `prefix` or `uuid` are invalid.
  """
  @spec from_uuid!(prefix :: String.t(), uuid :: String.t()) :: t() | no_return()
  def from_uuid!(prefix, uuid) do
    uuid_bytes = UUID.string_to_binary(uuid)
    from_uuid_bytes!(prefix, uuid_bytes)
  end

  @doc """
  Parses a `t:t/0` from a prefix and a string representation of a uuid.

  ### Example

      iex> {:ok, tid} = TypeID.from_uuid("device", "01890be9-b248-777e-964e-af1d244f997d")
      iex> tid
      #TypeID<"device_01h45ykcj8exz9cknf3mj4z6bx">

  """
  @spec from_uuid(prefix :: String.t(), uuid :: String.t()) :: {:ok, t()} | :error
  def from_uuid(prefix, uuid) do
    {:ok, from_uuid!(prefix, uuid)}
  rescue
    ArgumentError -> :error
  end

  @doc """
  Like `from_uuid_bytes/2` but raises an error if the `prefix` or `uuid_bytes`
  are invalid.
  """
  @spec from_uuid_bytes!(prefix :: String.t(), uuid_bytes :: binary()) :: t() | no_return()
  def from_uuid_bytes!(prefix, <<uuid_bytes::binary-size(16)>>) do
    suffix = Base32.encode(uuid_bytes)
    from!(prefix, suffix)
  end

  @doc """
  Parses a `t:t/0` from a prefix and a raw binary uuid.

  ### Example

      iex> {:ok, tid} = TypeID.from_uuid_bytes("policy", <<1, 137, 11, 235, 83, 221, 116, 212, 161, 42, 205, 139, 182, 243, 175, 110>>)
      iex> tid
      #TypeID<"policy_01h45ypmyxekaa2apdhevf7bve">

  """
  @spec from_uuid_bytes(prefix :: String.t(), uuid_bytes :: binary()) :: {:ok, t()} | :error
  def from_uuid_bytes(prefix, uuid_bytes) do
    {:ok, from_uuid_bytes!(prefix, uuid_bytes)}
  rescue
    ArgumentError -> :error
  end

  def validate_prefix!(prefix) do
    cond do
      String.starts_with?(prefix, "_") ->
        invalid_prefix!(prefix, "cannot start with an underscore")

      String.ends_with?(prefix, "_") ->
        invalid_prefix!(prefix, "cannot end with an underscore")

      byte_size(prefix) > 63 ->
        invalid_prefix!(prefix, "cannot be more than 63 characters")

      not Regex.match?(~r/^[a-z_]*$/, prefix) ->
        invalid_prefix!(prefix, "can contain only lowercase letters and underscores")

      true ->
        :ok
    end
  end

  defp invalid_prefix!(prefix, message) do
    raise ArgumentError, "invalid prefix: #{prefix}. #{message}"
  end

  defp validate_suffix!(suffix) do
    Base32.decode!(suffix)

    :ok
  end

  # Check if Ecto is actually available by verifying the module exports the expected function
  ecto_available? =
    Code.ensure_loaded?(Ecto.ParameterizedType) and
      function_exported?(Ecto.ParameterizedType, :__using__, 1)

  if ecto_available? do
    use Ecto.ParameterizedType

    @impl Ecto.ParameterizedType
    defdelegate init(opts), to: TypeID.Ecto

    @impl Ecto.ParameterizedType
    defdelegate type(params), to: TypeID.Ecto

    @impl Ecto.ParameterizedType
    defdelegate autogenerate(params), to: TypeID.Ecto

    @impl Ecto.ParameterizedType
    defdelegate cast(data, params), to: TypeID.Ecto

    @impl Ecto.ParameterizedType
    defdelegate dump(data, dumper, params), to: TypeID.Ecto

    @impl Ecto.ParameterizedType
    defdelegate load(data, loader, params), to: TypeID.Ecto
  end
end

defimpl Inspect, for: TypeID do
  import Inspect.Algebra

  def inspect(tid, _opts) do
    concat(["#TypeID<\"", TypeID.to_string(tid), "\">"])
  end
end

defimpl String.Chars, for: TypeID do
  defdelegate to_string(tid), to: TypeID
end

if Code.ensure_loaded?(Phoenix.HTML.Safe) do
  defimpl Phoenix.HTML.Safe, for: TypeID do
    defdelegate to_iodata(tid), to: TypeID
  end
end

if Code.ensure_loaded?(Phoenix.Param) do
  defimpl Phoenix.Param, for: TypeID do
    defdelegate to_param(tid), to: TypeID, as: :to_string
  end
end

if Code.ensure_loaded?(Jason.Encoder) do
  defimpl Jason.Encoder, for: TypeID do
    def encode(tid, _opts), do: [?", TypeID.to_iodata(tid), ?"]
  end
end

# Elixir 1.18+ native JSON support
if Code.ensure_loaded?(JSON.Encoder) do
  defimpl JSON.Encoder, for: TypeID do
    def encode(tid, _opts), do: [?", TypeID.to_iodata(tid), ?"]
  end
end
