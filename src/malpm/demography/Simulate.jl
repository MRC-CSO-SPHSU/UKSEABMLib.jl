"""
    Main simulation functions for the demographic aspect of LPM. 
""" 

module Simulate

using XAgents: Person, isFemale, alive, age

using MultiAgents: ABM, AbstractMABM, AbstractABMSimulation
using MultiAgents: allagents, add_agent!, currstep, verbose 
using MALPM.Demography.Population: removeDead!
using MALPM.Demography: DemographyExample, LPMUKDemography, LPMUKDemographyOpt
using MALPM.Models # no need for explicit listing anything(model) is from there
import MALPM.Demography: allPeople  
using LPM
import LPM.Demography.SimulateNew: doDeaths!#, doBirths!, doDivorces!
# export doDeaths!,doBirths!

alivePeople(model,::LPMUKDemography) = allPeople(model)
alivePeople(model,::LPMUKDemographyOpt) = alivePeople(model)
       

function removeDeads!(deadpeople,pop,::LPMUKDemography)    
    for deadperson in deadpeople
        removeDead!(deadperson,pop)
    end
    
    nothing 
end

removeDeads!(deadpeople,pop,::LPMUKDemographyOpt) = nothing 

function doDeaths!(model::AbstractMABM, sim::AbstractABMSimulation, example::DemographyExample) # argument simulation or simulation properties ? 

    (deadpeople) = doDeaths!(
            model,
            currstep(sim))
    
    # ToDo separate step? 
    removeDeads!(deadpeople,model.pop,example)
    nothing 
end # function doDeaths!

#=
function doBirths!(model::AbstractMABM, sim::AbstractABMSimulation, example::DemographyExample) 

    population = model.pop 

    newbabies = LPM.Demography.Simulate.doBirths!(
                        alivePeople(population,example),
                        currstep(sim),
                        population.data,
                        population.parameters.birthpars) 

    # false ? population.variables[:numBirths] += length(newbabies) : nothing # Temporarily this way till realized 
    
    for baby in newbabies
        add_agent!(population,baby)
    end

    nothing 
end


function doDivorces!(model::AbstractMABM, sim::AbstractABMSimulation, example::DemographyExample) 

    population = model.pop 

    LPM.Demography.Simulate.doDivorces!(
                        #allagents(population),
                        alivePeople(population,example),
                        currstep(sim),
                        houses(model),
                        towns(model),
                        population.parameters.divorcepars) 

    nothing 
end


=# 

end # Simulate 