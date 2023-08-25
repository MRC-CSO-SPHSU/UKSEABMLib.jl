"""
Constants indicated paths and constants included within the SocioEconomics[X]
Libraries. They are placed within a module to make them accessible internally
(via relative paths to modules)

Temporary simple solution till more standard ways are followed.

This file is included within the SocioEconomics[X] libraries
"""
module Constants

const SESRCPATH = @__DIR__
const SEPATH    = SESRCPATH * "/.."
const SEVERSION = v"0.5"    # performance tuning + ABMSIM.jl
const XAGENTS_GENERIC_PATH = SESRCPATH * "/generic"
const XAGENTS_MA_PATH      = SESRCPATH * "/multiagents"

# ensuring consistent version of ABMSim.jl library
using ABMSim: ABMSIMVERSION
@assert ABMSIMVERSION == v"0.6"  # integration of agents.jl basic types

end # module Constants
