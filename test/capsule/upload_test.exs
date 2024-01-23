defmodule Entrepot.UploadTest do
  use ExUnit.Case
  doctest Entrepot

  alias Entrepot.{Upload, Locator}

  describe "Locator" do
    test "name returns name metadata if present" do
      assert "test" = Upload.name(%Locator{metadata: %{name: "test"}})
    end
  end
end
