module SocioEconomics

    const SESRCPATH = @__DIR__ 
    const SEPATH    = SESRCPATH * "/.." 
    const SEVERSION = v"0.1.0"

    include("./socioeconomics/ParamTypes.jl")
    include("./socioeconomics/ModelAPI.jl")
    include("./socioeconomics/Demography.jl")

end  # module SocioEconomics 