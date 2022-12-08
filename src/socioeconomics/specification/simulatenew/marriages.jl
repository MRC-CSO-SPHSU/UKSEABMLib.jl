using Memoization
using ....XAgents

export resetCacheMarriages, marriage!, selectMarriage, doMarriages!


ageClass_(person) = trunc(Int, age(person)/10)


@memoize Dict function shareMenNoChildren_(model, ageclass :: Int)
    nAll = 0
    nNoC = 0

    for p in Iterators.filter(x->alive(x) && isMale(x) && ageClass_(x) == ageclass, allPeople(model))
        nAll += 1
        # only looks at legally dependent persons (which usually are underage and 
        # living in the same household)
        if !hasDependents(p)
            nNoC += 1
        end
    end

    nNoC / nAll
end


@memoize eligibleWomen_(model, pars) = [f for f in allPeople(model) if isFemale(f) && alive(f) &&
                                       isSingle(f) && age(f) > pars.minPregnancyAge]

# reset memoization caches
# needs to be done on every time step
function resetCacheMarriages()
    Memoization.empty_cache!(shareMenNoChildren_)
    Memoization.empty_cache!(eligibleWomen_)
end


function deltaAge_(delta)
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


function marryWeight_(man, woman, pars)
    geoFactor = 1/exp(pars.betaGeoExp * geoDistance_(man, woman, pars))

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

    ageFactor = pars.deltaAgeProb[deltaAge_(age(man) - age(woman))]

    # legal dependents (i.e. usually underage persons living at the same house)
    numChildrenWithWoman = length(dependents(woman))

    childrenFactor = 1/exp(pars.bridesChildrenExp * numChildrenWithWoman)

    geoFactor * socFactor * ageFactor * childrenFactor * studentFactor
end

geoDistance_(m, w, pars) = manhattanDistance(getHomeTown(m), getHomeTown(w))/
    (pars.mapGridXDimension + pars.mapGridYDimension)

# Atiyah: I thing alive(p) should be included? 
selectMarriage(p, pars) = alive(p) & isMale(p) && isSingle(p) && age(p) > pars.ageOfAdulthood &&
    careNeedLevel(p) < 4


function joinCouple_!(man, woman, model, pars)
    # they stay apart
    if rand() >= pars.probApartWillMoveTogether
        return false
    end

    # decide who leads the move
    peopleToMove = rand()<0.5 ? [man, woman] : [woman, man]

    append!(peopleToMove, gatherDependentsSingle(man), gatherDependentsSingle(woman))

    if rand() < pars.couplesMoveToExistingHousehold
        targetHouse = nOccupants(man.pos) > nOccupants(woman.pos) ? 
            woman.pos : man.pos

        movePeopleToHouse!(targetHouse, peopleToMove)
    else
        distance = rand([:here, :near])
        movePeopleToEmptyHouse!(peopleToMove, distance, houses(model), towns(model))
    end

    # TODO movedThisYear
    # required by moving around (I think)
    
    true
end

function marriage!(man, time, model, parameters) 

    pars = fuse(populationParameters(parameters), marriageParameters(parameters), 
                    birthParameters(parameters), mapParameters(parameters))

    ageclass = ageClass_(man) 

    manMarriageProb = pars.basicMaleMarriageProb * pars.maleMarriageModifierByDecade[ageclass]

    if status(man) != WorkStatus.worker || careNeedLevel(man) > 1
        manMarriageProb *= pars.notWorkingMarriageBias
    end

    snc = shareMenNoChildren_(model, ageclass)
    den = snc + (1-snc) * pars.manWithChildrenBias

    prob = manMarriageProb / den * (hasDependents(man) ? pars.manWithChildrenBias : 1)

    if rand() >= p_yearly2monthly(prob) 
        return false 
    end

    # get cached list
    # note: this is getting updated as we go
    women = eligibleWomen_(model, pars)

    # we store candidates as indices, so that we can efficiently remove married women 
    candidates = [i for (i,w) in enumerate(women) if (age(man)-10 < age(w) < age(man)+5)  &&
                                                # exclude siblings as well
                          !livingTogether(man, w) && !related1stDegree(man, w) ]
    
    if length(candidates) == 0
        return false 
    end

    weights = [marryWeight_(man, women[idx], pars) for idx in candidates]

    cumsum!(weights, weights)
    if weights[end] == 0
        selected = rand(1:length(weights))
    else
        r = rand() * weights[end]
        selected = findfirst(>(r), weights)
        @assert selected != nothing
    end

    selectedIdx = candidates[selected]
    selectedWoman = women[selectedIdx]

    setAsPartners!(man, selectedWoman)
    # remove from cached list
    remove_unsorted!(women, selectedIdx)

    joinCouple_!(man, selectedWoman, model, pars)

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

function doMarriages!(model,time)
    
    parameters = allParameters(model)
    people = allPeople(model)

    resetCacheMarriages()

    singleMens = [ man for man in people if selectMarriage(man, workParameters(model)) ]

    married = Person[] 
    
    for man in singleMens 
        if marriage!(man, time, model, parameters)
            wife = partner(man)  
            append!(married,[man, wife]) 
        end 
    end 

    delayedVerbose() do
        println("# of married in current iteration $(length(married))")
    end
    
    married 
end # doMarriages 


# for now simply all dependents
function gatherDependentsSingle(person)
    assumption() do
        for p in dependents(person)
            @assert p.pos == person.pos
            @assert length(guardians(p)) == 1
            @assert guardians(p)[1] == person
        end
    end

    dependents(person)
end

    

