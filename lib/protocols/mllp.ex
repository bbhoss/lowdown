defmodule Lowdown.Protocols.MLLP do
  @behaviour :ranch_protocol

  def start_link(ref, socket, transport, opts) do
    pid = spawn_link(__MODULE__, :init, [ref, socket, transport, opts])
    {:ok, pid}
  end

  def init(ref, socket, transport, opts) do
    :ok = :ranch.accept_ack(ref)
    hl7_processor = Keyword.get(opts, :processor)
    loop(socket, transport, hl7_processor)
  end

  defp loop(socket, transport, hl7_processor) do
    case transport.recv(socket, 0, 5000) do
      {:ok, <<11, data :: binary>>} ->
        expected_payload_size = byte_size(data) - 2

        case data do
          <<hl7 :: binary-size(expected_payload_size), 28, 13>> ->
            {:ok, ack} = hl7_processor.process(hl7)
            send_ack(transport, socket, ack)
            loop(socket, transport, hl7_processor)
          _ ->
            transport.close(socket)
        end
      _ ->
        :ok = transport.close(socket)
    end
  end

  defp send_ack(transport, socket, ack) do
    bin_ack = IO.iodata_to_binary(ack)
    mllp_ack = <<11>> <> bin_ack <> <<28, 13>>
    transport.send(socket, mllp_ack)
  end
end
