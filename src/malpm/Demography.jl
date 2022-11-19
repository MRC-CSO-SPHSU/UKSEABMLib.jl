module Demography

using XAgents: Town, PersonHouse, Person, alive  
using MultiAgents: AbstractMABM, ABM
# using LPM.Demography.Create: createTowns

export MAModel 
 
import MultiAgents.Util: AbstractExample
import MultiAgents: allagents

import LPM.ModelAPI: alivePeople, dataOf 
import LPM.ParamTypes: populationParameters

export allagents, allPeople, alivePeople, dataOf, houses, towns # TODO is this needed?
export populationParameters
export DemographyExample, LPMUKDemography, LPMUKDemographyOpt

### Example Names 
"Super type for all demographic models"
abstract type DemographyExample <: AbstractExample end 

"This corresponds to direct translation of the python model"
struct LPMUKDemography <: DemographyExample end 

"This is an attemp for improved algorthimic translation"
struct LPMUKDemographyOpt <: DemographyExample end 
 

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

include("./demography/Population.jl") 
include("./demography/Simulate.jl")
include("./demography/SimSetup.jl")  


end # Demography