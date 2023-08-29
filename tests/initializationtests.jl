include("./libpaths.jl")
include("./helpers.jl")

@testset verbose=true "Model creation" begin

    model = declare_demographic_model(1000)
    person1 = rand(model.pop[1:100])
    person2 = rand(model.pop[101:200])

    # basic model declaration
    @testset verbose=true "Declaration" begin

        @test length(model.pop) == model.parameters.poppars.initialPop
        @test length(alive_people(model)) == length(model.pop)
        @test ishomeless(person1)
        @test typeof(age(person1)) == Rational{Int}
        @test isnoperson(father(person1))
        @test isnoperson(partner(person2))
        @test verify_consistency(model.towns)
        @test sum(num_houses(model.towns)) == 0

    end

    initialize_demographic_model!(model)
    @testset verbose=true "Initialization" begin
        @test verify_children_parents_consistency(model.pop)
        @test verify_partnership_consistency(model.pop)
        @test verify_no_homeless(model.pop)
        @test verify_child_is_with_a_parent(model.pop)
        @test verify_singles_live_alone(model.pop)
        @test verify_family_lives_together(model.pop)
        @test verify_houses_consistency(model.pop,model.houses)
    end

end # Model creation
