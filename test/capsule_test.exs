defmodule CapsuleTest do
  use ExUnit.Case
  doctest Entrepot

  alias Entrepot.Locator

  describe "add_metadata/2 with map" do
    test "merges data into existing metadata" do
      assert {:ok, %{metadata: %{a: 1, b: 2}}} =
               Entrepot.add_metadata(%Locator{metadata: %{a: 1}}, %{b: 2})
    end
  end

  describe "add_metadata/2 with list" do
    test "merges data into existing metadata" do
      assert {:ok, %{metadata: %{a: 1, b: 2}}} =
               Entrepot.add_metadata(%Locator{metadata: %{a: 1}}, b: 2)
    end
  end

  describe "add_metadata/3" do
    test "merges val into existing metadata at given key" do
      assert {:ok, %{metadata: %{a: 1, b: 2}}} =
               Entrepot.add_metadata(%Locator{metadata: %{a: 1}}, :b, 2)
    end
  end

  describe "storage!/1 with binary storage" do
    test "returns storage module" do
      assert Entrepot.Storages.Mock =
               Entrepot.storage!(%Locator{storage: "Elixir.Entrepot.Storages.Mock"})
    end

    test "handles storage without Elixir prefix" do
      assert Entrepot.Storages.Mock =
               Entrepot.storage!(%Locator{storage: "Entrepot.Storages.Mock"})
    end

    test "raises error on invalid storage" do
      assert_raise Entrepot.Errors.InvalidStorage, fn ->
        Entrepot.storage!(%Locator{storage: "what"})
      end
    end
  end

  describe "storage!/1 with atom storage" do
    test "returns storage module" do
      assert Entrepot.Storages.Mock = Entrepot.storage!(%Locator{storage: Entrepot.Storages.Mock})
    end

    test "returns module" do
      assert Entrepot.Storages.Mock =
               Entrepot.storage!(%Locator{storage: "Entrepot.Storages.Mock"})
    end
  end
end
