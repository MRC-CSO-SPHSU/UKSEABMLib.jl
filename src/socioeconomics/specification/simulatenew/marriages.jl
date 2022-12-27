using Memoization
using ....XAgents

export resetCacheMarriages, marriage!, selectMarriage, doMarriages!

_age_class(person) = trunc(Int, age(person)/10)

_share_childless_men(people, ageclass::Int) = 
    count( x -> isMale(x) && !hasDependents(x) && _age_class(x) == ageclass , people) / length(people)

# is memoization really needed? 
# This can be stored as a time-dependent model variable 
@memoize Dict function shareMenNoChildren_(model, time::Rational{Int}, ageclass :: Int)
    nAll = 0
    nNoC = 0
    for p in Iterators.filter(x->alive(x) && isMale(x) && _age_class(x) == ageclass, allPeople(model))
        nAll += 1
        # only looks at legally dependent persons (which usually are underage and 
        # living in the same household)
        if !hasDependents(p)
            nNoC += 1
        end
    end

    nNoC / nAll
end

_eligible_women(people, minPregnancyAge) = 
    [f for f in people if isFemale(f) && isSingle(f) && age(f) > minPregnancyAge]

@memoize eligibleWomen_(model, time::Rational{Int}, pars) = [f for f in allPeople(model) if isFemale(f) && alive(f) &&
                                       isSingle(f) && age(f) > pars.minPregnancyAge]

# reset memoization caches
# needs to be done on every time step
# Probably no need if time is an argument / yes works 
function resetCacheMarriages()
    Memoization.empty_cache!(shareMenNoChildren_)
    Memoization.empty_cache!(eligibleWomen_)
end


function _delta_age(delta)
    if delta <= -10
        0
    elseif -10 < delta < -2
        1
    elseif -2 < delta < 1
        2
    elseif 1 < delta < 5
        3
    elseif 5 < delta < 10
        4
    else
        5
    end
end

_geo_distance(m, w, pars) = 
    manhattanDistance(getHomeTown(m), getHomeTown(w)) /
    (pars.mapGridXDimension + pars.mapGridYDimension)

function _marry_weight(man, woman, pars)
    geoFactor = 1/exp(pars.betaGeoExp * _geo_distance(man, woman, pars))
    if status(woman) == WorkStatus.student 
        studentFactor = pars.studentFactorParam
        womanRank = maxParentRank(woman)
    else
        studentFactor = 1.0
        womanRank = classRank(woman)
    end
    statusDistance = abs(classRank(man) - womanRank) / (length(pars.cumProbClasses) - 1)
    betaExponent = pars.betaSocExp * (classRank(man) < womanRank ? 1.0 : pars.rankGenderBias)
    socFactor = 1/exp(betaExponent * statusDistance)
    ageFactor = pars.deltaAgeProb[_delta_age(age(man) - age(woman))]
    # legal dependents (i.e. usually underage persons living at the same house)
    numChildrenWithWoman = length(dependents(woman))
    childrenFactor = 1/exp(pars.bridesChildrenExp * numChildrenWithWoman)
    return geoFactor * socFactor * ageFactor * childrenFactor * studentFactor
end


selectMarriage(p, pars) = alive(p) & isMale(p) && isSingle(p) && age(p) > pars.ageOfAdulthood &&
    careNeedLevel(p) < 4

_select_marriage(p, ageOfAdulthood) = 
    isMale(p) && isSingle(p) && age(p) > ageOfAdulthood && careNeedLevel(p) < 4

function _join_couple!(man, woman, model, pars)
    # they stay apart
    if rand() >= pars.probApartWillMoveTogether
        return false
    end
    # decide who leads the move
    (decider , follower) = number_of_occupants(home(man)) > number_of_occupants(home(woman)) ? 
        (man , woman) : (woman , man)  
    if rand() < pars.couplesMoveToExistingHousehold  
        targetHouse = house(decider) 
        for person in dependents(follower)
            @assert home(person) === home(follower)
        end
        move_people_to_house!(dependents(follower),targetHouse)
        move_person_to_person_house!(follower,decider) 
        @assert home(decider) === home(follower)
    else
        distance = rand((InTown(),AdjTown())) 
        move_person_to_emptyhouse!(decider,model,distance) 
        move_person_to_person_house!(follower,decider)
        move_people_to_house!(dependents(decider),home(decider)) 
        move_people_to_house!(dependents(follower),home(decider))
    end
    # TODO movedThisYear
    # required by moving around (I think)
    return true
end

function _marriage!(man, time, model, pars, eligibleWomen, ageclass, shareChildlessMens) 
    manMarriageProb = pars.basicMaleMarriageProb * pars.maleMarriageModifierByDecade[ageclass]
    if status(man) != WorkStatus.worker || careNeedLevel(man) > 1
        manMarriageProb *= pars.notWorkingMarriageBias
    end
    den = shareChildlessMens + (1 - shareChildlessMens) * pars.manWithChildrenBias
    prob = manMarriageProb / den * (hasDependents(man) ? pars.manWithChildrenBias : 1)
    if rand() >= p_yearly2monthly(prob) 
        return false 
    end

    #
    # can be simplified without so many arrays 
    #

    # we store candidates as indices, so that we can efficiently remove married women 
    candidates = [i for (i,w) in enumerate(eligibleWomen) if (age(man)-10 < age(w) < age(man)+5)  &&
        # exclude siblings as well
        !livingTogether(man, w) && !related1stDegree(man, w) ]
    if length(candidates) == 0
        return false 
    end
    weights = [_marry_weight(man, eligibleWomen[idx], pars) for idx in candidates]
    cumsum!(weights, weights)
    if weights[end] == 0
        selected = rand(1:length(weights))
    else
        r = rand() * weights[end]
        selected = findfirst(>(r), weights)
        @assert selected != nothing
    end
    selectedIdx = candidates[selected]
    selectedWoman = eligibleWomen[selectedIdx]
    setAsPartners!(man, selectedWoman)
    # remove from cached list
    remove_unsorted!(eligibleWomen, selectedIdx)
    _join_couple!(man, selectedWoman, model, pars)
    dep_man = dependents(man)
    dep_woman = dependents(selectedWoman)
    # all dependents become joint dependents
    for child in dep_man
        setAsGuardianDependent!(selectedWoman, child)
    end
    for child in dep_woman
        setAsGuardianDependent!(man, child)
    end
    true 
end 

function marriage!(man, time, model, parameters) 
    pars = fuse(populationParameters(parameters), marriageParameters(parameters), 
                    birthParameters(parameters), mapParameters(parameters))
    ageclass = _age_class(man) 
    snc =  _share_childless_men(model, ageclass)
    ewomen = eligibleWomen_(model, time, pars)
    return _marriage!(man, time, model, pars, ewomen, ageclass, snc)
end 

_init_return(::NoReturn) = nothing 
_init_return(::WithReturn) = Person[] 
_progress_return!(married,man,::NoReturn) = nothing 
function _progress_return!(married,man,::WithReturn) 
    wife = partner(man) 
    append!(married, [man, wife])
    nothing
end 

function _verbose_domarriages(man) 
    delayedVerbose() do
        println("man $(man.id) married to woman $(partner(man).id)")
    end
end

function _verbose_domarriages(nmarried::Int) 
    delayedVerbose() do
        println("# of married : $(nmarried)")
    end
end

function _domarriages!(people,model,time,rettype::FuncReturn)
    parameters = allParameters(model)
    resetCacheMarriages()
    married = _init_return(rettype) 
    ageOfAdulthood = workParameters(model).ageOfAdulthood
    pars = fuse(populationParameters(parameters), marriageParameters(parameters), 
                birthParameters(parameters), mapParameters(parameters))
    ewomen = eligibleWomen_(model, time, pars)
    snc = Vector{Float64}(undef,20)
    for i in 1:20
        snc[i] = _share_childless_men(people, i-1)
    end 
    nmarried = 0 
    for man in people 
        if !_select_marriage(man,ageOfAdulthood) continue end
        ageclass = _age_class(man) 
        if _marriage!(man, time, model, pars, ewomen, ageclass, snc[ageclass+1])
            _progress_return!(married,man,rettype)
            _verbose_domarriages(man)
            nmarried += 2
        end 
    end 
    _verbose_domarriages(nmarried)
    return married 
end 

# move this to traits? 
_selected_population(model,::FullPopulation) = alivePeople(model)
_selected_population(model,::AlivePopulation) = allPeople(model)

domarriages!(model, time, popfeature::PopulationFeature, rettype::FuncReturn) =
    _domarriages!(_selected_population(model,popfeature), model, time, rettype)

domarriages!(model,time) = 
    domarriages!(model, time, AlivePopulation(), NoReturn())