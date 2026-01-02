defmodule TypeID.ZeroValueTest do
  use ExUnit.Case, async: true

  describe "zero/0 and zero/1" do
    test "creates zero TypeID without prefix" do
      tid = TypeID.zero()
      assert TypeID.prefix(tid) == ""
      assert TypeID.suffix(tid) == TypeID.zero_suffix()
    end

    test "creates zero TypeID with prefix" do
      tid = TypeID.zero("user")
      assert TypeID.prefix(tid) == "user"
      assert TypeID.suffix(tid) == TypeID.zero_suffix()
    end
  end

  describe "zero_suffix/0" do
    test "returns the correct constant" do
      assert TypeID.zero_suffix() == "00000000000000000000000000"
      assert byte_size(TypeID.zero_suffix()) == 26
    end
  end

  describe "has_suffix?/1" do
    test "returns false for zero suffix" do
      refute TypeID.has_suffix?(TypeID.zero())
      refute TypeID.has_suffix?(TypeID.zero("user"))
    end

    test "returns true for non-zero suffix" do
      tid = TypeID.new("user")
      assert TypeID.has_suffix?(tid)
    end
  end

  describe "is_zero?/1" do
    test "returns true only for completely zero TypeID" do
      assert TypeID.is_zero?(TypeID.zero())
    end

    test "returns false if has prefix" do
      refute TypeID.is_zero?(TypeID.zero("user"))
    end

    test "returns false if has non-zero suffix" do
      refute TypeID.is_zero?(TypeID.new(""))
      refute TypeID.is_zero?(TypeID.new("user"))
    end
  end

  describe "has_prefix?/2" do
    test "returns true for matching prefix" do
      tid = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
      assert TypeID.has_prefix?(tid, "user")
    end

    test "returns false for non-matching prefix" do
      tid = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
      refute TypeID.has_prefix?(tid, "post")
    end

    test "works with empty prefix" do
      tid = TypeID.from_string!("01h45y0sxkfmntta78gqs1vsw6")
      assert TypeID.has_prefix?(tid, "")
      refute TypeID.has_prefix?(tid, "user")
    end
  end
end
