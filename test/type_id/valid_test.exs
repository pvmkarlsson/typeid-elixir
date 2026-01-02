defmodule TypeID.ValidTest do
  use ExUnit.Case, async: true

  describe "valid?/1" do
    test "returns true for valid TypeID struct" do
      tid = TypeID.new("user")
      assert TypeID.valid?(tid)
    end

    test "returns true for valid TypeID string with prefix" do
      assert TypeID.valid?("user_01h45y0sxkfmntta78gqs1vsw6")
    end

    test "returns true for valid TypeID string without prefix" do
      assert TypeID.valid?("01h45y0sxkfmntta78gqs1vsw6")
    end

    test "returns false for invalid string" do
      refute TypeID.valid?("invalid")
      refute TypeID.valid?("user_invalid")
      refute TypeID.valid?("USER_01h45y0sxkfmntta78gqs1vsw6")
    end

    test "returns false for non-string values" do
      refute TypeID.valid?(123)
      refute TypeID.valid?(nil)
      refute TypeID.valid?(%{})
      refute TypeID.valid?([])
    end
  end

  describe "valid?/2" do
    test "returns true for valid TypeID with matching prefix" do
      assert TypeID.valid?("user_01h45y0sxkfmntta78gqs1vsw6", "user")
    end

    test "returns false for valid TypeID with wrong prefix" do
      refute TypeID.valid?("post_01h45y0sxkfmntta78gqs1vsw6", "user")
    end

    test "returns false for invalid TypeID" do
      refute TypeID.valid?("invalid", "user")
    end
  end
end
