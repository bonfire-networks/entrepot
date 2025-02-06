defmodule Entrepot.Uploader do
  @moduledoc """
  A behaviour module for implementing custom uploaders.

  This module provides a set of callbacks and a macro for easily defining uploaders
  that work with different storage backends.
  """

  alias Entrepot.Locator

  @type storage :: atom()
  @type option :: {atom(), any()}

  @doc """
  Stores an upload in the specified storage.

  ## Parameters

  - `upload`: The upload to be stored.
  - `storage`: The storage backend to use.
  - `opts`: Optional list of options for the storage operation.

  ## Returns

  - `{:ok, Locator.t()}`: A `Locator` struct representing the stored file.
  - `{:error, any()}`: An error tuple if the storage operation fails.
  """
  @callback store(any(), storage, [option]) :: {:ok, Locator.t()} | {:error, any()}

  @doc """
  Builds options for the storage operation.

  ## Parameters

  - `upload`: The upload to be stored.
  - `storage`: The storage backend to use.
  - `opts`: Initial list of options.

  ## Returns

  - A list of options to be used in the storage operation.
  """
  @callback build_options(any(), storage, [option]) :: [option]

  @doc """
  Builds metadata for the stored file.

  ## Parameters

  - `locator`: The `Locator` struct representing the stored file.
  - `storage`: The storage backend used.
  - `opts`: The options used in the storage operation.

  ## Returns

  - A keyword list or map of metadata to be added to the `Locator`.
  """
  @callback build_metadata(Locator.t(), storage, [option]) :: Keyword.t() | map()

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Entrepot.Uploader

      @storages Keyword.fetch!(opts, :storages)

      @impl Entrepot.Uploader
      def store(upload, storage_key, opts \\ []) do
        storage = fetch_storage!(upload, storage_key)

        upload
        |> storage.put(build_options(upload, storage_key, opts))
        |> case do
          {:ok, id} ->
            Entrepot.add_metadata(
              Locator.new!(id: id, storage: storage),
              build_metadata(upload, storage_key, opts)
            )

          error_tuple ->
            error_tuple
        end
      end

      @impl Entrepot.Uploader
      def build_metadata(_, _, _), do: []

      @impl Entrepot.Uploader
      def build_options(_, _, instance_opts), do: instance_opts

      defp fetch_storage!(upload, storage) do
        @storages
        |> case do
          {m, f, a} -> apply(m, f, [upload | a])
          storages when is_list(storages) -> storages
        end
        |> Keyword.fetch(storage)
        |> case do
          {:ok, storage} ->
            storage

          _ ->
            raise "#{storage} not found in #{__MODULE__} storages. Available: #{inspect(Keyword.keys(@storages))}"
        end
      end

      defoverridable build_options: 3, build_metadata: 3
    end
  end
end
