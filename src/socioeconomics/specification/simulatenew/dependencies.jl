export selectAssignGuardian, assignGuardian!, doAssignGuardians! 

function hasValidGuardian_(person)
    for g in guardians(person)
        if alive(g)
            return true
        end
    end

    false
end


selectAssignGuardian(person) = alive(person) && !canLiveAlone(person) && 
    !hasValidGuardian_(person)


function assignGuardian!(person, time, model)
    guard = findFamilyGuardian_(person)
    people = allPeople(model)
    if guard == nothing
        guard = findOtherGuardian_(person, people)
    end

    # get rid of previous (possibly dead) guardians
    # this implies that relatives of a non-related former legal guardian
    # that are now excluded due to age won't get a chance again in the future
    empty!(guardians(person))

    if guard == nothing
        return false
    end

    # guard and partner become new guardians
    adopt_!(guard, person)

    true
end

function doAssignGuardians!(model, time) 

    people = allPeople(model) 

    orphans = [ person for person in people if selectAssignGuardian(person) ]

    n = length(orphans)
    for orphan in orphans 
        # Warn if no guardian is selected for an orphan 
        if assignGuardian!(orphan, time, model)
            n -= 1 
        end 
    end

    delayedVerbose() do 
        println("# of orphans : $(length(orphans)) out of which $(n) has been adopted")
        if length(orphans) > 0 
            println("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")
        end
    end

end 
    
function findFamilyGuardian_(person)
    potGuardians = Vector{Union{Person, Nothing}}()

    pparents = parents(person)
    # these might be nonexistent or dead
    append!(potGuardians, pparents)

    # these can but don't have to be identical to the parents
    for g in guardians(person)
        push!(potGuardians, partner(g))
    end

    # relatives of biological parents
    # any of these might already be guardians, but in that case they will be dead
    for p in pparents
        if p == nothing
            continue
        end
        append!(potGuardians, parents(p))
        append!(potGuardians, siblings(p))
    end
    
    # possible overlap with previous, but doesn't matter
    for g in guardians(person)
        append!(potGuardians, parents(g))
        append!(potGuardians, siblings(g))
    end

    # potentially lots of redundancy, but just take the first 
    # candidate that works
    for g in potGuardians
        if g == nothing || !alive(g) || age(g) < 18 
            continue
        end
        return g
    end

    return nothing
end

function findOtherGuardian_(person, people)
    candidates = [ p for p in people if 
        isFemale(p) && canLiveAlone(p) && !isSingle(p) && 
            (status(p) == WorkStatus.worker || status(partner(p)) == WorkStatus.worker) ]

    if length(candidates) > 0
        return rand(candidates)
    end

    return nothing
end


function adopt_!(guard, person)
    movePeopleToHouse!([person], guard.pos)
    setAsGuardianDependent!(guard, person)
    if ! isSingle(guard)
        setAsGuardianDependent!(partner(guard), person)
    end
end
