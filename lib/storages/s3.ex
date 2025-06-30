defmodule Entrepot.Storages.S3 do
  alias Entrepot.{Storage, Upload}

  @behaviour Storage

  alias ExAws.S3, as: Client

  @impl Storage
  def put(upload, opts \\ []) do
    key = Path.join(opts[:prefix] || "/", Upload.name(upload))

    case do_put(opts[:upload_with], upload, key, opts) do
      {:ok, _} -> {:ok, key}
      error -> handle_error(error)
    end
  end

  def clone(source_id, dest_path, opts \\ []) do
    opts = config(opts)
    default_bucket = Keyword.get(opts, :bucket)

    case Client.put_object_copy(
           Keyword.get(opts, :dest_bucket) || default_bucket,
           dest_path,
           Keyword.get(opts, :source_bucket) || default_bucket,
           source_id
         )
         |> ex_aws_module().request(opts) do
      {:ok, _} -> {:ok, dest_path}
      error -> handle_error(error)
    end
  end

  @impl Storage
  def delete(id, opts \\ []) do
    case Client.delete_object(config(opts, :bucket), id)
         |> ex_aws_module().request(opts) do
      {:ok, _} -> :ok
      error -> handle_error(error)
    end
  end

  @impl Storage
  def stream(id, opts \\ []) do
    Client.download_file(config(opts, :bucket), id, :memory)
    |> ex_aws_module().stream!()
  end

  @impl Storage
  def read(id, opts \\ []) do
    case Client.get_object(config(opts, :bucket), id) |> ex_aws_module().request(opts) do
      {:ok, %{body: contents}} -> {:ok, contents}
      error -> handle_error(error)
    end
  end

  @impl Storage
  def url(path, opts \\ []) do
    opts = prepare_url_opts(opts)
    |> IO.inspect(label: "S3 URL opts")

    if Keyword.get(opts, :unsigned) do
      unsigned_url(path, opts)
    else
      signed_url(path, opts)
    end
  end

  defp signed_url(path, opts) do
    opts = opts
    |> Keyword.put_new(:expires_in, 7200) # set a default just in case none is configured

    case ExAws.Config.new(:s3, opts)
        |> Client.presigned_url(:get, Keyword.fetch!(opts, :bucket), path, opts) do
      {:ok, url} -> 
        {:ok, url}
      error -> handle_error(error)
    end
  end

  defp unsigned_url(path, opts) do
    {:ok, prepare_unsigned_url(
      Keyword.fetch!(opts, :bucket), 
      path, 
      ExAws.Config.new(:s3, opts), 
      Keyword.get(opts, :virtual_host, false), 
      Keyword.get(opts, :bucket_as_host, false)
    )}
  end

  @impl Storage
  def path(_path, _opts \\ []), do: nil

  defp do_put(:contents, upload, key, opts) do
    with {:ok, contents} <- Upload.contents(upload) do
      Client.put_object(
        config(opts, :bucket),
        key,
        contents,
        Keyword.get(opts, :s3_options) || opts
      )
      |> ex_aws_module().request(opts)
    end
  end

  defp do_put(_stream, upload, key, opts) do
    with path when is_binary(path) <- Upload.path(upload) do
      path
      |> Client.Upload.stream_file()
      |> Client.upload(
        config(opts, :bucket),
        key,
        Keyword.get(opts, :s3_options) || opts
      )
      |> ex_aws_module().request(opts)
    else
      nil ->
        do_put(:contents, upload, key, opts)
    end
  end

  defp config(opts) do
    Application.get_env(:entrepot, __MODULE__, [])
    |> Keyword.merge(opts)
  end

  defp config(opts, key) do
    config(opts)
    |> Keyword.fetch!(key)
  end

  defp ex_aws_module() do
    Application.get_env(:entrepot, __MODULE__, [])
    |> Keyword.get(:ex_aws_module, ExAws)
  end

  defp handle_error({:error, error}) do
    {:error, "S3 storage API error: #{error |> inspect()}"}
  end

  defp prepare_url_opts(opts) do
    opts = config(opts)
    
    # Add CDN support - check if asset_host is configured
    if Keyword.get(opts, :bucket_as_host) do
      opts
        |> Keyword.put(:bucket_as_host, true)
        |> Keyword.put(:virtual_host, true)
    else
        opts
    end
  end

  defp prepare_unsigned_url(bucket, object, config, virtual_host, bucket_as_host) do
    port = sanitized_port_component(config)

    object =
      if object do
        ensure_slash(object)
      else
        ""
      end

    case virtual_host do
      true ->
        case bucket_as_host do
          true -> "#{config[:scheme]}#{bucket}#{port}#{object}"
          false -> "#{config[:scheme]}#{bucket}.#{config[:host]}#{port}#{object}"
        end

      false ->
        "#{config[:scheme]}#{config[:host]}#{port}/#{bucket}#{object}"
    end
  end

  # If we're using a standard port such as 80 or 443, ignore it
  @excluded_ports [80, "80", 443, "443"]
  defp sanitized_port_component(%{port: nil}), do: ""
  defp sanitized_port_component(%{port: port}) when port in @excluded_ports, do: ""
  defp sanitized_port_component(%{port: port}), do: ":#{port}"
  defp sanitized_port_component(_), do: ""

  defp ensure_slash("/" <> _ = path), do: path
  defp ensure_slash(path), do: "/" <> path

  defp put_accelerate_host(config) do
    Map.put(config, :host, "s3-accelerate.amazonaws.com")
  end

end
