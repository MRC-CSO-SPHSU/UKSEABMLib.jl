export do_assign_guardians!, assign_guardian!

function _has_valid_guardian(person)
    for g in guardians(person)
        if alive(g)
            return true
        end
    end
    return false
end

selectedfor(person,pars,::AlivePopulation,::AssignGuardian) =
    !can_live_alone(person) && !_has_valid_guardian(person)
selectedfor(person,pars,::FullPopulation,process::AssignGuardian) =
    alive(person) && selectedfor(person,pars,AlivePopulation(),process)

_valid_guardian(::Nothing) = false
_valid_guardian(g) = alive(g)  && can_live_alone(g)
_valid_guardian(g,::AlivePopulation) = can_live_alone(g)
_valid_guardian(g,::FullPopulation) = alive(g) && _valid_guardian(g,AlivePopulation())

function _related_vaid_guardian(person)
    if _valid_guardian(father(person)) return father(person) end
    if _valid_guardian(mother(person)) return mother(person) end
    for p in siblings(person)
        if _valid_guardian(p) return p end
    end
    return nothing
end

function _find_guardian_family(person)::Person
    if (p = _related_vaid_guardian(person)) != nothing return p end
    for g in guardians(person)
        if _valid_guardian(g) return g end
    end
    # relatives of biological parents
    # any of these might already be guardians, but in that case they will be dead
    if (p = _related_vaid_guardian(father(person))) != nothing return p end
    if (p = _related_vaid_guardian(mother(person))) != nothing return p end
    # possible overlap with previous, but doesn't matter
    for g in guardians(person)
        if (p = _related_vaid_guardian(g)) != nothing return p end
    end
    return person
end

const _G_CANDIDATES = Person[]
function _guardian_candidates(model,norphans,popfeature)
    empty!(_G_CANDIDATES)
    people = all_people(model) # select_population(model,nothing,popfeature,AssignGuardian())
    for p in people
        if _valid_guardian(p,popfeature) && isfemale(p) && !issingle(p)
            # && (status(p) == WorkStatus.worker || status(partner(p)) == WorkStatus.worker)
            push!(_G_CANDIDATES,p)
            if length(_G_CANDIDATES) > norphans return _G_CANDIDATES end
        end
    end
    return _G_CANDIDATES
end

function _find_random_guardian(model,popfeature)
    candidates = _guardian_candidates(model,popfeature)
    if length(candidates) > 0
        return rand(candidates)
    end
    error("no guardian was found for $(person)")
    #=people = alive_people(model,popfeature)
    g = rand(people)
    while !_valid_guardian(g,popfeature) || !isfemale(g) || !issingle(g)
        g = rand(people)
    end
    return g =#
    return people[1]
end

function _adopt!(guard, person)
    move_to_person_house!(person, guard)
    set_as_guardian_dependent!(guard, person)
    if ! issingle(guard)
        set_as_guardian_dependent!(partner(guard), person)
    end
end

function _assign_guardian!(person, gcandidates, popfeature)
    guard = _find_guardian_family(person)
    if guard === person
        guard = rand(gcandidates)
    end
    # get rid of previous (possibly dead) guardians
    # this implies that relatives of a non-related former legal guardian
    # that are now excluded due to age won't get a chance again in the future
    empty!(guardians(person))
    if isnoperson(guard) || guard === person
        return false
    end
    # guard and partner become new guardians
    _adopt!(guard, person)
    return true
end

function assign_guardian!(person, model,popfeature::PopulationFeature=FullPopulation())
    gcandidates = _guardian_candidates(model,1000, popfeature)
    return _assign_guardian!(person, gcandidates, popfeature)
end

const _ORPHANS = Person[]
function _orphans(model,popfeature)
    empty!(_ORPHANS)
    people = select_population(model,nothing,popfeature,AssignGuardian())
    for p in people
        if selectedfor(p,nothing,FullPopulation(),AssignGuardian())
            push!(_ORPHANS,p)
        end
    end
    return _ORPHANS
end

verbosemsg(::AssignGuardian) = "orphans"
verbosemsg(orphan,::AssignGuardian) = "orphan $(orphan.id) got adopted"

function _do_assign_guardians!(ret,model, popfeature)
    ret = init_return!(ret)
    orphans = _orphans(model,popfeature)
    n = length(orphans)
    gcandidates = _guardian_candidates(model,n,popfeature)
    for (ind,orphan) in enumerate(orphans)
        if _assign_guardian!(orphan, gcandidates, popfeature)
            ret = progress_return!(ret,(ind=ind,person=orphan))
            n -= 1
        end
    end
    @assert n == 0
    verbose(ret,AssignGuardian())
    return ret
end

do_assign_guardians!(model,popfeature::PopulationFeature,ret=nothing) =
    _do_assign_guardians!(ret,model,popfeature)

do_assign_guardians!(model,ret=nothing) =
    do_assign_guardians!(model,FullPopulation(),ret)
