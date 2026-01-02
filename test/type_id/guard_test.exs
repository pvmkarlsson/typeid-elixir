defmodule TypeID.GuardTest do
  use ExUnit.Case, async: true

  import TypeID, only: [is_typeid: 1]

  describe "is_typeid/1 guard" do
    test "returns true for TypeID struct" do
      tid = TypeID.new("user")
      assert is_typeid(tid)
    end

    test "returns false for other values" do
      refute is_typeid("string")
      refute is_typeid(123)
      refute is_typeid(nil)
      refute is_typeid(%{})
      refute is_typeid([])
    end

    test "can be used in function heads" do
      assert process_id(TypeID.new("user")) == :typeid
      assert process_id("string") == :string
      assert process_id(123) == :other
    end
  end

  # Helper functions for testing guard in function heads
  defp process_id(id) when is_typeid(id), do: :typeid
  defp process_id(id) when is_binary(id), do: :string
  defp process_id(_), do: :other
end
