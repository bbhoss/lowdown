defmodule LowdownTest do
  use ExUnit.Case
  alias HL7.Segment.{MSH, MSA}
  alias HL7.Composite.{HD, CM_MSH_9}

  doctest Lowdown
  @sample_message <<11>> <>
    "MSH|^~\\&|CUSTOMEREMR|DH|HEALTHLOOP|DH|201301011226||ADT^A01|HL7MSG00001|P|2.3|\r" <>
    <<28, 13>> # SB <> HL7 data <> EB <> CR

  setup do
    ref = make_ref
    :ranch.start_listener(ref, 1, :ranch_tcp, [port: 0], Lowdown.Protocols.MLLP, [])
    port = :ranch.get_port(ref)

    sock = Socket.TCP.connect! "localhost", port
    Socket.packet!(sock, :raw)

    {:ok, %{socket: sock}}
  end

  test "starts a tcp server on port 6660", %{socket: sock} do
    assert sock
  end

  test "acknowledges received messages", %{socket: sock} do
    Socket.Stream.send!(sock, @sample_message)
    body = sock |> Socket.Stream.recv!()
    body_size = byte_size(body) - 3
    <<11, mllp_stripped_body :: binary-size(body_size), 28, 13>> = body
    res = HL7.read!(mllp_stripped_body, input_format: :wire)
    msh = HL7.segment(res, "MSH")
    msa = HL7.segment(res, "MSA")

    current_time = :calendar.universal_time()
    assert msh.message_control_id != "HL7MSG00001"
    assert %MSH{
      sending_app: %HD{namespace_id: "HEALTHLOOP"},
      sending_facility: %HD{namespace_id: "DH"},
      receiving_app: %HD{namespace_id: "CUSTOMEREMR"},
      receiving_facility: %HD{namespace_id: "DH"},
      message_datetime: ^current_time,
      message_type: %CM_MSH_9{structure: "ACK"},
      accept_ack_type: "ER",
      app_ack_type: "ER",
    } = msh

    assert %MSA{
      ack_code: "AA",
      message_control_id: "HL7MSG00001"
    } = msa
  end

end
