defmodule Route do
  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Plug
      def init(opts), do: opts

      def call(conn, opts) do
        route_plug(super(conn, opts), [])
      end

      import Route, only: [route: 1]

      Module.register_attribute(__MODULE__, :routes, accumulate: true)
      @before_compile Route
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    Module.get_attribute(env.module, :routes)
    |> Enum.reverse
    |> Enum.map(fn {path, host, router} ->
      host_match = Plug.Router.Utils.build_host_match(host)
      {_, path_match} = Plug.Router.Utils.build_path_match(path <> "/*glob")
      quote do
        def route_plug(%Plug.Conn{host: unquote(host_match), path_info: unquote(path_match)} = conn, opts) do
          Plug.Router.Utils.forward(conn, var!(glob), unquote(router), opts)
        end
      end
    end)
  end

  defmacro route(opts) do
    router = Keyword.fetch!(opts, :to)
    path = Keyword.get(opts, :path, "")
    host = Keyword.get(opts, :host, nil)
    quote do
      @routes {unquote(path), unquote(host), unquote(router)}
    end
  end
end