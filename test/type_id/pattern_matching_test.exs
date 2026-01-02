defmodule TypeID.PatternMatchingTest do
  use ExUnit.Case, async: true

  describe "struct pattern matching" do
    test "can match on prefix in case" do
      tid = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")

      result =
        case tid do
          %TypeID{prefix: "user"} -> :user
          %TypeID{prefix: "post"} -> :post
          _ -> :other
        end

      assert result == :user
    end

    test "can extract suffix in pattern" do
      tid = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")

      %TypeID{suffix: suffix} = tid
      assert suffix == "01h45y0sxkfmntta78gqs1vsw6"
    end

    test "can extract both prefix and suffix" do
      tid = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")

      %TypeID{prefix: prefix, suffix: suffix} = tid
      assert prefix == "user"
      assert suffix == "01h45y0sxkfmntta78gqs1vsw6"
    end

    test "can use in function heads" do
      user_tid = TypeID.from_string!("user_01h45y0sxkfmntta78gqs1vsw6")
      post_tid = TypeID.from_string!("post_01h45y0sxkfmntta78gqs1vsw6")

      assert handle_entity(user_tid) == {:user, user_tid}
      assert handle_entity(post_tid) == {:post, post_tid}
    end
  end

  # Helper functions
  defp handle_entity(%TypeID{prefix: "user"} = tid), do: {:user, tid}
  defp handle_entity(%TypeID{prefix: "post"} = tid), do: {:post, tid}
  defp handle_entity(_), do: :unknown
end
