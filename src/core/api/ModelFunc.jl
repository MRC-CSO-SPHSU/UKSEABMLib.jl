"""
    This module describes basic model interfaces to
    be employed within simulation functions in any
    *Simulate module

    This module is within the SocioEconomics[X] modules
"""
module ModelFunc

using ..Traits
using ....XAgents
import ....XAgents: random_position
using ....Utilities

export init!
export all_people, alive_people, data_of, houses, towns
export select_population, selectedfor
export add_person!, add_house!, remove_person!
export verbose_houses
export share_childless_men, eligible_women

init!(model) = error("init!($(typeof(model))) not implemented")

all_people(model) = error("all_people not implemeneted")
alive_people(model)  = error("alive_people not implemented")
data_of(model) = error("data_of not implemeneted")
houses(model) = error("houses not implemented")
towns(model)  = error("towns not implemented")

alive_people(model,::FullPopulation) =
    [ person for person in all_people(model)  if alive(person) ]
alive_people(model,::AlivePopulation) = all_people(model)

"select subpopulation to be examined for a particular simulation process"
select_population(model,
                    pars,
                    popfeature::PopulationFeature,
                    process::SimProcess)::Vector{Person} = all_people(model) # Default

"examine if a person is selected to be applicable to a given simulation process"
selectedfor(person, pars, popfeature::PopulationFeature, process::SimProcess)::Bool =
    error("selectedfor(person, pars, ::$(typeof(popfeatue)),  $(typeof(process)) not implemented")

add_person!(model,person) = error("add_person! not implemented")
add_house!(model,person)  = error("add_house! not implemented")
remove_person!(model,personidx::Int) = error("remove_person! not implemented")
remove_person!(model,personidx::Int,::FullPopulation) = nothing # don't remove
remove_person!(model,personidx::Int,::PopulationFeature) = remove_person!(model,personidx)

function verbose_houses(model,msg="")
    delayedVerbose() do
        ts = towns(model)
        ehouses,ohouses = number_of_houses(ts)
        println("$(msg) # empty houses : $ehouses , # occupied houses : $ohouses")
    end
end

# help functions that can be implemented to access model variables for
#   storing intermediate expensive computations

share_childless_men(model,ageclass::Int) =
    error("share_childless_men(::$(typeof(model)),ageclass::Int) not implemented")

eligible_women(model) =
    error("eligible_women(::$(typeof(model))) not implemented")

end # ModelFunc