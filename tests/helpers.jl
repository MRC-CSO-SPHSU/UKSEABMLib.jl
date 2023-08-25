using Test
using ABMSim: ABMSIMVERSION, init_abmsim, verify_agentsjl
using SocioEconomics: SEVERSION
using SocioEconomics.XAgents
using SocioEconomics.ParamTypes
using SocioEconomics.Specification.Declare

# model initialization
using SocioEconomics.API.Traits
using SocioEconomics.Specification.Initialize

using StatsBase: sample

import SocioEconomics.ParamTypes: load_parameters
import SocioEconomics.API.ModelFunc: all_people, alive_people

@assert ABMSIMVERSION == v"0.6"
init_abmsim()  # reset agents id counter

@assert SEVERSION == v"0.5"  # Unit testing

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
