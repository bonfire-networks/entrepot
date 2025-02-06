defimpl Entrepot.Upload, for: Plug.Upload do
  def path(%{path: path}) when is_binary(path) do
    case File.exists?(path) do
      false -> nil
      true -> path
    end
  end

  def contents(%{path: path}) do
    case File.read(path) do
      {:error, reason} -> {:error, "Could not read path: #{reason}"}
      success_tuple -> success_tuple
    end
  end

  def name(%{filename: name}), do: name
end
