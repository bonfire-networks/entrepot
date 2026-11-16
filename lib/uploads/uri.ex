defimpl Entrepot.Upload, for: URI do
  # The fetch can be replaced with `config :entrepot, :uri_fetcher, {Module, :function}`, where the function takes the `%URI{}` and returns `{:ok, body}` or `{:error, reason}`. Without it the URI is fetched with `:httpc`, which does not restrict the target host, the redirects or the size of the body.
  def contents(name) do
    case Application.get_env(:entrepot, :uri_fetcher) do
      {mod, fun} -> apply(mod, fun, [name])
      _ -> httpc_contents(name)
    end
  end

  defp httpc_contents(name) do
    download =
      Task.async(fn ->
        :httpc.request(:get, {name |> URI.to_string() |> String.to_charlist(), []}, [],
          body_format: :binary
        )
      end)

    case download |> Task.await(15_000) do
      {:ok, {{~c"HTTP/1.1", 200, ~c"OK"}, _headers, body}} ->
        {:ok, body}

      {:ok, {{~c"HTTP/1.1", code, _}, _headers, _}} ->
        {:error, "Unsuccessful response code: #{code}"}

      {:error, {reason, _}} ->
        {:error, reason}
    end
  end

  def path(_) do
    nil
  end

  def name(%{path: path}), do: Path.basename(path)
end
