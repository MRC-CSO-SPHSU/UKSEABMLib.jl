using StatsBase

export adjacent_8_towns, adjacent_inhabited_towns
export select_random_town, create_newhouse!, create_newhouse_and_append!
export num_houses
export verify_no_homeless, verify_no_motherless_child

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
        if ischild(person) && mother(person) == nothing
            @show "motherless child : $(person)"
            return false
        end
    end
    return true
end
