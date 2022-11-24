module Demography
 
import MultiAgents.Util: AbstractExample

export DemographyExample, LPMUKDemography, LPMUKDemographyOpt

### Example Names 
"Super type for all demographic models"
abstract type DemographyExample <: AbstractExample end 

"This corresponds to direct translation of the python model"
struct LPMUKDemography <: DemographyExample end 

"This is an attemp for improved algorthimic translation"
struct LPMUKDemographyOpt <: DemographyExample end 


include("./demography/Population.jl") 
include("./demography/Simulate.jl")
include("./demography/SimSetup.jl")  


end # Demography