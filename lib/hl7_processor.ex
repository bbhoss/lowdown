defmodule Lowdown.HL7Processor do
  @callback process(binary()) :: {:ok, binary()}
end
