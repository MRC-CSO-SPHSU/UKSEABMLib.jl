"""
    Main simulation functions for the demographic aspect of LPM. 
""" 


module Simulate

using XAgents: Person  
using XAgents: alive, age

using MultiAgents: ABM, allagents

using MALPM.Create: LPMUKDemographyOpt

using LPM
import LPM.Demography.Simulate: doDeaths!
export doDeaths!


function doDeaths!(population::ABM{Person};
                   verbose = true, 
                   sleeptime=0) 

    pars = population.properties 
    data = population.data

    people = allagents(population)

    livingPeople = typeof(pars[:example]) == LPMUKDemographyOpt ? 
        people : [person for person in people if alive(person)]

    @assert length(livingPeople) > 0 ? 
        typeof(age(livingPeople[1])) == Rational{Int64} :
        true  # Assumption

    (numberDeaths) = LPM.Demography.Simulate.doDeaths!(people=livingPeople,parameters=pars,data=data,verbose=verbose,sleeptime=sleeptime) 

    false ? population.variables[:numberDeaths] += numberDeaths : nothing # Temporarily this way till realized 

end # function doDeaths!

end # Simulate 