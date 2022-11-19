module LPM
    export LPMVERSION

    const LPMVERSION = r"0.6.2"

    include("./lpm/ParamTypes.jl")
    include("./lpm/ModelAPI.jl")
    include("./lpm/Demography.jl")

end # LoneParentsModel
