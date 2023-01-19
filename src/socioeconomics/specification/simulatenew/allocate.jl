#= 
Implemenation of get_or_create_emptyhouse! & move_person_to_empty_house 
=# 

export get_or_create_emptyhouse!, move_person_to_emptyhouse!

function _get_random_emptyhouse(town) 
    @assert has_emptyhouses(town)
    rand(emptyhouses(town))
end

#@memoize # does not really make that big difference  
_town_dimension(model) = 1:mapParameters(model).townGridDimension
function _create_emptyhouse!(town, model) 
    dims = _town_dimension(model)
    xdim = rand(dims) 
    ydim = rand(dims) 
    newhouse = create_newhouse!(town,xdim, ydim)
    add_house!(model, newhouse) 
    return newhouse 
end 

function _get_or_create_emptyhouse!(town::PersonTown, model) 
    if has_emptyhouses(town)
        return _get_random_emptyhouse(town)
    else
        return _create_emptyhouse!(town, model)
    end
end

get_or_create_emptyhouse!(town, model, ::InTown) = 
    _get_or_create_emptyhouse!(town, model)
    
function _get_or_create_emptyhouse!(towns, model) 
    town = select_random_town(towns)
    _get_or_create_emptyhouse!(town, model)
end

get_or_create_emptyhouse!(town, model, ::AdjTown) = 
    _get_or_create_emptyhouse!(adjacent_inhabited_towns(town, towns(model)), model) 

get_or_create_emptyhouse!(::PersonTown, model, loc::AnyWhere) = 
    get_or_create_emptyhouse!(model,loc)

get_or_create_emptyhouse!(model,::AnyWhere) = 
    _get_or_create_emptyhouse!(towns(model), model) 

function move_person_to_emptyhouse!(person, house) 
    @assert isEmpty(house)
    moveToHouse!(person, house) 
end
 
function move_person_to_emptyhouse!(person::Person, 
                                    model,
                                    dmax) 
    # TODO 
    # - yearInTown (used in relocation cost)
    # - movedThisYear
    newhouse = get_or_create_emptyhouse!(hometown(person), model, dmax)
    move_person_to_emptyhouse!(person, newhouse)
    nothing
end

move_person_to_person_house!(personToMove,personWithAHouse) =
    moveToHouse!(personToMove, home(personWithAHouse))

function move_people_to_house!(people, house)
    @assert house !== UNDEFINED_HOUSE
    for person in people
        moveToHouse!(person, house)
    end
    nothing 
end

move_people_to_person_house!(peopleToMove,personWithAHouse) = 
    move_people_to_house!(peopleToMove,home(personWithAHouse))

# people[1] determines centre of search radius
function move_people_to_emptyhouse!(people, model,dmax) 
    head = people[1]    
    move_person_to_emptyhouse!(head,model,dmax)
    others = people[2:end] 
    move_people_to_person_house!(others,head)
    nothing 
end
