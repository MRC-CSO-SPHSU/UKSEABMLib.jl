"""
Run this script from shell as
# julia tests/runtests.jl

or within REPL

julia> include("tests/runtests.jl")
"""

using Test

@testset "Lone Parent Model Components Testing" begin

    include("./basictests.jl")
    include("./initializationtests.jl")
    include("./agentsmodulestests.jl")

    @testset verbose=true "Lone Parent Model Simulation" begin

        #=
        To re-implement

        using  SocialSimulations: SocialSimulation


        simProperties = LoneParentsModel.loadSimulationParameters()
        lpmSimulation = SocialSimulation(LoneParentsModel.createPopulation,simProperties)

        @test LoneParentsModel.loadMetaParameters!(lpmSimulation) != nothing  skip=true
        @test LoneParentsModel.loadModelParameters!(lpmSimulation) != nothing skip=false
        @test LoneParentsModel.createShifts!(lpmSimulation) != nothing        skip=false
        =#

    end


end  # Lone Parent Model main components

nothing
