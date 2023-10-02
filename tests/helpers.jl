using Test
using ABMSim: ABMSIMVERSION, init_abmsim, verify_agentsjl
using UKSEABMLib: SEVERSION
using UKSEABMLib.XAgents
using UKSEABMLib.ParamTypes
using UKSEABMLib.Specification.Declare

# model initialization
using UKSEABMLib.API.Traits
using UKSEABMLib.Specification.Initialize

using StatsBase: sample

import UKSEABMLib.ParamTypes: load_parameters
import UKSEABMLib.API.ModelFunc: all_people, alive_people

@assert ABMSIMVERSION == v"0.7.1"
init_abmsim()  # reset agents id counter

@assert SEVERSION == v"0.6.1"  # Unit testing + ABMSim.jl

function load_parameters()
    simPars = SimulationPars()
    ParamTypes.seed!(simPars)
    dataPars = DataPars()
    pars = DemographyPars()
    simPars, dataPars, pars
end

# flat model structure
mutable struct DemographyModel
    const towns :: Vector{PersonTown}
    const houses :: Vector{PersonHouse}
    const pop :: Vector{Person}
    const parameters :: DemographyPars
    const data :: DemographyData
    time :: Rational{Int}
end

all_people(model::DemographyModel) = model.pop
alive_people(model::DemographyModel) = [ person for person in model.pop if alive(person) ]

function declare_demographic_model(ips = 1000)
    init_abmsim()  # reset agents id counter

    simPars, dataPars, pars = load_parameters()
    pars.poppars.initialPop = ips

    data = load_demography_data(dataPars)

    towns =  Vector{PersonTown}(declare_inhabited_towns(pars))
    houses = Vector{PersonHouse}()
    pop = declare_pyramid_population(pars)
    model = DemographyModel(towns, houses, pop, pars, data, simPars.starttime)

    return model
end

applycaching(::SimProcess) = false
applycaching(::Birth) = true
initialize_demographic_model!(model) = Initialize.init!(model;verify=false,applycaching)

get_random_persons(model,n) = sample(model.pop,n;replace=false)
