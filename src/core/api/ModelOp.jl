"""
This module is concerned with functions operating on models. There are usable within model
specification modules and client.

The functions here are generic and are supposed to work whatever the model type is.
    If the implementation is not generic enough, the client can still re-implement it
    for very specific models.

This module is within API module
"""

module ModelOp

using ..ModelFunc
using ....XAgents
using ..Traits

import ....XAgents: create_newhouse!, add_town!
export create_many_newhouses!, cache_computation

#TODO  examine if delegation to space or towns can be achieved

function create_newhouse!(model)
    town = select_random_town(towns(model))
    townGridDimension = map_pars(model).townGridDimension
    house = create_newhouse!(town,  rand(1:townGridDimension),
                                    rand(1:townGridDimension))
    return house
end

function create_many_newhouses!(model,nhouses)
    cnt = 0
    while cnt < nhouses
        create_newhouse!(model)
        cnt += 1
    end
    return nothing
end

function add_town!(model,town)
    push!(model.space.towns,town) # TODO fix space(model)
end

cache_computation(model,process::SimProcess) = nothing

end # Models Operation
