"""
This file is included within the Module ParamTypes
"""

using Random
using ..Utilities
import Random.seed!
export SimulationPars, seed!, reseed0!, debug_setup
export DataPars


"General simulation parameters"
@with_kw mutable struct SimulationPars
    starttime :: Rational{Int}  = 1920
    finishtime :: Rational{Int} = 2040
    dt :: Rational{Int} = 1//12      # step size
    seed :: Int       = 42 ;   @assert seed >= 0 # 0 is random
    verbose::Bool     = false       # whether significant intermediate info shallo be printed
    sleeptime :: Float64  = 0; @assert sleeptime >= 0
                                   # how long simulation is suspended after printing info
    checkassumption :: Bool = false # whether assumptions in unit functions should be checked
	#caching :: Bool = false # wehter pre-computation is saved 
    logfile :: String = "log.tsv"
end

reseed0!(simPars) =
    simPars.seed = simPars.seed == 0 ?  floor(Int, time()) : simPars.seed

function seed!(simPars::SimulationPars,
                randomizeSeedZero=true)
    if randomizeSeedZero
        reseed0!(simPars)
    end
    Random.seed!(simPars.seed)
end

function debug_setup(simpars)
    simpars.verbose ? setVerbose!() : unsetVerbose!()
    setDelay!(simpars.sleeptime)
    simpars.checkassumption ? checkAssumptions!() : ignoreAssumptions!()
    nothing
end
