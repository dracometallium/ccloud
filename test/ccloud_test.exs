defmodule CcloudTest do
  use ExUnit.Case
  doctest Ccloud

  test "greets the world" do
    assert Ccloud.hello() == :world
  end
end
