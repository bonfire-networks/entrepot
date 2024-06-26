defmodule Entrepot.MockUpload do
  defstruct content: "Hi, I'm a file", name: "hi", path: nil

  defimpl Entrepot.Upload do
    def contents(mock), do: {:ok, mock.content}

    def path(mock), do: mock.path

    def name(mock), do: mock.name
  end
end
