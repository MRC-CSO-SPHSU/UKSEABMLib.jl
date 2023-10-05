"""
UKSEABMLib Library is dependent on ABMSim.jl

Note: MultiAgents.jl was renamed to ABMSim.jl begining from ABMSim Version 0.6
    if MultiAgents.jl is desired (for executing older version), it is obtainable
    from https://github.com/AtiyahElsheikh/MultiAgents.jl
"""

module UKSEABMLib

include("Constants.jl")
using .Constants: SESRCPATH, SEPATH, SEVERSION 

include("./core/Utilities.jl")

include("abmsim/XAgents.jl")

include("semodules.jl")

end  # module UKSEABMLib
