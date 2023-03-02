module Create

using Distributions

using ....Utilities
using ....XAgents
using ....ParamTypes
using ....API.ParamFunc
using ....API.ModelFunc

export create_towns, create_inhabited_towns, create_inhabited_towns!,
    create_population, create_population!, create_pyramid_population,
    create_newhouse!, create_newhouses!

function _create_towns(mappars)
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

create_towns(pars::DemographyPars) = _create_towns(mapx(pars))

function _create_inhabited_towns(mappars)
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

# TODO this rather belongs to Operation module
function create_newhouse!(model)
    town = select_random_town(towns(model))
    townGridDimension = map_pars(model).townGridDimension
    house = create_newhouse!(town,  rand(1:townGridDimension),
                                    rand(1:townGridDimension))
    return house
end

function create_newhouses!(model,nhouses)
    cnt = 0
    @assert sum(num_houses(towns(model))) == 0
    popsize = length(alive_people(model))
    while cnt < popsize
        create_newhouse!(model)
        cnt += 1
    end
    return nothing
end

create_inhabited_towns(pars) = _create_inhabited_towns(mapx(pars))

function create_inhabited_towns!(model)
    towns = create_inhabited_towns(all_pars(model))
    for town in towns
        push!(model.space.towns,town)
    end
    nothing
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

function _create_pyramid_population(pars)
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

    for p in population
        a = age(p)
        # adults remain orphans with a certain likelihood
        if a >= 18 && rand() < pars.startProbOrphan * a
            continue
        end

        # get all women that are between 18 and 40 years older than
        # p (and could thus be their mother)
        start, stop = _age_interval(women, a + 18, a + 40)
        # check if we actually found any
        if start > length(women) || start > stop
            continue
        end

        @assert typeof(start) == Int
        @assert age(women[start]) >= a+18

        mother = women[rand(start:stop)]

        set_as_parent_child!(p, mother)
        if !issingle(mother)
            set_as_parent_child!(p, partner(mother))
        end

        if age(p) < 18
            set_as_guardian_dependent!(mother, p)
            if !issingle(mother) # currently not an option
                set_as_guardian_dependent!(partner(mother), p)
            end
            set_as_provider_providee!(mother, p)
        end
    end

    @assert length(population) == pars.initialPop
    return population
end

create_pyramid_population(pars::DemographyPars) =
	_create_pyramid_population(population(pars))

function _create_population(pars)
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

function create_population(pars::DemographyPars)
    poppars = population(pars)
    return _create_population(poppars)
end

function create_population!(model)
    pop = create_population(all_pars(model))
    for person in pop
        ModelFunc.add_agent_pos!(person,model)
    end
    nothing
end


end # module Create
