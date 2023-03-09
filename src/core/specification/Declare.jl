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
using ....API.ParamFunc
using ....API.ModelFunc
using ....API.ModelOp

import ....XAgents: createX_newhouse!
export declare_towns, declare_inhabited_towns, declare_inhabited_towns!,
    declare_population, declare_population!, declare_pyramid_population, declare_many_newhouses!

function _declare_towns(mappars)
    uktowns = PersonTown[]
    for y in 1:mappars.mapGridYDimension
        for x in 1:mappars.mapGridXDimension
            town = PersonTown((x,y),density=mappars.map[y,x])
            push!(uktowns,town)
        end
    end

    for uktown in uktowns
        if uktown.density == 0 continue end
        for t in uktowns
            if isadjacent8(uktown,t) && t.density > 0
                push!(uktown.adjacentInhabitedTowns,t)
            end
        end
    end

    return uktowns
end

declare_towns(pars::DemographyPars) = _declare_towns(mapx(pars))

function _declare_inhabited_towns(mappars)
    uktowns = PersonTown[]
    for y in 1:mappars.mapGridYDimension
        for x in 1:mappars.mapGridXDimension
            density = mappars.map[y,x]
            if density > 0
                town = PersonTown((x,y),density=density)
                push!(uktowns,town)
            end
        end
    end

    for uktown in uktowns
        for t in uktowns
            if isadjacent8(uktown,t)
                push!(uktown.adjacentInhabitedTowns,t)
            end
        end
    end

    @info "# of towns : $(length(uktowns))"
    return uktowns
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

function declare_many_newhouses!(model)
    cnt = 0
    @assert sum(num_houses(towns(model))) == 0
    popsize = length(alive_people(model))
    while cnt < popsize
        createX_newhouse!(model)
        cnt += 1
    end
    return nothing
end

# return agents with age in interval minAge, maxAge
# assumes pop is sorted by age
# very simple implementation, binary search would be faster
function _age_interval(pop, minAge, maxAge)
    idx_start = 1
    idx_end = 0

    for p in pop
        if age(p) < minAge
            # not there yet
            idx_start += 1
            continue
        end

        if age(p) > maxAge
            # we reached the end of the interval, return what we have
            return idx_start, idx_end
        end

        idx_end += 1
    end

    idx_start, idx_end
end

# TODO initialize
function _declare_pyramid_population(pars)
    population = Person[]
    men = Person[]
    women = Person[]

    # age pyramid
    dist = TriangularDist(0, pars.maxStartAge * 12, 0)

    for i in 1:pars.initialPop
        # surplus of babies and toddlers, lower bit of age pyramid
        if i < pars.startBabySurplus
            age = rand(1:36) // 12
        else
            age = floor(Int, rand(dist)) // 12
        end

        gender = Bool(rand(0:1)) ? male : female

        person = Person(UNDEFINED_HOUSE, age; gender)
        if age < 18
            push!(population, person)
        else
            push!((gender==male ? men : women), person)
        end
    end

###  assign partners

    nCouples = floor(Int, pars.startProbMarried * length(men))
    for i in 1:nCouples
        man = men[1]
        # find woman of the right age
        for (j, woman) in enumerate(women)
            if age(man)+2 >= age(woman) >= age(man)-5
                set_as_partners!(man, woman)
                push!(population, man)
                push!(population, woman)
                remove_unsorted!(men, 1)
                remove_unsorted!(women, j)
                break
            end
        end
    end

    # store unmarried people in population as well
    append!(population, men)
    append!(population, women)

### assign parents

    # get all adult women
    women = filter(population) do p
        isfemale(p) && age(p) >= 18
    end

    # sort by age so that we can easily get age intervals
    sort!(women, by = age)

    for person in population
        a = age(person)
        # adults remain orphans with a certain likelihood
        if a >= 18 && rand() < pars.startProbOrphan * a
            continue
        end

        # get all women that are between 18 and 40 years older than
        # p (and could thus be their mother)
        start, stop = _age_interval(women, a + 18, a + 40)
        # check if we actually found any
        if start > length(women) || start > stop
            @assert !ischild(person)
            continue
        end

        @assert typeof(start) == Int
        @assert age(women[start]) >= a+18

        mother = women[rand(start:stop)]

        set_as_parent_child!(person, mother)
        if !issingle(mother)
            set_as_parent_child!(person, partner(mother))
        end

        if age(person) < 18
            set_as_guardian_dependent!(mother, person)
            if !issingle(mother) # currently not an option
                set_as_guardian_dependent!(partner(mother), person)
            end
            set_as_provider_providee!(mother, person)
        end
    end

    @assert length(population) == pars.initialPop
    return population
end

declare_pyramid_population(pars::DemographyPars) =
	_declare_pyramid_population(population(pars))

# TODO no Kinship initialization
function _declare_population(pars)
    population = Person[]
    for _ in 1 : pars.initialPop
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

        newMan = Person(UNDEFINED_HOUSE,rageMale,gender=male)
        newWoman = Person(UNDEFINED_HOUSE,rageFemale,gender=female)
        set_as_partners!(newMan,newWoman)

        push!(population,newMan);  push!(population,newWoman)

    end # for

    return population
end # createPopulation

function declare_population(pars::DemographyPars)
    poppars = population(pars)
    return _declare_population(poppars)
end

function declare_population!(model)
    pop = declare_population(all_pars(model))
    for person in pop
        add_person!(model,person)
    end
    nothing
end


end # module Declare
