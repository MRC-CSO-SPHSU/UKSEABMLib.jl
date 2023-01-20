using CSV
using Tables

using ....Constants: SEPATH

export load_demography_data, DemographyData, DataPars 

"Data files"
@with_kw mutable struct DataPars
    datadir     :: String = SEPATH * "/data"
    fertFName   :: String = "babyrate.txt.csv"
    deathFFName :: String = "deathrate.fem.csv"
    deathMFName :: String = "deathrate.male.csv"
end

struct DemographyData
    fertility   :: Matrix{Float64}
    deathFemale :: Matrix{Float64}
    deathMale   :: Matrix{Float64}  
end

function load_demography_data(fertFName, deathFFName, deathMFName) 
    fert = CSV.File(fertFName, header=0) |> Tables.matrix
    deathFemale = CSV.File(deathFFName, header=0) |> Tables.matrix
    deathMale = CSV.File(deathMFName, header=0) |> Tables.matrix
    return DemographyData(fert,deathFemale,deathMale)
end

"""
load demography data from the data directory
    datapars :: DataPars 
    sepath :: Path of Socio Economic Library 
"""
function load_demography_data(datapars)
    dir = datapars.datadir 
    ukDemoData = load_demography_data(dir * "/" * datapars.fertFName, 
                                      dir * "/" * datapars.deathFFName,
                                      dir * "/" * datapars.deathMFName)
end
