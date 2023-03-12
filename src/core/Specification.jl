module Specification

using ..XAgents: AbstractXAgent

include("./specification/Declare.jl")
include("./specification/Initialize.jl")
include("./specification/SimulateNew.jl")

end # Specification
