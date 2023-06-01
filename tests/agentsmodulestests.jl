include("./libpaths.jl")
include("./helpers.jl")

@testset verbose=true "Person modules tests" begin

    model = declare_demographic_model(1000)
    initialize_demographic_model!(model)
    randperson1,randperson2 = get_random_persons(model,2)

    @testset verbose=true "BasicInfo Module" begin
        set_dead!(randperson1)
        @test !alive(randperson1)
        a2 = age(randperson2)
        agestep!(randperson2)
        @test age(randperson2) > a2
    end

    #=
    @testset verbose=true "Kinship Module" begin

        set_as_parent_child!(person1,person6)
        @test person1 in person6.kinship.children
        @test father(person1) === person6

        set_as_parent_child!(person2,person4)
        @test mother(person2) === person4
        @test person2 in person4.kinship.children

        @test issingle(person1)
        set_as_partners!(person1,person4)
        @test !issingle(person4)
        @test partner(person1) === person4 && partner(person4) === person1

        @test_throws InvalidStateException set_as_partners!(person3,person4) # same gender

        @test_throws InvalidStateException set_as_parent_child!(person4,person5)  # unknown gender
        @test_throws ArgumentError set_as_parent_child!(person4,person1)          # ages incompatibe / well they are also partners
        @test_throws ArgumentError set_as_parent_child!(person2,person3)          # person 2 has a mother

        resolve_partnership!(person4,person1)
        @test issingle(person4)
        @test partner(person1) !== person4 && partner(person4) != person1
        @test_throws ArgumentError resolve_partnership!(person1,person4)

    end

    @testset verbose=true "Type Person" begin
        @test getHomeTown(person1) != nothing
        @test getHomeTownName(person1) == "Edinbrugh"

        set_as_partners!(person4,person6)
        @test !issingle(person6)
        @test !issingle(person4)

        person7 = Person(pos=person4.pos,gender=male,mother=person4,father=person6)
        @test father(person7) === person6
        @test mother(person7) === person4
        @test person7 ∈ children(person4)
        @test person7 ∈ children(person6)

        reset_partner!(person4)
        @test issingle(person6)
        @test issingle(person4)
    end
    =#

end # Person modules tests
