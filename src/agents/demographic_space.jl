"""
space types for human populations conform with Agents.jl space concept, though the client
    can also choose not to use Agents.jl.
"""

using TypedDelegation
export PopulationSpace, DemographicMap, add_town!

abstract type PopulationSpace <: DiscreteSpace end
struct DemographicMap <: PopulationSpace
    countryname::String
    towns::Vector{PersonTown}
end

DemographicMap(name) = DemographicMap(name,Town[])
add_town!(space::DemographicMap) = notimplemented()
#=
@delegate_onefield(DemographicMap, towns,
    [empty_positions, positions, empty_houses, houses, has_empty_house,
        random_town, random_house, random_empty_house,
        empty_positions, positions, has_empty_positions, random_position, random_empty ])
=#

#=
function add_empty_house!(space::DemographicMap,town::Town)
    location = (rand(1:space.maxTownGridDim),rand(1:space.maxTownGridDim))
    return add_empty_house!(town,location)
end
add_empty_house!(space) = add_empty_house!(space,random_town(space))

function add_empty_houses!(space,nhouses)
    houses = House[]
    for _ in 1:nhouses
        house = add_empty_house!(space)
        push!(houses,house)
    end
    return houses

    add_town!(space,density,location) = push!(space.towns,Town(density,location))
end
=#
