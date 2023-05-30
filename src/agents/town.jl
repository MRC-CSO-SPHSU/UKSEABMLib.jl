export Town, TownLocation, UNDEFINED_2DLOCATION
export undefined, isadjacent8, adjacent8Towns, init_adjacent_ihabited_towns!,
    manhattan_distance
export add_empty_house!, make_empty_house_occupied!, make_occupied_house_empty!
export has_empty_houses, empty_houses, occupied_houses

"""
Specification of a Town agent type.

Every person in the population is an agent with a house as
a position. Every house is an agent with assigned town as a
position.

This file is included in the module XAgents

Type Town to extend from AbstractAXgent.
"""

const TownLocation  = NTuple{2,Int}
const UNDEFINED_2DLOCATION = (-1,-1)

struct Town{H}
    loc::TownLocation
    # name::String            # does not look necessary
    # local house allowance
    #   a vector of size 4 each corresponding the number of bed rooms
    # lha::Array{Float64,1}
    # relative population density w.r.t. the town with the highest density
    density::Float64
    occupiedHouses::Vector{H}
    emptyHouses::Vector{H}
    adjacentInhabitedTowns::Vector{Town{H}}

    Town{H}(loc::TownLocation,density::Float64) where H =
        new{H}(loc,density,H[],H[],Town{H}[])
end  # Town

"costum show method for Town"
function Base.show(io::IO,  town::Town)
    print(" Town $(town.loc) ")
    #isempty(town.name) ? nothing : print(" $(town.name) ")
    println(" density: $(town.density)")
end

# Base.show(io::IO, ::MIME"text/plain", town::Town) = Base.show(io,town)

Town{H}(loc;density=0.0) where H = Town{H}(loc,density)

location(town::Town) = town.loc
undefined(town::Town{H}) where H =
    location(town) == UNDEFINED_2DLOCATION

isadjacent8(town1, town2) =
    town1 !== town2 &&
    abs(town1.loc[1] - town2.loc[1]) <= 1 &&
    abs(town1.loc[2] - town2.loc[2]) <= 1

function add_empty_house!(town,house)
    @assert isempty(house)
    push!(town.emptyHouses,house)
end

has_empty_houses(town) = length(town.emptyHouses) > 0
function has_empty_houses(towns::Vector)
    for town in towns
        if has_empty_house(town)
            return true
        end
    end
    return false
end
empty_houses(town::Town{H}) where H = town.emptyHouses
occupied_houses(town)    = town.occupiedHouses
adjacent_inhabited_towns(town) = town.adjacentInhabitedTowns

function init_adjacent_ihabited_towns!(towns)
    for town in towns
        @assert isempty(town.adjacentInhabitedTowns)
        if town.density == 0 continue end
        for t in towns
            if isadjacent8(town,t) && t.density > 0
                push!(town.adjacentInhabitedTowns,t)
            end
        end
    end
end

function _make_empty_house_occupied!(town,idx::Int)
    house = town.emptyHouses[idx]
    @assert !isempty(house)
    town.emptyHouses[idx] = town.emptyHouses[end]
    pop!(town.emptyHouses)
    push!(town.occupiedHouses,house)
    nothing
end

function make_empty_house_occupied!(house)
    town = hometown(house)
    _make_empty_house_occupied!(town, findfirst(x -> x === house, town.emptyHouses))
end

function _make_occupied_house_empty!(town,idx::Int)
    house = town.occupiedHouses[idx]
    @assert isempty(house)
    town.occupiedHouses[idx] = town.occupiedHouses[end]
    pop!(town.occupiedHouses)
    push!(town.emptyHouses,house)
    nothing
end

function make_occupied_house_empty!(house)
    town = hometown(house)
    _make_occupied_house_empty!(town, findfirst(x -> x === house, town.occupiedHouses))
end

function verify_consistency(town::Town)
    # check the empty houses are empty
    # check that allocated houses are not empty
    # check that occupants are alive verify_consistency(house)
    error("not implemented")
end

####
# Agents.jl stuffs
####

#=
abstract type HousesRetType end
struct AllHouses <: HousesRetType end
struct EmptyHouses <: HousesRetType end
=#

const Towns = Union{Town,Vector} # One town or list of towns

positions(towns::Towns) = notneeded("")
empty_positions(town::Town) = empty_houses(town)
has_empty_positions(towns::Towns) = has_empty_houses(towns)
random_position(towns) = notneeded("")
random_empty(town::Town) = rand(empty_positions(town))
manhattan_distance(town1,town2) =
    abs(town1.loc[1] - town2.loc[1]) + abs(town1.loc[2] - town2.loc[2])
