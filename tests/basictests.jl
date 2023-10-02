include("./libpaths.jl")
include("./helpers.jl")

@testset verbose=true "Basic components" begin
    # List of towns
    glasgow   = PersonTown((10,10),density=0.8)
    edinburgh = PersonTown((10,11),density=1.0)
    sterling  = PersonTown((11,10),density=0.2)
    aberdeen  = PersonTown((20,12),density=0.5)
    Scotland  = [glasgow, edinburgh, sterling, aberdeen]
    unknownTown = PersonTown(UNDEFINED_2DLOCATION)

    towns = [aberdeen, glasgow, edinburgh, sterling]
    _NH = 100
    for _ in 1:_NH
        town = select_random_town(towns)
        create_newhouse!(town,rand(1:10),rand(1:10))
    end

    init_adjacent_ihabited_towns!(towns)

    @testset verbose=true "Town" begin
        @test undefined(unknownTown)
        @test !undefined(glasgow)
        @test isadjacent8(edinburgh,sterling)
        @test !isadjacent8(sterling,aberdeen)
        @test has_empty_houses(aberdeen)
        @test manhattan_distance(sterling,aberdeen) == 11
        @test isempty(aberdeen.adjacentInhabitedTowns)
        @test sterling in glasgow.adjacentInhabitedTowns
    end

    id = 1 
    people = Person[]
    for town in towns
        for ehouse in empty_houses(town)
            if rand() > 0.5
                person = Person(id,ehouse,rand(1:40),gender=rand((female,male)))
                id += 1
                push!(people,person)
            end
        end
    end

    randperson = rand(people)
    randhouse = home(randperson)

    @testset verbose=true "House" begin

        @test location(randhouse) != UNDEFINED_2DLOCATION
        @test hometown(randhouse) in Scotland
        @test hometown(randhouse) === hometown(randperson)
        @test randperson in occupants(randhouse)

        @test verify_consistency(randhouse)
        @test !isempty(randhouse)
        @test num_occupants(randhouse) == 1
        @test verify_consistency(hometown(randhouse))

        remove_occupant!(randhouse,randperson)
        @test verify_consistency(randhouse)
        @test verify_consistency(hometown(randhouse))
        @test isempty(randhouse)
        @test !(home(randperson) == randhouse)
        @test undefined(home(randperson))

        add_occupant!(randhouse,randperson)
        @test verify_consistency(randhouse)
        @test verify_consistency(hometown(randhouse))
        @test home(randperson) === randhouse
        @test !isempty(randhouse)
        @test num_occupants(randhouse) == 1
    end

    @testset verbose=true "Person" begin
        reset_house!(randperson)

        @test ishomeless(randperson)
        @test verify_consistency(randhouse)
        @test verify_consistency(hometown(randperson))

        move_to_house!(randperson,randhouse)

        @test !ishomeless(randperson)
        @test verify_consistency(randhouse)
        @test verify_consistency(hometown(randperson))
    end

    @testset verbose=true "XAgents.jl" begin
        @test verify_agentsjl(randperson)
        @test randperson.id > 0
        ids = Int[]
        for town in towns
            for house in occupied_houses(town)
                @assert length(occupants(house)) == 1
                push!(ids,house.occupants[1].id)
            end
        end
        @test sum(ids) == sum(1:length(ids)) > 0
    end
end
