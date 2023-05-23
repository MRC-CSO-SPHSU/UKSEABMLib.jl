using ....XAgents

export marriage!, domarriages!

_age_class(person) = trunc(Int, age(person) * 0.1)

_is_childless_man(person,ageclass::Int) =
    ismale(person) && !has_dependents(person) && _age_class(person) == ageclass
_is_childless_man(person,ageclass::Int,::AlivePopulation) =
    _is_childless_man(person,ageclass)
_is_childless_man(person,ageclass::Int,::FullPopulation) =
    isalive(person) && _is_childless_man(person,ageclass)

_num_alive_people(people,::AlivePopulation) = length(people)
_num_alive_people(people,::FullPopulation) = nalive = count(x -> alive(x) , people)

# Is this share childless mens among mens or among all people ?
function _share_childless_men(people, ageclass::Int, popfeature)
    nalive = _num_alive_people(people,popfeature)
    ret = nalive == 0 ?
        0 :
        count( x -> _is_childless_man(x,ageclass,popfeature) , people) / nalive
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

_is_eligible(f,minPregnancyAge,::AlivePopulation) =
    isfemale(f) && issingle(f) && age(f) > minPregnancyAge
_is_eligible(f,minPregnancyAge,::FullPopulation) =
    alive(f) && _is_eligible(f,minPregnancyAge,AlivePopulation())

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
    manhattan_distance(hometown(m), hometown(w)) /
    (mappars.mapGridXDimension + mappars.mapGridYDimension)

function _marry_weight(man, woman, marpars, mappars, poppars)
    geoFactor = 1/exp(marpars.betaGeoExp * _geo_distance(man, woman, mappars))
    if status(woman) == WorkStatus.student
        studentFactor = marpars.studentFactorParam
        womanRank = max_parent_rank(woman)
    else
        studentFactor = 1.0
        womanRank = classRank(woman)
    end
    statusDistance = abs(classRank(man) - womanRank) / (length(poppars.cumProbClasses) - 1)
    betaExponent = marpars.betaSocExp * (classRank(man) < womanRank ?
                        1.0 : marpars.rankGenderBias)
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
    (decider , follower) = num_occupants(home(man)) > num_occupants(home(woman)) ?
            (man , woman) : (woman , man)
    if rand() < marpars.couplesMoveToExistingHousehold
        targetHouse = house(decider)
        for person in dependents(follower)
            @assert home(person) === home(follower)
        end
        move_to_house!(dependents(follower),targetHouse)
        move_to_person_house!(follower,decider)
        @assert home(decider) === home(follower)
    else
        distance = rand((InTown(),AdjTown()))
        move_to_empty_house!(decider,model,distance)
        move_to_person_house!(follower,decider)
        move_to_house!(dependents(decider),home(decider))
        move_to_house!(dependents(follower),home(decider))
    end
    # TODO movedThisYear
    # required by moving around (I think)
    return true
end

const _EW_CANDIDATES = Int[]
function _compute_ew_candidates(man, eligibleWomen)
    empty!(_EW_CANDIDATES)
    for (i,w) in enumerate(eligibleWomen)
        if (age(man)-10 < age(w) < age(man)+5)  &&
            # exclude siblings as well
            !are_living_together(man, w) && !related_first_degree(man, w)
            push!(_EW_CANDIDATES,i)
        end
    end
    return _EW_CANDIDATES
end

selectedfor(man, ageOfAdulthood, ::AlivePopulation, ::Marriage) =
    ismale(man) && issingle(man) && age(man) > ageOfAdulthood && careNeedLevel(man) < 4
selectedfor(man, ageOfAdulthood, ::FullPopulation, process::Marriage) =
    alive(man) && selectedfor(man, ageOfAdulthood, AlivePopulation(), process)

function _marriage!(man, model, eligibleWomen, ageclass, shareChildlessMens, popfeature)
    if !selectedfor(man,work_pars(model).ageOfAdulthood,popfeature,Marriage())
        return false
    end
    marpars = marriage_pars(model)
    manMarriageProb =
        marpars.basicMaleMarriageProb * marpars.maleMarriageModifierByDecade[ageclass]
    if status(man) != WorkStatus.worker || careNeedLevel(man) > 1
        manMarriageProb *= marpars.notWorkingMarriageBias
    end
    den = shareChildlessMens + (1 - shareChildlessMens) * marpars.manWithChildrenBias
    prob = manMarriageProb / den * (has_dependents(man) ? marpars.manWithChildrenBias : 1)

    if rand() >= p_yearly2monthly(prob)
        return false
    end

    candidates = _compute_ew_candidates(man, eligibleWomen)
    if length(candidates) == 0
        return false
    end

    weights = _compute_weights(man, eligibleWomen, candidates, marpars,
                                map_pars(model), population_pars(model))
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
    @assert isfemale(selectedWoman) && alive(selectedWoman)
    set_as_partners!(man, selectedWoman)
    # remove from cached list
    remove_unsorted!(eligibleWomen, selectedIdx)
    _join_couple!(man, selectedWoman, model, marpars)
    dep_man = dependents(man)
    dep_woman = dependents(selectedWoman)
    # all dependents become joint dependents
    for child in dep_man
        set_as_guardian_dependent!(selectedWoman, child)
    end
    for child in dep_woman
        set_as_guardian_dependent!(man, child)
    end
    verbose(man,Marriage())
    return true
end

function marriage!(man, model, popfeatue::PopulationFeature = FullPopulation())
    ageclass = _age_class(man)
    snc =  share_childless_men(model, ageclass)
    ewomen = eligible_women(model)
    return _marriage!(man, model, ewomen, ageclass, snc, popfeatue)
end

verbosemsg(::Marriage) = "marriages"
verbosemsg(person::Person,::Marriage) =
    "person $(person.id) married to $(partner(person).id)"

function _domarriages!(ret,model, popfeature)
    verbose_houses(model,"before domarriages!")
    ret = init_return!(ret)
    people = select_population(model,nothing,popfeature,Marriage())
    minPregnancyAge = birth_pars(model).minPregnancyAge
    # pars = fuse(population_pars(model), marriage_pars(model),
    #            birth_pars(model), map_pars(model))
    ewomen = _compute_eligible_women(people, minPregnancyAge, popfeature)
    snc = _share_childless_men(people, popfeature)
    for (ind,man) in enumerate(people)
        ageclass = _age_class(man)
        if _marriage!(man, model, ewomen, ageclass, snc[ageclass+1], popfeature)
            ret = progress_return!(ret,(ind=ind,person=man))
        end
    end
    verbose(ret,Marriage())
    verbose_houses(model,"after domarriages!")
    return ret
end

domarriages!(model, popfeature::PopulationFeature, ret=nothing) =
    _domarriages!(ret, model, popfeature)

domarriages!(model, ret=nothing) =
    domarriages!(model, FullPopulation(),ret)
