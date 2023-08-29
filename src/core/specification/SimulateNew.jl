"""
Functions used for demography simulation
"""

# to replace the module Simulate
module SimulateNew

using ....API.Traits
import ....API.Traits: verbosemsg

# API for accessory functions
using ....API.ModelFunc  # Here it is does not make sense anymore to
                    #     employ explicit using statements
                    #     anything(model) comes from there
import ....API.ModelFunc: select_population, selectedfor
using ....API.ModelOp
import ....API.ModelOp: cache_computation

using ....Utilities
using ....XAgents
using ....ParamTypes

include("simulatenew/allocate.jl")
include("simulatenew/death.jl")
include("simulatenew/birth.jl")
include("simulatenew/divorce.jl")
include("simulatenew/ageTransition.jl")
include("simulatenew/workTransition.jl")
include("simulatenew/socialTransition.jl")
include("simulatenew/marriages.jl")
include("simulatenew/dependencies.jl")

end # module Simulate
