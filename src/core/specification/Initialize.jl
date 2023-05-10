module Initialize

using Distributions: Normal
using Random:  shuffle
using ....Utilities
using ....XAgents
using ....ParamTypes
using ....API.ModelFunc
using ....API.ParamFunc
using ..Declare

import ....API.ModelFunc: init!
import ....API.ModelOp: create_many_newhouses!
import ....API.Connection: AbsInitPort, AbsInitProcess, initial_connect!

export InitHousesInTownsPort, InitCouplesToHousesPort
export InitClassesProcess, InitWorkProcess, InitHousesInTownsProcess, InitPeopleInHouses,
    InitKinshipProcess
export DefaultModelInit, AgentsModelInit

struct DefaultModelInit <: AbsInitPort end
struct AgentsModelInit <: AbsInitPort end

struct InitHousesInTownsPort <: AbsInitPort end
struct InitCouplesToHousesPort <: AbsInitPort end

struct InitHousesInTownsProcess <: AbsInitProcess end
struct InitKinshipProcess <: AbsInitProcess end
struct InitPeopleInHouses <: AbsInitProcess end
struct InitClassesProcess <: AbsInitProcess end
struct InitWorkProcess <: AbsInitProcess end

init!(model,process::AbsInitProcess) = init!(all_people(model),all_pars(model),process)

"initialize houses in a given set of towns"
function _initialize_houses_towns(towns, houses, pars, popsize)
    @assert length(houses) == 0
    while length(houses) < popsize
        for town in towns
            if town.density > 0
                adjustedDensity = town.density * pars.mapDensityModifier
                for hx in 1:pars.townGridDimension
                    for hy in 1:pars.townGridDimension
                        if(rand() < adjustedDensity)
                            house = create_newhouse_and_append!(town,houses,hx,hy)
                        end
                    end # for hy
                end # for hx
            end # if town.density
        end # for town
    end # while
    return houses
end  # function initializeHousesInTwons

function initial_connect!(houses, towns, pars,::InitHousesInTownsPort)
    _initialize_houses_towns(towns, houses, mapx(pars), population(pars).initialPop)
    @assert length(houses) > 0
    for house in houses
        @assert hometown(house) != nothing
    end
    @info "# of initialized houses $(length(houses))"
    nothing
end

initial_connect!(houses::Vector{PersonHouse},
                towns::Vector{PersonTown},
                pars) =
    initial_connect!(houses,towns,pars,InitHousesInTownsPort())

function init!(model,::InitHousesInTownsProcess)
    popsize = length(alive_people(model))  # Why alive_people? , are not all people alive?
    @assert length(towns(model)) > 0
    @assert sum(num_houses(towns(model))) == 0
    create_many_newhouses!(model,popsize)
    return nothing
end

# return agents with age in interval minAge, maxAge
# assumes pop is sorted by age
# very simple implementation, binary search would be faster
function _age_interval(pop, minAge, maxAge)
    idx_start = 1
    idx_end = 0

    for p in pop
        idx_end += 1
        if age(p) < minAge
            # not there yet
            idx_start += 1
            continue
        end

        if age(p) > maxAge
            # we reached the end of the interval, return what we have
            return idx_start, idx_end
        end
    end

    idx_start, idx_end
end

function _init_kinship!(pop,pars)

    population = Person[]
    men = Person[]
    women = Person[]

    ###  The code below by Martin Hinsh

    for person in pop
        if ischild(person)
            push!(population,person)
        else
            push!(ismale(person) ? men : women, person)
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
    @assert length(population) == pars.initialPop

    ### assign parents

    # get all adult women
    adultWomen = filter(population) do p
        isfemale(p) && isadult(p)
    end

    # @info "married women : " * string(length([m for m in adultWomen if !issingle(m)]))
    # sort by age so that we can easily get age intervals
    sort!(adultWomen, by = age)
    # @info "# of adult women : $(length(adultWomen)) from \
    #    $(yearsold(adultWomen[1])) to $(yearsold(adultWomen[end])) yearsold"

    for person in population
        a = age(person)
        # adults remain orphans with a certain likelihood
        if isadult(person) && rand() < pars.startProbOrphan * a
            continue
        end

        # get all women that are between 18 and 40 years older than
        # p (and could thus be their mother)
        start, stop = _age_interval(adultWomen, a + 18, a + 40)
        # check if we actually found any
        if start > length(adultWomen) || start > stop
            @assert !ischild(person)
            continue
        end

        @assert typeof(start) == Int
        @assert age(adultWomen[start]) >= a+18

        mother = adultWomen[rand(start:stop)]

        set_as_parent_child!(person, mother)
        if !issingle(mother) && age(partner(mother)) >= age(person) + 18
            set_as_parent_child!(person, partner(mother))
        end

        if ischild(person)
            set_as_guardian_dependent!(mother, person)
            if !issingle(mother) # currently not an option
                set_as_guardian_dependent!(partner(mother), person)
            end
            set_as_provider_providee!(mother, person)
        end
    end

    return nothing
end

function init!(pop,pars,::InitKinshipProcess)
    _init_kinship!(pop,population(pars))
end

"Randomly assign a population to non-inhebted set of houses"
function _population_to_houses!(population, houses)
    women = [ person for person in population if isfemale(person) && isadult(person)]
    randomhouses = shuffle(houses)
    # TODO Improve the overall algorithm
    for woman in women
        house = pop!(randomhouses)
        move_to_house!(woman, house)
        if !issingle(woman)
            move_to_house!(partner(woman), house)
        end
        #for child in dependents(woman)
        for child in children(woman)
            if ischild(child)
                move_to_house!(child, house)
            end
        end
    end # for person

    for person in population
        if home(person) === UNDEFINED_HOUSE
            @assert ismale(person)
            @assert isadult(person)
            @assert length(randomhouses) >= 1
            house = pop!(randomhouses)
            move_to_house!(person, house)
        end
    end
    return nothing
end  # function assignCouplesToHouses

initial_connect!(pop, houses, pars, ::InitCouplesToHousesPort) =
    _population_to_houses!(pop, houses)

initial_connect!(pop::Vector{Person},
                houses::Vector{PersonHouse},
                pars) =
    initial_connect!(pop,houses,pars,InitCouplesToHousesPort())

function _init_class!(person, pars)
    p = rand()
    class = findfirst(x->p<x, pars.cumProbClasses)-1
    classRank!(person, class)
    nothing
end

function init!(pop,pars,::InitClassesProcess)
    for person in pop
        _init_class!(person,population(pars))
    end
end

function _init_work!(person, pars)
    class = classRank(person)+1
    workingTime = 0
    for i in age(person):pars.workingAge[class]
        workingTime *= pars.workDiscountingTime
        workingTime += 1
    end

    dKi = rand(Normal(0, pars.wageVar))
    initialWage = pars.incomeInitialLevels[class] * exp(dKi)
    dKf = rand(Normal(dKi, pars.wageVar))
    finalWage = pars.incomeFinalLevels[class] * exp(dKf)

    initialIncome!(person, initialWage)
    finalIncome!(person, finalWage)

    c = log(initialWage/finalWage)
    wage!(person, finalWage * exp(c * exp(-pars.incomeGrowthRate[class]*workingTime)))
    income!(person, wage(person) * pars.weeklyHours[class])
    potentialIncome!(person, income(person))
    jobTenure!(person, rand(1:50))
#    workExperience = workingTime

    nothing
end

function init!(pop,pars,::InitWorkProcess)
    for person in pop
        _init_work!(person,work(pars))
    end
end

function _init_pre_verification(model)
    @assert length(alive_people(model)) == length(all_people(model))
    @info "init!: verification of initial population are all alive"
end

function _init_post_verification(model)
    @assert verify_children_parents_consistency(all_people(model))
    @info "init!: verification of consistency of child-parent relationship conducted"

    @assert verify_partnership_consistency(all_people(model))
    @info "init!: verification of consistency of partnership relationship conducted"

    @assert verify_no_homeless(all_people(model)) #TODO to move to unit tests
    @info "init!: verification of no homeless conducted"

    @assert verify_child_is_with_a_parent(all_people(model))
    @info "init!: verification of a child lives with one of his parents conducted"

    @assert verify_singles_live_alone(all_people(model))
    @info "init!: verification of singles living alone conducted"

    @assert verify_family_lives_together(all_people(model))
    @info "init!: verification of families living together conducted"

    @assert verify_houses_consistency(all_people(model),houses(model))
    @info "init!: verification of houses consistency conducted"
end

function init!(model,::DefaultModelInit; verify)
    if verify
        _init_pre_verification(model)
    end

    pars = all_pars(model)

    init!(all_people(model), pars, InitKinshipProcess())
    initial_connect!(houses(model), towns(model), pars)
    initial_connect!(houses(model), all_people(model), pars)
    init!(all_people(model), pars, InitClassesProcess())
    init!(all_people(model), pars, InitWorkProcess())

    if verify
        _init_post_verification(model)
    end
end
init!(model;verify) = init!(model,DefaultModelInit();verify)

function init!(model, ::AgentsModelInit; verify)
    if verify
        _init_pre_verification(model)
    end

    pars = all_pars(model)
    init!(model, InitHousesInTownsProcess())
    init!(model, InitKinshipProcess())
    initial_connect!(all_people(model), houses(model) , pars, InitCouplesToHousesPort())
    init!(model,InitClassesProcess())
    init!(model,InitWorkProcess())

    if verify
        _init_post_verification(model)
    end
end

end # module Initalize
