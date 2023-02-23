export House, HouseLocation
export hometown, house_location, undefined, town, num_occupants

import Base.isempty
using ....Utilities: removefirst!

const HouseLocation  = NTuple{2,Int}

"""
Specification of a House Agent Type.
This file is included in the module XAgents
Type House to extend from AbstracXAgent.
"""
mutable struct House{P, T}
    # id :: Int
    town :: T
    pos :: HouseLocation     # location in the town
    # size::String           # TODO enumeration type / at the moment not yet necessary
    occupants::Vector{P}

    House{P, T}(town, pos) where {P, T} = new(town, pos,P[])
end # House

undefined(house::House{P,T}) where {P,T} =
    undefined(house.town) && house.pos == UNDEFINED_2DLOCATION

num_occupants(house) = length(house.occupants)
isempty(house::House) = length(house.occupants) == 0
town(house) = house.town

"town associated with house"
hometown(house::House) = house.town

"house location in the associated town"
house_location(house::House) = house.pos

"add an occupant to a house"
function add_occupant!(house::House{P}, person::P) where {P}
    @assert !(person in house.occupants)
    if isempty(house)
	    push!(house.occupants, person)
        @assert house in empty_houses(hometown(house))
        make_empty_house_occupied!(house)
    else
        push!(house.occupants,person)
    end
	nothing
end

"remove an occupant from a house"
function remove_occupant!(house::House{P}, person::P) where {P}
    removefirst!(house.occupants, person)
    @assert !(person in house.occupants)
    if isempty(house)
        @assert house in occupied_houses(hometown(house))
        make_occupied_house_empty!(house)
    end
    nothing
end

"Costum print function for agents"
function Base.show(io::IO, house::House{P}) where P
    town = hometown(house)
    print("House @ pos: $(house.pos) @ town pos: $(town.pos)")
    length(house.occupants) == 0 ? nothing : print(" occupants: ")
    for person in house.occupants
        print(" $(person.id) ")
    end
    println()
end
