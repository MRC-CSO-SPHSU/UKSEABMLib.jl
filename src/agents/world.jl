using StatsBase

export adjacent_8_towns, adjacent_inhabited_towns
export select_random_town, create_newhouse!, create_newhouse_and_append!
export num_houses
export verify_no_homeless, verify_no_motherless_child, verify_child_is_with_a_parent,
    verify_children_parents_consistency, verify_partnership_consistency,
    verify_singles_live_alone

# memoization does not help
_weights(towns) = [ town.density for town in towns ]

function select_random_town(towns)
    ws = _weights(towns)
    return sample(towns, Weights(ws))
end

function create_newhouse!(town,xdim,ydim)
    house = PersonHouse(town,(xdim,ydim))
    add_empty_house!(town,house)
    return house
end

function create_newhouse_and_append!(town, allHouses, xdim, ydim)
    house = create_newhouse!(town,xdim,ydim)
    push!(allHouses,house)
    nothing
end

function num_houses(towns)
    nempty = 0
    noccupied = 0
    for town in towns  # can be expressed better
        nempty += length(empty_houses(town))
        noccupied += length(occupied_houses(town))
    end
   return (nempty, noccupied)
end

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
    parents = [parent for parent in population if has_children(parent)]
    for parent in parents
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
