module Demography

using ..XAgents: AbstractXAgent


include("./demography/Create.jl") 
include("./demography/Initialize.jl")  
include("./demography/Simulate.jl")   

# Temporarly 
include("./demography/SimulateNew.jl")

end # Demography