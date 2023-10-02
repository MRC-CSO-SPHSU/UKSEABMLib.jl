"""
Module for defining a supertype, AbstractAgent for all Agent types
    with additional ready-to-use agents to be used in (Multi-)ABMs models
"""
module XAgents

using Agents: AbstractAgent, DiscreteSpace, nextid

include("../agents/town.jl")
include("../agents/house.jl")
include("../agents/person.jl")
include("../agents/demographic_space.jl")
include("../agents/world.jl")
include("../agents/population_verification.jl")

end  # XAgents
