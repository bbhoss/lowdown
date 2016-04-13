defmodule Lowdown.Protocols.MLLPTest do
  use ExUnit.Case

  @sample_hl7 "MSH|^~\&|EPICADT|DH|LABADT|DH|201301011226||ADT^A01|HL7MSG00001|P|2.3|\\r"
  @sample_message <<11>> <>
    @sample_hl7 <>
    <<28, 13>> # SB <> HL7 data <> EB <> CR


  setup do
    ref = :erlang.make_ref
    test_pid = self()
    hl7_processor = fn(hl7) ->
      send test_pid, {:hl7, hl7}
      {:ok, "ACK"}
    end

    :ranch.start_listener(ref, 1, :ranch_tcp, [port: 0], Lowdown.Protocols.MLLP, [hl7_processor: hl7_processor])

    port = :ranch.get_port(ref)
    sock = Socket.TCP.connect!("localhost", port)
    Socket.packet!(sock, :raw)
    {:ok, %{socket: sock}}
  end

  test "starts a tcp server", %{socket: sock} do
    assert sock
  end

  test "acknowledges received messages", %{socket: sock} do
    Socket.Stream.send!(sock, @sample_message)
    body = sock |> Socket.Stream.recv!()
    assert_receive {:hl7, @sample_hl7}
    assert body == <<11>> <> "ACK" <> <<28, 13>>
  end

end
