module Initialize

using Distributions: Normal
using Random:  shuffle
using ....XAgents
using ....ParamTypes
using ....API.ModelFunc
import ....API.ModelFunc: init!
import ....API.Connection: AbsInitPort, AbsInitProcess, initial_connect!

export InitHousesInTownsPort, InitCouplesToHousesPort
export InitClassesProcess, InitWorkProcess, Init, DefaultModelInit

struct DefaultModelInit <: AbsInitPort end

struct InitHousesInTownsPort <: AbsInitPort end
struct InitCouplesToHousesPort <: AbsInitPort end

struct InitClassesProcess <: AbsInitProcess end
struct InitWorkProcess <: AbsInitProcess end

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
    _initialize_houses_towns(towns, houses, mapParameters(pars), populationParameters(pars).initialPop)
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

"Randomly assign a population of couples to non-inhebted set of houses"
function _couples_to_houses!(population::Vector{Person}, houses::Vector{PersonHouse})

    women = [ person for person in population if isfemale(person) ]
    randomhouses = shuffle(houses)

    for woman in women
        house = pop!(randomhouses)
        move_to_house!(woman, house)
        if !issingle(woman)
            move_to_house!(partner(woman), house)
        end
        #for child in dependents(woman)
        for child in children(woman)
            move_to_house!(child, house)
        end
    end # for person

    for person in population
        if home(person) === UNDEFINED_HOUSE
            @assert ismale(person)
            @assert length(randomhouses) >= 1
            house = pop!(randomhouses)
            move_to_house!(person, house)
        end
    end
end  # function assignCouplesToHouses

function initial_connect!(pop, houses, pars, ::InitCouplesToHousesPort)
    _couples_to_houses!(pop, houses)
    nothing
end

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
        _init_class!(person,populationParameters(pars))
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
        _init_work!(person,workParameters(pars))
    end
end

function init!(model, mi::AbsInitPort = DefaultModelInit())
    pars = allParameters(model)
    initial_connect!(houses(model), towns(model), pars)
    initial_connect!(houses(model), all_people(model), pars)
    init!(all_people(model),pars,InitClassesProcess())
    init!(all_people(model),pars,InitWorkProcess())
end

end # module Initalize
