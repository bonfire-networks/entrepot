defmodule Entrepot do
  @moduledoc "./README.md" |> File.stream!() |> Enum.drop(1) |> Enum.join()

  # This module provides cross-location functionality, such as copying files between storages.

  alias Entrepot.Locator
  alias Entrepot.Errors.InvalidStorage

  @doc """
  Copies a file from one storage to another.

  ## Parameters

  - `locator`: A `Locator` struct representing the file to be copied.
  - `dest_storage`: The destination storage module.
  - `opts`: Optional keyword list of options to be passed to the storage modules.

  ## Returns

  - `{:ok, Locator.t()}`: A new `Locator` struct for the copied file.
  - `{:error, term()}`: An error tuple if the copy operation fails.

  ## Raises

  - Raises an error if attempting to copy a file to the same storage.

  ## Examples

      iex> Entrepot.copy(%Locator{id: "file.txt", storage: Disk}, S3)
      {:ok, %Locator{id: "new_id", storage: S3, metadata: %{copied_from: Disk}}}
  """
  def copy(locator, dest_storage, opts \\ [])

  def copy(%Locator{storage: source_storage}, dest_storage, _opts)
      when source_storage == dest_storage do
    raise "Use `#{source_storage.clone / 3}` when you want to clone a file on the same storage"
  end

  def copy(%Locator{id: id} = locator, dest_storage, opts) do
    source_storage = storage!(locator)

    id
    |> source_storage.stream(opts)
    |> dest_storage.put(Keyword.put(opts, :name, id))
    |> case do
      {:ok, id} ->
        Entrepot.add_metadata(
          Locator.new!(id: id, storage: dest_storage),
          %{copied_from: source_storage}
        )

      error_tuple ->
        error_tuple
    end
  end

  @doc """
  Adds metadata to a Locator.

  ## Parameters

  - `locator`: A `Locator` struct to which metadata will be added.
  - `key`: A key for the metadata (when adding a single key-value pair).
  - `val`: A value for the metadata (when adding a single key-value pair).
  - `data`: A map or keyword list of metadata to be added.

  ## Returns

  - `{:ok, Locator.t()}`: An updated `Locator` struct with the new metadata.
  - `{:error, term()}`: The original error tuple if given an error tuple.

  ## Examples

      iex> Entrepot.add_metadata(%Locator{}, :key, "value")
      {:ok, %Locator{metadata: %{key: "value"}}}

      iex> Entrepot.add_metadata(%Locator{key: "value"}, %{key2: "value2"})
      {:ok, %Locator{metadata: %{key: "value1", key2: "value2"}}}
  """
  def add_metadata(%Locator{} = locator, key, val),
    do: add_metadata(locator, %{key => val})

  def add_metadata(%Locator{} = locator, data) when is_list(data),
    do: add_metadata(locator, Enum.into(data, %{}))

  def add_metadata(%Locator{} = locator, data) when is_map(data),
    do: {:ok, %{locator | metadata: locator.metadata |> Map.merge(data)}}

  def add_metadata(_locator, {:error, e}), do: {:error, e}

  @doc """
  Resolves the storage module from a Locator.

  ## Parameters

  - `locator`: A `Locator` struct containing the storage information.

  ## Returns

  - The resolved storage module as an atom.

  ## Raises

  - `InvalidStorage`: If the storage module cannot be resolved.

  ## Examples

      iex> Entrepot.storage!(%Locator{storage: Disk})
      Disk

      iex> Entrepot.storage!(%Locator{storage: "Elixir.Disk"})
      Disk
  """
  def storage!(%Locator{storage: module_name}) when is_binary(module_name) do
    module_name
    |> String.replace_prefix("", "Elixir.")
    |> String.replace_prefix("Elixir.Elixir", "Elixir")
    |> String.to_existing_atom()
  rescue
    ArgumentError -> raise InvalidStorage
  end

  def storage!(%Locator{storage: module_name}) when is_atom(module_name), do: module_name
end
