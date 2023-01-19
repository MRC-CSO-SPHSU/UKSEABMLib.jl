export Town, TownLocation
export undefined, isAdjacent8, adjacent8Towns, manhattanDistance
export add_emptyhouse!, make_emptyhouse_occupied!, make_occupiedhouse_empty!
export has_emptyhouses, emptyhouses, occupiedhouses 

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

struct Town{H} <: AbstractXAgent
    id::Int
    pos::TownLocation
    # name::String                            # does not look necessary
    # lha::Array{Float64,1}                 # local house allowance 
                                            #   a vector of size 4 each corresponding the number of bed rooms 
    density::Float64                        # relative population density w.r.t. the town with the highest density 
    occupiedHouses::Vector{H}
    emptyHouses::Vector{H}

    Town{H}(pos::TownLocation,density::Float64) where H =
        new{H}(getIDCOUNTER(),pos,density,H[],H[])
end  # Town 

"costum show method for Town"
function Base.show(io::IO,  town::Town) 
    print(" Town $(town.id) ")  
    #isempty(town.name) ? nothing : print(" $(town.name) ")
    print("@ $(town.pos)") 
    println(" density: $(town.density)")
end 

# Base.show(io::IO, ::MIME"text/plain", town::Town) = Base.show(io,town)
    
Town{H}(pos;density=0.0) where H = Town{H}(pos,density)

undefined(town::Town{H}) where H = 
    town.pos == UNDEFINED_2DLOCATION

isAdjacent8(town1, town2) = 
    abs(town1.pos[1] - town2.pos[1]) <= 1 &&   
    abs(town1.pos[2] - town2.pos[2]) <= 1 

manhattanDistance(town1, town2) = 
    abs(town1.pos[1] - town2.pos[1]) +   
    abs(town1.pos[2] - town2.pos[2]) 

function add_emptyhouse!(town,house)  
    @assert isEmpty(house)
    push!(town.emptyHouses,house) 
end

has_emptyhouses(town) = length(town.emptyHouses) > 0 
emptyhouses(town::Town{H}) where H = town.emptyHouses 
occupiedhouses(town)    = town.occupiedHouses

function make_emptyhouse_occupied!(town,idx::Int)
    house = town.emptyHouses[idx] 
    @assert !isEmpty(house)
    town.emptyHouses[idx] = town.emptyHouses[end] 
    pop!(town.emptyHouses) 
    push!(town.occupiedHouses,house)
    nothing 
end

function make_emptyhouse_occupied!(house) 
    # println("house $(house.id) become occupied")
    town = hometown(house)
    @assert house in emptyhouses(town)
    make_emptyhouse_occupied!(town,findfirst(x -> x === house, town.emptyHouses))
end

function make_occupiedhouse_empty!(town,idx::Int)
    house = town.occupiedHouses[idx] 
    #println("house $(house.id) become empty")
    @assert isEmpty(house)
    town.occupiedHouses[idx] = town.occupiedHouses[end] 
    pop!(town.occupiedHouses)
    push!(town.emptyHouses,house)  
    nothing 
end

function make_occupiedhouse_empty!(house) 
    town = hometown(house)
    @assert house in hometown(house).occupiedHouses
    make_occupiedhouse_empty!(town,findfirst(x -> x === house, town.occupiedHouses))
end


function verify_consistency(town::Town)
    # check the empty houses are empty 
    # check that allocated houses are not empty 
    # check that occupants are alive verify_consistency(house)
end 
