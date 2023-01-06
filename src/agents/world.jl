using StatsBase 
using Memoization

export adjacent_8_towns, adjacent_inhabited_towns 
export select_random_town, create_newhouse!, create_newhouse_and_append!
export number_of_houses

# effectivness of memoization is not clear 
@memoize adjacent_inhabited_towns(town, towns) = [ t for t in towns if isAdjacent8(town, t) && t.density > 0 ] 

# memoization does not help 
function _weights(towns) 
    w = Vector{Float64}(undef,length(towns))
    for (i,town) in enumerate(towns)
        w[i] = town.density
    end 
    return w
end 

function select_random_town(towns) 
    ws = _weights(towns)
    return sample(towns, Weights(ws))
end 

function create_newhouse!(town,xdim,ydim)
    house = PersonHouse(town,(xdim,ydim))
    add_emptyhouse!(town,house)
    return house 
end 

function create_newhouse_and_append!(town, allHouses, xdim, ydim)
    house = create_newhouse!(town,xdim,ydim)
    push!(allHouses,house)
    nothing 
end

function number_of_houses(towns)
    nempty = 0 
    noccupied = 0 
    for town in towns  # can be expressed better 
        nempty += length(emptyhouses(town))
        noccupied += length(occupiedhouses(town))
    end
   return (nempty, noccupied)
end

