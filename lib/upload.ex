defprotocol Entrepot.Upload do
  @moduledoc """
  A protocol defining the interface for file uploads.

  This protocol should be implemented by any struct that represents an uploadable file.

  There are built-in implementations for `Plug.Upload`, `File.Stream, `Stream`, `URI` and `Entrepot.Locator`.
  """

  @doc """
  Retrieves the contents of the upload.

  ## Returns

  - `{:ok, iodata()}`: The contents of the upload.
  - `{:error, String.t()}`: An error message if the contents cannot be retrieved.
  """
  @spec contents(struct()) :: {:ok, iodata()} | {:error, String.t()}
  def contents(upload)

  @doc """
  Retrieves the name of the upload.

  ## Returns

  - `String.t()`: The name of the upload.
  """
  @spec name(struct()) :: String.t()
  def name(upload)

  @doc """
  Retrieves the path of the upload, if available.

  ## Returns

  - `String.t()`: The path of the upload.
  - `nil`: If no path is available.
  """
  @spec path(struct()) :: String.t() | nil
  def path(upload)
end 

defimpl Entrepot.Upload, for: Entrepot.Locator do
  def contents(locator), do: Entrepot.storage!(locator).read(locator.id)

  def name(%{metadata: %{name: name}}), do: name
  def name(%{id: id}), do: id

  def path(%{} = locator), do: Entrepot.storage!(locator).path(locator)
end
