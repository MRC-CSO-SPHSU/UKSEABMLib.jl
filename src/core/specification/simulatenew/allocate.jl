"""
Set of routines related to people allocatiom to empty potentially new
"""

export get_or_create_empty_house!, move_to_empty_house!

function _get_random_empty_house(town)
    @assert has_empty_houses(town)
    rand(empty_houses(town))
end

#@memoize # does not really make that big difference
_town_dimension(model) = 1:map_pars(model).townGridDimension
function _create_empty_house!(town, model)
    dims = _town_dimension(model)
    xdim = rand(dims)
    ydim = rand(dims)
    newhouse = create_newhouse!(town,xdim, ydim)
    add_house!(model, newhouse)
    return newhouse
end

function _get_or_create_empty_house!(town::PersonTown, model)
    if has_empty_houses(town)
        return _get_random_empty_house(town)
    else
        return _create_empty_house!(town, model)
    end
end

get_or_create_empty_house!(town, model, ::InTown) =
    _get_or_create_empty_house!(town, model)

function _get_or_create_empty_house!(towns, model)
    town = select_random_town(towns)
    _get_or_create_empty_house!(town, model)
end

get_or_create_empty_house!(town, model, ::AdjTown) =
    _get_or_create_empty_house!(adjacent_inhabited_towns(town), model)

get_or_create_empty_house!(::PersonTown, model, loc::AnyWhere) =
    get_or_create_empty_house!(model,loc)

get_or_create_empty_house!(model,::AnyWhere) =
    _get_or_create_empty_house!(towns(model), model)

function move_to_empty_house!(person, house)
    @assert isempty(house)
    move_to_house!(person, house)
end

function move_to_empty_house!(person::Person,
                                    model,
                                    dmax)
    # TODO
    # - yearInTown (used in relocation cost)
    # - movedThisYear
    newhouse = get_or_create_empty_house!(hometown(person), model, dmax)
    move_to_empty_house!(person, newhouse)
    nothing
end

move_to_person_house!(personToMove,personWithAHouse) =
    move_to_house!(personToMove, home(personWithAHouse))

move_to_person_house!(peopleToMove::Vector{Person},personWithAHouse) =
    move_to_house!(peopleToMove,home(personWithAHouse))

# people[1] determines centre of search radius
function move_to_empty_house!(people::Vector{Person}, model,dmax)
    move_to_empty_house!(people[1],model,dmax)
    others = @view people[2:end]
    move_to_person_house!(others,people[1])
    nothing
end

# some Agents.jl stuffs

function random_position(model)
    town = select_random_town(towns(model))
    return _get_or_create_empty_house(town,model)
end

#=
Shallow implementation of some Agents.jl functions.
They shall be implemented if needed particulary by some Agents.jl functionalities
    or beneficial future extensions
=#

nearby_ids(::PersonHouse, model, r=1) =
    error("nearby_ids(::PersonHouse,$(typeof(model)),r=1) not implemented")
nearby_ids(::PersonTown, model, r=1) =
    error("nearby_ids(::PersonTown,$(typeof(model)),r=1) not implemented")

add_agent_to_space!(::PersonHouse, model) =
    error("add_agent_to_space!(::PersonHouse,$(typeof(model))) not implemented")
remove_agent_from_space!(::PersonHouse, model) =
    error("remove_agent_from_space!(::PersonHouse,$(typeof(model))) not implemented")
