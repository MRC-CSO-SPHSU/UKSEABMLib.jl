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
const ABMSIM_PATH      = SESRCPATH * "/abmsim"

# ensuring consistent version of ABMSim.jl library
using ABMSim: ABMSIMVERSION
@assert ABMSIMVERSION == v"0.7.1"  # Space concept

end # module Constants
