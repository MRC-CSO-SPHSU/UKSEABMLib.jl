"""
Constants indicated paths and constants included within the UKSEABMLib[X]
Libraries. They are placed within a module to make them accessible internally
(via relative paths to modules)

Temporary simple solution till more standard ways are followed.

This file is included within the UKSEABMLib[X] libraries
"""
module Constants

const SESRCPATH = @__DIR__
const SEPATH    = SESRCPATH * "/.."
const SEVERSION = v"0.6"    # Renaming to UKSEABMLib.jl 
const XAGENTS_GENERIC_PATH = SESRCPATH * "/generic"
const XAGENTS_MA_PATH      = SESRCPATH * "/multiagents"

# ensuring consistent version of ABMSim.jl library
using ABMSim: ABMSIMVERSION
@assert ABMSIMVERSION == v"0.5"  # integration of agents.jl basic types

end # module Constants
