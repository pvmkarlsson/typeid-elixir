defmodule TypeID.ComparisonTest do
  use ExUnit.Case, async: true

  describe "compare/2" do
    test "returns :eq for identical TypeIDs" do
      tid = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
      assert TypeID.compare(tid, tid) == :eq
    end

    test "compares by prefix first" do
      tid_a = TypeID.from_string!("aaa_01h45y0sxkfmntta78gqs1vsw6")
      tid_z = TypeID.from_string!("zzz_01h45y0sxkfmntta78gqs1vsw6")

      assert TypeID.compare(tid_a, tid_z) == :lt
      assert TypeID.compare(tid_z, tid_a) == :gt
    end

    test "compares by suffix when prefix matches" do
      # Earlier timestamp
      tid1 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
      # Later timestamp (higher suffix)
      tid2 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw7")

      assert TypeID.compare(tid1, tid2) == :lt
      assert TypeID.compare(tid2, tid1) == :gt
    end

    test "works with Enum.sort/2" do
      tid1 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw9")
      tid2 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
      tid3 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw7")

      sorted = Enum.sort([tid1, tid2, tid3], TypeID)

      assert sorted == [tid2, tid3, tid1]
    end

    test "works with Enum.sort/2 descending" do
      tid1 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw9")
      tid2 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
      tid3 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw7")

      sorted = Enum.sort([tid1, tid2, tid3], {:desc, TypeID})

      assert sorted == [tid1, tid3, tid2]
    end

    test "works with Enum.min/2 and Enum.max/2" do
      tid1 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw9")
      tid2 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
      tid3 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw7")

      tids = [tid1, tid2, tid3]

      assert Enum.min(tids, TypeID) == tid2
      assert Enum.max(tids, TypeID) == tid1
    end

    test "groups by prefix when sorting mixed types" do
      user1 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw9")
      user2 = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
      post1 = TypeID.from_string!("post_01h45y0sxkfmntta78gqs1vsw8")

      sorted = Enum.sort([user1, post1, user2], TypeID)

      # Posts come before users alphabetically
      assert sorted == [post1, user2, user1]
    end
  end
end
