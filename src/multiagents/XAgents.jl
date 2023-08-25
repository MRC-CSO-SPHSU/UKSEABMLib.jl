"""
Module for defining a supertype, AbstractAgent for all Agent types
    with additional ready-to-use agents to be used in (Multi-)ABMs models
"""
module XAgents

using ABMSim: AbstractAgent, AbstractXAgent, getIDCOUNTER, init_majl,
    Agents.DiscreteSpace
# for Town
import ABMSim: positions, empty_positions, has_empty_positions,
    random_position, random_empty, manhattan_distance

include("../agents/town.jl")
include("../agents/house.jl")
include("../agents/person.jl")
include("../agents/demographic_space.jl")
include("../agents/world.jl")
include("../agents/population_verification.jl")

end  # XAgents
