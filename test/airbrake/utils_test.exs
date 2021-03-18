defmodule Airbrake.UtilsTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Airbrake.Utils

  @moduletag :focus

  describe "filter/2" do
    property "returns input unchanged when attribute list is nil" do
      check all input <- term() do
        assert Utils.filter(input, nil) == input
      end
    end

    test "one big nested structure" do
      input = %{
        "foo" => "bar",
        "baz" => %{"baz" => %{"baz" => %{"quux" => 999}}},
        "qux" => %{
          "x" => 5,
          "y" => 55,
          "z" => 555
        },
        "quuz" => 123,
        "corge" => [1, 2, "three", %{"quux" => 789}]
      }

      filtered_attributes = ["qux", "quux", "quuz"]

      assert Utils.filter(input, filtered_attributes) == %{
               "foo" => "bar",
               # filters deeply...
               "baz" => %{"baz" => %{"baz" => %{"quux" => "[FILTERED]"}}},
               # filters out a whole structure...
               "qux" => "[FILTERED]",
               # filters at the top level...
               "quuz" => "[FILTERED]",
               # filters deeply in a list, repeat attribute...
               "corge" => [1, 2, "three", %{"quux" => "[FILTERED]"}]
             }
    end
  end
end
