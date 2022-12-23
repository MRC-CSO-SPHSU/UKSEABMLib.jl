
#= 
An initial design for findNewHouse*(*) interfaces (subject to incremental 
    modification, simplifcation and tuning)
=# 

export findEmptyHouseInTown, findEmptyHouseInOrdAdjacentTown, 
        findEmptyHouseAnywhere, movePeopleToEmptyHouse!, movePeopleToHouse!

# The type annotation is to hint validity for future extensions of agent types 
function _select_house(list)::PersonHouse
    if isempty(list)
        return UNDEFINED_HOUSE
    end
    rand(list)
end

findEmptyHouseInTown(town, allHouses) = _select_house(emptyHousesInTown(town, allHouses))

function findEmptyHouseInOrdAdjacentTown(town, allHouses, allTowns) 
    adjTowns = adjacent8Towns(town, allTowns)
    emptyHouses = [ house for town in adjTowns 
                          for house in emptyHousesInTown(town, allHouses) ]

    _select_house(emptyHouses)
end

# we might want to cache a list of empty houses at some point, but for now 
# this is fine
findEmptyHouseAnywhere(allHouses) = _select_house(emptyHouses(allHouses)) 

function movePeopleToHouse!(people, house)
    @assert house !== UNDEFINED_HOUSE
    # TODO 
    # - yearInTown (used in relocation cost)
    # - movedThisYear
    for person in people
        if person.pos != house
            moveToHouse!(person, house)
        end
    end
    nothing 
end

# TODO return only one type 
function movePersonToEmptyHouse!(person::Person, dmax, allHouses, allTowns=Town[]) 
    newhouse = UNDEFINED_HOUSE

    if dmax == :here
        newhouse = findEmptyHouseInTown(person.pos,allHouses)
    end
    if dmax == :near || newhouse == UNDEFINED_HOUSE
        newhouse = findEmptyHouseInOrdAdjacentTown(person.pos,allHouses,allTowns) 
    end
    if dmax == :far || newhouse == UNDEFINED_HOUSE
        newhouse = findEmptyHouseAnywhere(allHouses)
    end 

    if newhouse != UNDEFINED_HOUSE
        movePersonToHouse!(person, newhouse)
    end
    return UNDEFINED_HOUSE
end


# people[1] determines centre of search radius
function movePeopleToEmptyHouse!(people, dmax, allHouses, allTowns=Town[]) 
    newhouse = UNDEFINED_HOUSE

    if dmax == :here
        newhouse = findEmptyHouseInTown(getHomeTown(people[1]),allHouses)
    end
    if dmax == :near || newhouse == UNDEFINED_HOUSE
        newhouse = findEmptyHouseInOrdAdjacentTown(getHomeTown(people[1]),allHouses,allTowns) 
    end
    if dmax == :far || newhouse == UNDEFINED_HOUSE
        newhouse = findEmptyHouseAnywhere(allHouses)
    end 

    if newhouse != UNDEFINED_HOUSE
        movePeopleToHouse!(people, newhouse)
    end
    return newhouse
end
