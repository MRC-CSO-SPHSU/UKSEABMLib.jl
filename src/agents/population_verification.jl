export verify_no_homeless, verify_no_motherless_child, verify_child_is_with_a_parent,
    verify_children_parents_consistency, verify_partnership_consistency,
    verify_singles_live_alone, verify_family_lives_together,
    verify_houses_consistency

"used to verify pre-assumed housing initialization is done correctly"
function verify_no_homeless(population)
    for person in population
        if ishomeless(person)
            return false
        end
    end
    return true
end

"verifying that kinship initialization is done correctly"
function verify_no_motherless_child(population)
    for person in population
        if ischild(person) && isnoperson(mother(person))
            @show "motherless child : $(person)"
            return false
        end
    end
    return true
end

function verify_child_is_with_a_parent(population)
    for child in population
        if !ischild(child) continue end
        # check that there is at least one defined parent
        @assert father(child) != nothing || mother(child) != nothing
        if (father(child) != nothing && home(father(child)) === home(child)) ||
            (mother(child) != nothing && home(mother(child)) === home(child))
            continue
        end
        @info "child not with any of his parents:"
        @info child
        m = mother(child)
        f = father(child)
        @show "parents:"
        isnoperson(m) ? nothing : @info m
        isnoperson(f) ? nothing : @info f
        @show "occupants"
        for occupant in occupants(home(child))
            @info occupant
        end
        return false
    end
    return true
end

function verify_no_parentless_child(population)
    kids = [kid for kid in population if ischild(kid)]
    parentsfunc = [mother, father]

    for child in kids
        if isnoperson(mother(child)) && isnoperson(father(child))
            @warn "a parentless child identified"
            @info aparent(child)
            return false
        end
        for aparent in parentsfunc
            if !(isnoperson(aparent(child)))
                if !(aparent(child) in population)
                    @warn "a parent does not exist in population"
                    @info aparent(child)
                    return false
                end
                if !(child in children(aparent(child)))
                    @warn "inconsistency parent <=> child identified"
                    @info child
                    @info aparent(child)
                    return false
                end
            end
        end
    end
    return true
end

function verify_parentship_consistency(population)
    for parent in population
        if !has_children(parent) continue end
        if ischild(parent)
            @warn "an assumed parent is a child"
            @info parent
            return false
        end

        if !(issubset(children(parent),population))
            @warn "non adult children not in the population"
            @info parent
            for child in children(parent)
                @info child
            end
            return false
        end
    end
    return true
end

"""
verify that
    - no parentless children
    - a parent of a child should exist in the population
    - a child is in the children list of a parent
    - a parent should be an adult
    - children of a parent are in the population
"""
function verify_children_parents_consistency(population)
    if !verify_no_parentless_child(population)
        return false
    end
    if !verify_parentship_consistency(population)
        return true
    end
    return true
end

"verify consistency of partnership relations"
function verify_partnership_consistency(population)
    for person in population
        if !issingle(person)
            if !(partner(person) in population) return false end
            if issingle(partner(person)) return false end
            if partner(partner(person)) !== person return false end
        end
    end
    return true
end

function verify_singles_live_alone(population)
    for single in population
        if ischild(single) continue end
        if !issingle(single) continue end
        if has_children(single) continue end
        if !(single in home(single).occupants)
            @show "single not in the occupant list of his house"
            @info single
            return false
        end
        if length(occupants(home(single))) != 1
            @show "single does not live alone"
            @info single
            return false
        end
    end
    return true
end

"""
verify that families lives together. A family could be
- a married couple
- a single lone parent
"""
function verify_family_lives_together(population)
    for person in population
        if is_lone_parent(person)
            nothing
        elseif issingle(person)
            continue
        end
        if !isnoperson(partner(person))
            if !(partner(person) in population)
                @info "person's partner not in population"
                @info partner(person)
                return false
            end
            if home(partner(person)) !== home(partner(person))
                @info "partner's home not the identical"
                @info partner(person)
                return false
            end
        end
        for child in children(person)
            if !ischild(child) continue end
            if !(child in population)
                @info "a child not in population"
                @info child
                return false
            end
            if home(child) !== home(person)
                @info "child home not identical to parent home"
                @info child
                return false
            end
        end
    end
    return true
end

# TODO this function fits better with model as an argument
function verify_houses_consistency(population,allhouses)
    for house in allhouses
        if isempty(house) continue end
        occs = occupants(house)
        if length(occs) == 1 continue end
        for occupant in occs
            if !(occupant in population)
                @info "occupant not in population"
                return false
            end
            for another in occs
                if another === occupant continue end
                if !related_first_degree(occupant,another) && !arepartners(occupant,another)
                    # family with a step father
                    if mother(another) in occs || mother(occupant) in occs
                        continue
                    end
                    @info "strangers living together"
                    @info occupant
                    @info another
                    return false
                end
            end
        end
    end

    for person in population
        if !ishomeless(person)
            if !(person in occupants(home(person)))
                return false
            end
            if !(home(person) in occupied_houses(hometown(person)))
                return false
            end
        end
    end
    return true
end
