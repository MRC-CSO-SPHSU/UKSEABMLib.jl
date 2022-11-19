"""
This module is defining simulation models 

This module is within the MALPM module 
""" 

module Models 

using XAgents: Town, PersonHouse, Person, alive  
using MultiAgents: AbstractMABM, ABM

import LPM.ModelAPI: alivePeople, dataOf # Functions has to be listed explicitly ? 
import LPM.ParamTypes: populationParameters
import MultiAgents: allagents

export allagents, allPeople, alivePeople, dataOf, houses, towns # TODO is this needed?
export populationParameters

export MAModel 

mutable struct MAModel <: AbstractMABM 
    towns  :: ABM{Town} 
    houses :: ABM{PersonHouse}
    pop    :: ABM{Person}

    function MAModel(model,pars,data) 
        ukTowns  = ABM{Town}(model.towns,parameters = pars.mappars) 
        ukHouses = ABM{PersonHouse}(model.houses)
        parameters = (poppars = pars.poppars, birthpars = pars.birthpars, 
                        divorcepars = pars.divorcepars, workpars = pars.workpars)   
        ukPopulation = ABM{Person}(model.pop,parameters=pars,data=data)
        new(ukTowns,ukHouses,ukPopulation)
    end
end

allagents(model::MAModel) = allagents(model.pop)
allPeople(model::MAModel) = allagents(model.pop)
alivePeople(model::MAModel) = 
    [ person for person in allPeople(model)  if alive(person) ]
    # Iterators.filter(person->alive(person),people) # Iterators did not show significant value sofar
houses(model::MAModel) = allagents(model.houses)
towns(model::MAModel) = allagents(model.towns) 
dataOf(model) = model.pop.data

populationParameters(model::MAModel) = model.pop.parameters  

end # module Models 