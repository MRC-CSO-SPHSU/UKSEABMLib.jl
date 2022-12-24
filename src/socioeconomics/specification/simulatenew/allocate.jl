
#= 
An initial design for findNewHouse*(*) interfaces (subject to incremental 
    modification, simplifcation and tuning)
=# 

export get_or_create_emptyhouse!, move_person_to_emptyhouse!

# The type annotation is to ensure validity for future extensions of agent types 
_get_random_emptyhouse(town::PersonTown) = rand(emptyhouses(town))

function get_or_create_emptyhouse!(town::PersonTown, allTowns, allHouses, mappars, ::InTown) 
    if has_emptyhouses(town)
        return _get_random_emptyhouse(town)
    else
        xdim = mappars.townGridDimension # todo Correction rand(1:mappars.townGridDimension)
        ydim = 0 
        newhouse = establish_newhouse(town,xdim, ydim)
        push!(allHouses, newhouse) 
        return newhouse 
    end
end

function _get_or_create_emptyhouse!(towns, allTowns, allHouses, mappars) 
    town = select_random_town(towns)
    return get_or_create_emptyhouse!(town, allTowns, allHouses, mappars, InTown())
end

get_or_create_emptyhouse!(town, allTowns, allHouses, mappars, ::AdjTown) = 
    _get_or_create_emptyhouse!(adjacent_8_towns(town), allTowns, allHouses, mappars) 

get_or_create_emptyhouse(::PersonTown, allTowns, allHouses, mappars, ::AnyWhere) = 
    _get_or_create_emptyhouse!(allTowns, allTowns, allHouses, mappars) 

function move_person_to_emptyhouse(person, house) 
    moveToHouse!(person, house) 
    #make_emptyhouse_occupied!(newhouse)
    nothing 
end 

function move_person_to_emptyhouse!(person::Person, 
                                    allTowns,
                                    allHouses, 
                                    mappars,
                                    dmax) 
    # TODO 
    # - yearInTown (used in relocation cost)
    # - movedThisYear
    newhouse = get_or_create_emptyhouse(getHomeTown(person), allTowns, allHouses, mappars, dmax)
    move_person_to_emptyhouse!(person, newhouse)
    return newhouse 
end

function move_person_to_person_house!(personToMove,personWithAHouse) end 

function move_people_to_house!(people, house)
    for person in people
        moveToHouse!(person, house)
    end
    nothing 
end

move_people_to_person_house!(peopleToMove,personWithAHouse) = 
    move_people_to_house!(peopleToMove,home(personWithAHouse))

# people[1] determines centre of search radius
function move_people_to_emptyhouse!(people,allTowns,allHouses,mappars,dmax) 
    head = people[1]    
    newhouse = move_person_to_emptyhouse!(head,allTowns,allHouses,mappars,dmax)
    others = people[2:end] 
    move_people_to_person_house!(others,head)
    return newhouse
end
