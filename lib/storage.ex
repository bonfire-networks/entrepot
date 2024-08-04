defmodule Entrepot.Storage do
  @moduledoc """
  A behaviour module defining the interface for storage backends.

  This module specifies the callbacks that must be implemented by any storage backend
  used with Entrepôt.
  """

  alias Entrepot.Upload

  @type option :: {atom(), any()}
  @type locator_id :: String.t()

  @doc """
  Generates a URL for accessing the stored file.

  ## Parameters

  - `locator_id`: The unique identifier of the stored file.
  - `opts`: Optional list of options.

  ## Returns

  - `binary()`: The URL for accessing the file.
  - `nil`: If a URL cannot be generated.
  """
  @callback url(locator_id, [option]) :: binary() | nil
  @callback url(locator_id) :: binary() | nil

  @doc """
  Retrieves the local filesystem path of the stored file, if applicable.

  ## Parameters

  - `locator_id`: The unique identifier of the stored file.
  - `opts`: Optional list of options.

  ## Returns

  - `binary()`: The local filesystem path of the file.
  - `nil`: If a local path is not applicable or available.
  """
  @callback path(locator_id, [option]) :: binary() | nil
  @callback path(locator_id) :: binary() | nil

  @doc """
  Reads the contents of the stored file.

  ## Parameters

  - `locator_id`: The unique identifier of the stored file.
  - `opts`: Optional list of options.

  ## Returns

  - `{:ok, binary()}`: The contents of the file.
  - `{:error, String.t()}`: An error message if the file cannot be read.
  """
  @callback read(locator_id, [option]) :: {:ok, binary()} | {:error, String.t()}
  @callback read(locator_id) :: {:ok, binary()} | {:error, String.t()}

  @doc """
  Creates a stream for reading the contents of the stored file.

  ## Parameters

  - `locator_id`: The unique identifier of the stored file.
  - `opts`: Optional list of options.

  ## Returns

  - `IO.Stream.t()` | `File.Stream.t()` | `Stream.t()`: A stream for reading the file contents.
  """
  @callback stream(locator_id, [option]) :: IO.Stream.t() | File.Stream.t() | Stream.t()
  @callback stream(locator_id) :: IO.Stream.t() | File.Stream.t() | Stream.t()

  @doc """
  Stores a file in the storage backend.

  ## Parameters

  - `upload`: An `Upload` struct representing the file to be stored.
  - `opts`: Optional list of options.

  ## Returns

  - `{:ok, locator_id}`: The unique identifier of the stored file.
  - `{:error, String.t()}`: An error message if the file cannot be stored.
  """
  @callback put(Upload.t(), [option]) :: {:ok, locator_id} | {:error, String.t()}
  @callback put(Upload.t()) :: {:ok, locator_id} | {:error, String.t()}

  @doc """
  Deletes a file from the storage backend.

  ## Parameters

  - `locator_id`: The unique identifier of the file to be deleted.
  - `opts`: Optional list of options.

  ## Returns

  - `:ok`: If the file was successfully deleted.
  - `{:error, String.t()}`: An error message if the file cannot be deleted.
  """
  @callback delete(locator_id, [option]) :: :ok | {:error, String.t()}
  @callback delete(locator_id) :: :ok | {:error, String.t()}
end
