
#= 
An initial design for findNewHouse*(*) interfaces (subject to incremental 
    modification, simplifcation and tuning)
=# 

export findEmptyHouseInTown, findEmptyHouseInOrdAdjacentTown, 
        findEmptyHouseAnywhere, movePeopleToEmptyHouse!, movePeopleToHouse!

const undefinedHouse = PersonHouse(undefinedTown,(-1,-1))

# The type annotation is to hint validity for future extensions of agent types 
function _select_house(list)::PersonHouse
    if isempty(list)
        return undefinedHouse
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
    @assert house !== undefinedHouse
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
    newhouse = undefinedHouse

    if dmax == :here
        newhouse = findEmptyHouseInTown(person.pos,allHouses)
    end
    if dmax == :near || newhouse == undefinedHouse
        newhouse = findEmptyHouseInOrdAdjacentTown(person.pos,allHouses,allTowns) 
    end
    if dmax == :far || newhouse == undefinedHouse
        newhouse = findEmptyHouseAnywhere(allHouses)
    end 

    if newhouse != undefinedHouse
        movePersonToHouse!(person, newhouse)
    end
    return undefinedHouse
end


# people[1] determines centre of search radius
function movePeopleToEmptyHouse!(people, dmax, allHouses, allTowns=Town[]) 
    newhouse = undefinedHouse

    if dmax == :here
        newhouse = findEmptyHouseInTown(people[1].pos,allHouses)
    end
    if dmax == :near || newhouse == undefinedHouse
        newhouse = findEmptyHouseInOrdAdjacentTown(people[1].pos,allHouses,allTowns) 
    end
    if dmax == :far || newhouse == undefinedHouse
        newhouse = findEmptyHouseAnywhere(allHouses)
    end 

    if newhouse != undefinedHouse
        movePeopleToHouse!(people, newhouse)
    end
    return newhouse
end
