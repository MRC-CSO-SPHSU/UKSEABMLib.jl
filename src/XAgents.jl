"""
Module for defining a supertype, AbstractAgent for all Agent types 
    with additional ready-to-use agents to be used in (Multi-)ABMs models 
"""
module XAgents

    include("./agents/AbstractXAgent.jl")    # could implant Agents.jl 
    include("./agents/AbstractPerson.jl")

    include("./agents/Town.jl")
    include("./agents/House.jl")
    include("./agents/Person.jl")
    
end  # XAgents 

