defmodule Entrepot.Locator do
  @moduledoc """
  A struct representing a stored file's location and metadata.

  The `Locator` struct contains information about where a file is stored,
  including its unique identifier, the storage backend used, and any
  additional metadata.
  """

  defstruct [:id, :storage, metadata: %{}]

  @type t() :: %__MODULE__{
          id: String.t(),
          storage: String.t(),
          metadata: map()
        }

  @doc """
  Creates a new Locator struct, raising an error if the input is invalid.

  ## Parameters

  - `attrs`: A map or keyword list of attributes for the Locator.

  ## Returns

  - A new `Locator` struct.

  ## Raises

  - `Entrepot.Errors.InvalidLocator`: If the input is invalid.

  ## Examples

      iex> Entrepot.Locator.new!(id: "file.txt", storage: Disk)
      %Entrepot.Locator{id: "file.txt", storage: Disk, metadata: %{}}

      iex> Entrepot.Locator.new!(id: 123, storage: Disk)
      ** (Entrepot.Errors.InvalidLocator) id must be binary
  """
  def new!(attrs) do
    case new(attrs) do
      {:ok, locator} -> locator
      {:error, error} -> raise(Entrepot.Errors.InvalidLocator, error)
    end
  end

  @doc """
  Creates a new Locator struct.

  ## Parameters

  - `attrs`: A map or keyword list of attributes for the Locator.

  ## Returns

  - `{:ok, Locator.t()}`: A new `Locator` struct.
  - `{:error, String.t()}`: An error message if the input is invalid.

  ## Examples

      iex> Entrepot.Locator.new(id: "file.txt", storage: Disk)
      {:ok, %Entrepot.Locator{id: "file.txt", storage: Disk, metadata: %{}}}

      iex> Entrepot.Locator.new(id: 123, storage: Disk)
      {:error, "id must be binary"}
  """
  def new(attrs) when is_list(attrs),
    do: attrs |> Map.new() |> new()

  def new(map = %{"id" => id, "storage" => storage}),
    do: new(%{id: id, storage: storage, metadata: Map.get(map, "metadata")})

  def new(map) when is_map_key(map, :id) and is_map_key(map, :storage) do
    __MODULE__
    |> struct(map)
    |> validate()
  end

  def new(_), do: {:error, "data must contain id and storage keys"}

  defp validate(%{id: id}) when not is_binary(id), do: {:error, "id must be binary"}

  defp validate(%{storage: storage})
       when (not is_binary(storage) and not is_atom(storage)) or is_nil(storage),
       do: {:error, "storage must be string or atom"}

  defp validate(struct), do: {:ok, struct}
end
