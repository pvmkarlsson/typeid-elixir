defmodule TypeID.JSONEncoderTest do
  use ExUnit.Case, async: true

  # Test native JSON module if available (Elixir 1.18+)
  if Code.ensure_loaded?(JSON) do
    describe "JSON.Encoder (Elixir 1.18+)" do
      test "encodes TypeID to JSON string" do
        tid = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
        assert JSON.encode!(tid) == ~s("user_01h45y0sxkfmntta78gqs1vsw6")
      end

      test "encodes TypeID without prefix" do
        tid = TypeID.from_string!("01h45y0sxkfmntta78gqs1vsw6")
        assert JSON.encode!(tid) == ~s("01h45y0sxkfmntta78gqs1vsw6")
      end

      test "encodes in nested structures" do
        tid = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
        data = %{id: tid, name: "Alice"}

        result = JSON.encode!(data)
        assert result =~ ~s("id":"user_01h45y0sxkfmntta78gqs1vsw6")
        assert result =~ ~s("name":"Alice")
      end

      test "round-trip encode/decode" do
        original = "user_01h45y0sxkfmntta78gqs1vsw6"
        tid = TypeID.from_string!(original)

        encoded = JSON.encode!(tid)
        decoded = JSON.decode!(encoded)

        assert decoded == original
      end
    end
  end
end
