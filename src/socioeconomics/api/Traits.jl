module Traits 

export PopulationFeature, FullPopulation, AlivePopulation

abstract type PopulationFeature end
struct FullPopulation <: PopulationFeature end 
struct AlivePopulation <: PopulationFeature end 

end 