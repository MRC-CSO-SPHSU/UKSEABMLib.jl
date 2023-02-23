"""
Module for defining a supertype, AbstractAgent for all Agent types
    with additional ready-to-use agents to be used in (Multi-)ABMs models
"""
module XAgents

using MultiAgents: AbstractAgent, AbstractXAgent, getIDCOUNTER
import MultiAgents: random_position, nearby_ids,
    add_agent_to_space!, remove_agent_from_space!

include("../agents/town.jl")
include("../agents/house.jl")
include("../agents/person.jl")
include("../agents/world.jl")

end  # XAgents
