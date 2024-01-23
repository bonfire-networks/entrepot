defmodule Entrepot.UploaderTest do
  use ExUnit.Case
  doctest Entrepot

  alias Entrepot.{Locator, Uploader}

  defmodule BasicUploader do
    use Uploader, storages: [temp: Entrepot.Storages.Mock, perm: Entrepot.Storages.Mock]
  end

  defmodule DynamicUploader do
    use Uploader, storages: {__MODULE__, :get_storages, []}

    def get_storages(_), do: [temp: Entrepot.Storages.Mock]
  end

  describe "store/2 with basic uploader and valid storage key" do
    setup do
      %{result: BasicUploader.store(%Locator{id: "fake"}, :temp)}
    end

    test "succeeds", %{result: result} do
      assert {:ok, _} = result
    end

    test "returns locator", %{result: result} do
      assert {_, %Locator{}} = result
    end
  end

  describe "store/2 with basic uploader invalid storage key" do
    test "raises" do
      assert_raise(RuntimeError, fn ->
        BasicUploader.store(%Locator{id: "fake"}, :wrong)
      end)
    end
  end

  describe "store/2 with dynamic uploader and valid storage key" do
    setup do
      %{result: BasicUploader.store(%Locator{id: "fake"}, :temp)}
    end

    test "succeeds", %{result: result} do
      assert {:ok, _} = result
    end
  end
end
