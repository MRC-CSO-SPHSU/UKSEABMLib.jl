export  House, HouseLocation

export getHomeTown, getHouseLocation, undefined, isEmpty, town, number_of_occupants

using ....Utilities: removefirst!

const HouseLocation  = NTuple{2,Int}

"""
Specification of a House Agent Type. 

This file is included in the module XAgents 

Type House to extend from AbstracXAgent.
""" 
mutable struct House{P, T} <: AbstractXAgent
    id :: Int
    town :: T
    pos :: HouseLocation     # location in the town    
    # size::String                     # TODO enumeration type / at the moment not yet necessary  
    occupants::Vector{P}                           

    House{P, T}(town, pos) where {P, T} = new(getIDCOUNTER(),town, pos,P[])
end # House 

undefined(house::House{P,T}) where {P,T} = 
    undefined(house.town) && house.pos == UNDEFINED_2DLOCATION

number_of_occupants(house) = length(house.occupants)
isEmpty(house) = length(house.occupants) == 0

town(house) = house.town 

# to replace the functions below in order to unify style across agents APIs
"town associated with house"
function getHomeTown(house::House)
    house.town
end

"town name associated with house"
getHomeTownName(house::House) = house.town.id 

"house location in the associated town"
function getHouseLocation(house::House)
    house.pos
end

"add an occupant to a house"
function addOccupant!(house::House{P}, person::P) where {P}
    @assert !(person in house.occupants)
    if isEmpty(house)
	    push!(house.occupants, person)
        @assert house in emptyhouses(getHomeTown(house))
        make_emptyhouse_occupied!(house)
    else 
        push!(house.occupants,person)
    end 
	nothing
end

"remove an occupant from a house"
function removeOccupant!(house::House{P}, person::P) where {P}
    removefirst!(house.occupants, person) 
    @assert !(person in house.occupants)
    if isEmpty(house) 
        @assert house in occupiedhouses(getHomeTown(house))
        make_occupiedhouse_empty!(house)
    end 
    nothing 
end

"Costum print function for agents"
function Base.show(io::IO, house::House{P}) where P
    townName = getHomeTownName(house)
    print("House $(house.id) @ town $(townName) @ $(house.pos)")
    length(house.occupants) == 0 ? nothing : print(" occupants: ") 
    for person in house.occupants
        print(" $(person.id) ")
    end
    println() 
end 
