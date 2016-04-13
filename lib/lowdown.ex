defmodule Lowdown do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

#    :ranch.start_listener(MLLPEchoServer, 10, :ranch_tcp, [port: 6660], Lowdown.Protocols.MLLP, [])

    children = [
      # worker()
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lowdown.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
