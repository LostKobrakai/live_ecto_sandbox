defmodule LiveEctoSandbox do
  @moduledoc """
  A plug and module to allow concurrent, transactional acceptance tests
  using `Phoenix.Ecto.SQL.Sandbox` and [`Ecto.Adapters.SQL.Sandbox`](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html) with LiveView.

  ## Endpoint

  For the use as a plug see the documentation of `Phoenix.Ecto.SQL.Sandbox`,and just replace `plug Phoenix.Ecto.SQL.Sandbox` with `plug LiveEctoSandbox`.

  Plugging this module does add only one small behavior to it: Storing the
  metadata in `conn.assigns` for the static render of live views to have access to.

  ## LiveView's

  In live views there is nothing similar to your `endpoint.ex`, where global
  behavior could be "plugged in", therefore the following needs to be done
  in each live view you use (but not live components).

      def mount(_, _, socket) do
        LiveEctoSandbox.allow_sandbox_access(socket)
        …
      end

  This is mostly a noop when no sandbox is used, but if you wish you could
  also wrap it in a conditional like `Phoenix.Ecto.SQL.Sandbox` suggests
  for the plug in your `endpoint.ex`.
  """
  import Phoenix.LiveView

  def init(opts) do
    Phoenix.Ecto.SQL.Sandbox.init(opts)
  end

  def call(conn, %{header: header} = opts) do
    conn = Phoenix.Ecto.SQL.Sandbox.call(conn, opts)

    if conn.halted do
      conn
    else
      metadata =
        conn
        |> Plug.Conn.get_req_header(header)
        |> List.first()
        |> Phoenix.Ecto.SQL.Sandbox.decode_metadata()

      Plug.Conn.assign(conn, :live_ecto_sandbox, metadata)
    end
  end

  def allow_sandbox_access(socket) do
    %{assigns: %{live_ecto_sandbox: metadata}} =
      assign_new(socket, :live_ecto_sandbox, fn ->
        get_connect_info(socket).user_agent
        |> Phoenix.Ecto.SQL.Sandbox.decode_metadata()
      end)

    allow_sandbox_access(metadata, Ecto.Adapters.SQL.Sandbox)
  end

  # Remove here once this is public in phoenix_ecto
  defp allow_sandbox_access(%{repo: repo, owner: owner}, sandbox) do
    Enum.each(List.wrap(repo), &sandbox.allow(&1, owner, self()))
  end

  defp allow_sandbox_access(_metadata, _sandbox), do: nil
end
