defmodule Lowdown.HL7Processor do
  alias HL7.Segment.{MSH, MSA}
  alias HL7.Composite.CM_MSH_9

  def process(hl7) do
    {:ok, parsed} = HL7.read(hl7, input_format: :wire)
    {:ok, generate_acknowledgement(parsed)}
  end

  defp generate_acknowledgement([msh = %HL7.Segment.MSH{} | _]) do
    msa = %MSA{
      ack_code: "AA",
      message_control_id: msh.message_control_id,
    }
    ack_msh = %MSH{msh |
      sending_app: msh.receiving_app,
      sending_facility: msh.receiving_facility,
      receiving_app: msh.sending_app,
      receiving_facility: msh.sending_facility,
      message_datetime: :calendar.universal_time(),
      message_type: %CM_MSH_9{msh.message_type | structure: "ACK"},
      message_control_id: Base.encode32(:crypto.rand_bytes(20)), #TODO: Serialize and store
      accept_ack_type: "ER",
      app_ack_type: "ER",
    }

    HL7.write([ack_msh, msa], output_format: :wire, trim: true)
  end

end
