defmodule TypeID.FromStringPrefixTest do
  use ExUnit.Case, async: true

  describe "from_string!/2" do
    test "accepts matching prefix" do
      tid = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6", "user")
      assert TypeID.prefix(tid) == "user"
    end

    test "raises on prefix mismatch" do
      assert_raise ArgumentError, ~r/prefix mismatch/, fn ->
        TypeID.from_string!("post_01h45y0sxkfmntta78gqs1vsw6", "user")
      end
    end

    test "raises on invalid typeid" do
      assert_raise ArgumentError, fn ->
        TypeID.from_string!("invalid", "user")
      end
    end

    test "works with empty prefix" do
      tid = TypeID.from_string!("01h45y0sxkfmntta78gqs1vsw6", "")
      assert TypeID.prefix(tid) == ""
    end

    test "raises when empty prefix expected but prefix present" do
      assert_raise ArgumentError, ~r/prefix mismatch/, fn ->
        TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6", "")
      end
    end
  end

  describe "from_string/2" do
    test "returns ok tuple for matching prefix" do
      assert {:ok, tid} = TypeID.from_string("user_01h45y0sxkfmntta78gqs1vsw6", "user")
      assert TypeID.prefix(tid) == "user"
    end

    test "returns error for prefix mismatch" do
      assert :error = TypeID.from_string("post_01h45y0sxkfmntta78gqs1vsw6", "user")
    end

    test "returns error for invalid typeid" do
      assert :error = TypeID.from_string("invalid", "user")
    end
  end
end
