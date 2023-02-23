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
const SEVERSION = v"0.3.3"    # (Shallow) integration of Agents.jl space concept
const XAGENTS_GENERIC_PATH = SESRCPATH * "/generic"
const XAGENTS_MA_PATH      = SESRCPATH * "/multiagents"

# ensuring consistent version of MultiAgents.jl library
using MultiAgents: MAVERSION
@assert MAVERSION == v"0.4.1"  # integration of agents.jl basic types

end # module Constants
