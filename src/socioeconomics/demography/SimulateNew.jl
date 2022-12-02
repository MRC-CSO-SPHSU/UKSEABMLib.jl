"""
Functions used for demography simulation 
"""

# to replace the module Simulate
module SimulateNew 

# API for accessory functions 
using ....ModelAPI  # Here it is does not make sense anymore to 
                    #     employ explicit using statements 
                    #     anything(model) comes from there 

using ....Utilities

#include("simulate/allocate.jl")

include("simulatenew/death.jl")

#include("simulate/birth.jl")  
#include("simulatenew/divorce.jl")       
#include("simulatenew/ageTransition.jl")
#include("simulatenew/socialTransition.jl")
#include("simulatenew/marriages.jl")
#include("simulatenew/dependencies.jl")

end # module Simulate 
