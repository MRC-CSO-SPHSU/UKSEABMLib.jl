"""
This module is cocnerned with functions employed for declaring model components.
    It is assumed that a model component (e.g. towns, houses, populations etc.)
    don't need to be
    - declared in a specific order by the client
    - does not need to rely on the declaration of another component
    - are not initialized by sophisticated procedure
    - are declared at the start of the simulation
"""

module Declare

using Distributions

using ....Utilities
using ....XAgents
using ....ParamTypes
using ....API.ModelFunc
using ....API.ModelOp
using Agents: nextid

import ....XAgents: create_newhouse!
export declare_towns, declare_inhabited_towns, declare_inhabited_towns!,
    declare_population, declare_population!,
    declare_pyramid_population, declare_pyramid_population!,
    declare_many_newhouses!

function _declare_towns(mappars)
    towns = PersonTown[]
    for y in 1:mappars.mapGridYDimension
        for x in 1:mappars.mapGridXDimension
            town = PersonTown((x,y),density=mappars.map[y,x])
            push!(towns,town)
        end
    end
    init_adjacent_ihabited_towns!(towns)
    return towns
end

declare_towns(pars::DemographyPars) = _declare_towns(mapx(pars))

function _declare_inhabited_towns(mappars)
    towns = PersonTown[]
    for y in 1:mappars.mapGridYDimension
        for x in 1:mappars.mapGridXDimension
            density = mappars.map[y,x]
            if density > 0
                town = PersonTown((x,y),density=density)
                push!(towns,town)
            end
        end
    end
    init_adjacent_ihabited_towns!(towns)
    @info "# of towns : $(length(towns))"
    return towns
end

declare_inhabited_towns(pars) = _declare_inhabited_towns(mapx(pars))

function declare_inhabited_towns!(model)
    ts = declare_inhabited_towns(all_pars(model))
    for town in ts
        add_town!(model,town)
        # push!(model.space.towns,town)
    end
    nothing
end

declare_many_newhouses!(model) =
    create_many_newhouses!(model,population_pars(model).iniitialPop)

# TODO initialize
function _declare_pyramid_population(pars,id=1)
    population = Person[]
    men = Person[]
    women = Person[]

    # age pyramid
    dist = TriangularDist(0, pars.maxStartAge * 12, 0)

    for i in 1:pars.initialPop
        # surplus of babies and toddlers, lower bit of age pyramid
        if i < pars.startBabySurplus
            personAge = rand(1:36) // 12
        else
            personAge = floor(Int, rand(dist)) // 12
        end

        gender = Bool(rand(0:1)) ? male : female

        person = Person(id+i-1,UNDEFINED_HOUSE, personAge; gender)
        #=if ischild(person)
            push!(population, person)
        else
            push!((gender==male ? men : women), person)
        end=#
        push!(population,person)
    end

    @assert length(population) == pars.initialPop
    return population
end

declare_pyramid_population(pars::DemographyPars,id=1) =
	_declare_pyramid_population(population(pars),id)

# TODO no Kinship initialization
function _declare_population(pars,id=1)
    population = Person[]
    for i in 1 : pars.initialPop / 2
        ageMale = rand(pars.minStartAge:pars.maxStartAge)
        ageFemale = ageMale - rand(-2:5)
        ageFemale = ageFemale < 24 ? 24 : ageFemale

        rageMale = ageMale + rand(0:11) // 12
        rageFemale = ageFemale + rand(0:11) // 12

        # From the old code:
        #    the following is direct translation but it does not ok
        #    birthYear = properties[:startYear] - rand((properties[:minStartAge]:properties[:maxStartAge]))
        #    why not
        #    birthYear = properties[:startYear]  - ageMale/Female
        #    birthMonth = rand((1:12))

        newMan = Person(id+i*2-2,UNDEFINED_HOUSE,rageMale,gender=male)
        newWoman = Person(id+i*2-1,UNDEFINED_HOUSE,rageFemale,gender=female)
        set_as_partners!(newMan,newWoman)

        push!(population,newMan);  push!(population,newWoman)

    end # for

    return population
end # createPopulation

function declare_population(pars::DemographyPars,id=1)
    poppars = population(pars)
    return _declare_population(poppars,id)
end

function declare_population!(model)
    pop = declare_population(all_pars(model))
    for person in pop
        add_person!(model,person)
        nextid(model) # Hack
    end
    nothing
end

function declare_pyramid_population!(model)
    pop = declare_pyramid_population(all_pars(model))
    for person in pop
        add_person!(model,person)
        nextid(model)
    end
    nothing
end

end # module Declare
