defmodule InventoryWatcherWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: InventoryWatcherWeb.Schema

  @impl true
  def connect(_params, socket, _connect_info) do
    IO.puts("✅ UserSocket connecting...")

    socket =
      Absinthe.Phoenix.Socket.put_options(socket,
        context: %{pubsub: InventoryWatcherWeb.Endpoint}
      )

    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end
