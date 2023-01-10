""" 
    This module describes basic model interfaces to
    be employed within simulation functions in any 
    *Simulate module
    
    This module is within the SocioEconomics[X] modules 
"""
module ModelFunc

using ..Traits
using ....XAgents
using ....Utilities

export allPeople, alivePeople, dataOf, houses, towns 
export select_population, selectedfor
export add_person!, add_house!, remove_person! 
export verbose_houses
export share_childless_men, eligible_women

allPeople(model) = error("allPeople not implemeneted") 
alivePeople(model)  = error("alivePeople not implemented") 
dataOf(model) = error("dataOf not implemeneted") 
houses(model) = error("houses not implemented")
towns(model)  = error("towns not implemented")

alivePeople(model,::FullPopulation) = 
    [ person for person in allPeople(model)  if alive(person) ]
alivePeople(model,::AlivePopulation) = allPeople(model)

"select subpopulation to be examined for a particular simulation process"
select_population(model, pars, popfeature::PopulationFeature, process::SimProcess)::Vector{Person} = 
    allPeople(model) # Default 

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