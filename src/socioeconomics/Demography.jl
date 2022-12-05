module Demography

using ..XAgents: AbstractXAgent
export AbsProc, AbsPort, initialConnect!

"""
to be used as a trait for generic functions implementing 
    candidates of processes
"""
abstract type AbsProcess end 

"""two components with identical port are connectable"""
abstract type AbsPort <: AbsProcess end 

"Interface" 
function initialConnect!() end 

"symmetry of connections"
initialConnect!(x,y,pars) = initialConnect!(y,x,pars) 

initialConnect!(x,y,pars,initPort::PType)  where PType <: AbsPort = 
    initialConnect!(y,x,pars,initPort)

include("./demography/Create.jl") 
include("./demography/Initialize.jl")  
include("./demography/Simulate.jl")   

# Temporarly 
include("./demography/SimulateNew.jl")

end # Demography