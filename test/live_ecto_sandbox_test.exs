defmodule LiveEctoSandboxTest do
  use ExUnit.Case
  doctest LiveEctoSandbox

  test "greets the world" do
    assert LiveEctoSandbox.hello() == :world
  end
end
