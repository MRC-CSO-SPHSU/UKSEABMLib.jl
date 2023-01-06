using ....XAgents

export resetCacheMarriages, marriage!, domarriages!

_age_class(person) = trunc(Int, age(person)/10)

# Is this share childless mens among mens or among all people ?
_share_childless_men(people, ageclass::Int, ::AlivePopulation) = 
    length(people) == 0 ? 0 : 
        count( x -> isMale(x) && !hasDependents(x) && _age_class(x) == ageclass , people) / length(people)

function _share_childless_men(people, ageclass::Int, ::FullPopulation)  
    nalive = count(x -> alive(x) , people)
    ret = nalive == 0 ?  
        0 : 
        count( x -> alive(x) && isMale(x) && !hasDependents(x) && _age_class(x) == ageclass , people) / nalive 
    return ret    
end

const _SNC_SIZE = 20 
const _SNC = Vector{Float64}(undef,_SNC_SIZE)
function _share_childless_men(people, popfeature)
    for i in 1:_SNC_SIZE
        _SNC[i] = _share_childless_men(people, i-1, popfeature)
    end 
    @assert _SNC[_SNC_SIZE] == 0 
    return _SNC 
end 

_is_eligible(f,minPregnancyAge,::AlivePopulation) = isFemale(f) && isSingle(f) && age(f) > minPregnancyAge
_is_eligible(f,minPregnancyAge,::FullPopulation) = alive(f) && _is_eligible(f,minPregnancyAge,AlivePopulation())

const _ELIGIBLE_WOMEN = Person[] 
function _compute_eligible_women(people, minPregnancyAge,popfeature) 
    # [f for f in people if _is_eligible(f,minPregnancyAge,popfeature)]
    empty!(_ELIGIBLE_WOMEN) 
    for f in people  
        if _is_eligible(f,minPregnancyAge,popfeature) 
            push!(_ELIGIBLE_WOMEN,f)
        end
    end
    return _ELIGIBLE_WOMEN
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

_geo_distance(m, w, mappars) = 
    manhattanDistance(getHomeTown(m), getHomeTown(w)) /
    (mappars.mapGridXDimension + mappars.mapGridYDimension)

function _marry_weight(man, woman, marpars, mappars, poppars)
    geoFactor = 1/exp(marpars.betaGeoExp * _geo_distance(man, woman, mappars))
    if status(woman) == WorkStatus.student 
        studentFactor = marpars.studentFactorParam
        womanRank = maxParentRank(woman)
    else
        studentFactor = 1.0
        womanRank = classRank(woman)
    end
    statusDistance = abs(classRank(man) - womanRank) / (length(poppars.cumProbClasses) - 1)
    betaExponent = marpars.betaSocExp * (classRank(man) < womanRank ? 1.0 : marpars.rankGenderBias)
    socFactor = 1/exp(betaExponent * statusDistance)
    ageFactor = marpars.deltaAgeProb[_delta_age(age(man) - age(woman))]
    # legal dependents (i.e. usually underage persons living at the same house)
    numChildrenWithWoman = length(dependents(woman))
    childrenFactor = 1/exp(marpars.bridesChildrenExp * numChildrenWithWoman)
    return geoFactor * socFactor * ageFactor * childrenFactor * studentFactor
end

const _WEIGHTS = Float64[] 
function _compute_weights(man, eligibleWomen, candidates, marpars, mappars, poppars) 
    # [_marry_weight(man, eligibleWomen[idx], pars) for idx in candidates]
    empty!(_WEIGHTS) 
    for idx in candidates
        push!(_WEIGHTS, _marry_weight(man, eligibleWomen[idx], marpars, mappars, poppars))
    end 
    return _WEIGHTS
end 

function _join_couple!(man, woman, model, marpars)
    # they stay apart
    if rand() >= marpars.probApartWillMoveTogether
        return false
    end
    # decide who leads the move
    (decider , follower) = number_of_occupants(home(man)) > number_of_occupants(home(woman)) ? 
        (man , woman) : (woman , man)  
    if rand() < marpars.couplesMoveToExistingHousehold  
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

const _CANDIDATES = Int[] 
function _compute_candidates(man, eligibleWomen) 
    empty!(_CANDIDATES)
    for (i,w) in enumerate(eligibleWomen) 
        if (age(man)-10 < age(w) < age(man)+5)  &&
            # exclude siblings as well
            !livingTogether(man, w) && !related1stDegree(man, w)
            push!(_CANDIDATES,i)
        end
    end
    return _CANDIDATES
end

selectedfor(man, ageOfAdulthood, ::AlivePopulation, ::Marriage) = 
    isMale(man) && isSingle(man) && age(man) > ageOfAdulthood && careNeedLevel(man) < 4
selectedfor(man, ageOfAdulthood, ::FullPopulation, process::Marriage) = 
    alive(man) && selectedfor(man, ageOfAdulthood, AlivePopulation(), process)

function _marriage!(man, time, model, eligibleWomen, ageclass, shareChildlessMens, popfeature) 
    if !selectedfor(man,workParameters(model).ageOfAdulthood,popfeature,Marriage()) return false end
    marpars = marriageParameters(model) 
    manMarriageProb = marpars.basicMaleMarriageProb * marpars.maleMarriageModifierByDecade[ageclass]
    if status(man) != WorkStatus.worker || careNeedLevel(man) > 1
        manMarriageProb *= marpars.notWorkingMarriageBias
    end
    den = shareChildlessMens + (1 - shareChildlessMens) * marpars.manWithChildrenBias
    prob = manMarriageProb / den * (hasDependents(man) ? marpars.manWithChildrenBias : 1)

    if rand() >= p_yearly2monthly(prob) 
        return false 
    end

    candidates = _compute_candidates(man, eligibleWomen)
    if length(candidates) == 0
        return false 
    end

    weights =  _compute_weights(man, eligibleWomen, candidates, marpars, mapParameters(model), populationParameters(model)) # this worthen memory 
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
    @assert isFemale(selectedWoman) && alive(selectedWoman)
    setAsPartners!(man, selectedWoman)
    # remove from cached list
    remove_unsorted!(eligibleWomen, selectedIdx)
    _join_couple!(man, selectedWoman, model, marpars)
    dep_man = dependents(man)
    dep_woman = dependents(selectedWoman)
    # all dependents become joint dependents
    for child in dep_man
        setAsGuardianDependent!(selectedWoman, child)
    end
    for child in dep_woman
        setAsGuardianDependent!(man, child)
    end
    verbose(man,Marriage())
    return true 
end 

function marriage!(man, time, model, popfeatue::PopulationFeature = FullPopulation()) 
    ageclass = _age_class(man) 
    snc =  share_childless_men(model, ageclass)
    ewomen = eligible_women(model)
    return _marriage!(man, time, model, ewomen, ageclass, snc, popfeatue)
end 

verbosemsg(::Marriage) = "marriages"
verbosemsg(person::Person,::Marriage) =
    "person $(person.id) married to $(partner(person).id)" 

function _domarriages!(ret,model,time, popfeature)
    verbose_houses(model,"before domarriages!")
    ret = init_return!(ret) 
    people = select_population(model,nothing,popfeature,Marriage())
    minPregnancyAge = birthParameters(model).minPregnancyAge
    # pars = fuse(populationParameters(model), marriageParameters(model), 
    #            birthParameters(model), mapParameters(model))
    ewomen = _compute_eligible_women(people, minPregnancyAge, popfeature)
    snc = _share_childless_men(people, popfeature)
    for (ind,man) in enumerate(people) 
        ageclass = _age_class(man) 
        if _marriage!(man, time, model, ewomen, ageclass, snc[ageclass+1], popfeature)
            ret = progress_return!(ret,(ind=ind,person=man))
        end 
    end 
    verbose(ret,Marriage())
    verbose_houses(model,"after domarriages!")
    return ret 
end 

domarriages!(model, time, popfeature::PopulationFeature, ret=nothing) =
    _domarriages!(ret, model, time, popfeature)

domarriages!(model,time,ret=nothing) = 
    domarriages!(model, time, AlivePopulation(),ret)