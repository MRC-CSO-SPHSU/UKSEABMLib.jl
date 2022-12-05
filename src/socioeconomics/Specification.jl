module Specification

using ..XAgents: AbstractXAgent


include("./specification/Create.jl") 
include("./specification/Initialize.jl")  
include("./specification/Simulate.jl")   

# Temporarly 
include("./specification/SimulateNew.jl")

end # Specification 