export dodivorces!, select_divorce, select_divorce_alive, divorce!

function _divorce_probability(rawRate, pars) # ,classRank) 
    #=
     def computeSplitProb(self, rawRate, classRank):
        a = 0
        for i in range(int(self.p['numberClasses'])):
            a += self.socialClassShares[i]*math.pow(self.p['divorceBias'], i)
        baseRate = rawRate/a
        splitProb = baseRate*math.pow(self.p['divorceBias'], classRank)
        return splitProb
    =# 
    rawRate * pars.divorceBias 
end 

function _assumption_divorce(man)
    assumption() do
        @assert isMale(man) 
        @assert !isSingle(man)
        agem = age(man)
        @assert typeof(agem) == Rational{Int}
    end
    nothing 
end 

function _divorce!(man, time, allHouses, allTowns, parameters)
        
    agem = age(man) 
    
    ## This is here to manage the sweeping through of this parameter
    ## but only for the years after 2012
    if time < parameters.thePresent 
        # Not sure yet if the following is parameter or data 
        rawRate = parameters.basicDivorceRate * parameters.divorceModifierByDecade[ceil(Int, agem / 10 )]
    else 
        rawRate = parameters.variableDivorce  * parameters.divorceModifierByDecade[ceil(Int, agem / 10 )]           
    end

    divorceProb = _divorce_probability(rawRate, parameters) # TODO , man.classRank)

    if rand() < p_yearly2monthly(divorceProb) 
        wife = partner(man)
        resolvePartnership!(man, wife)
        
        #=
        man.yearDivorced.append(self.year)
        wife.yearDivorced.append(self.year)
        =# 
        if status(wife) == WorkStatus.student
            startWorking_!(wife, parameters)
        end

        peopleToMove = [man]
        for child in dependents(man)
            @assert alive(child)
            # TODO check the following 
            if (father(child) == man && mother(child) != wife) ||
                # if both have the same status decide by probability
                (((father(child) == man) && (mother(child) == wife)) &&
                 rand() < parameters.probChildrenWithFather)
                push!(peopleToMove, child)
                resolveDependency!(wife, child)
            else
                resolveDependency!(man, child)
            end 
        end # for 

        movePeopleToEmptyHouse!(peopleToMove, rand([:near, :far]), allHouses, allTowns)

        return true 
    end

    false 
end 

divorce!(man, time, model, parameters) = 
    _divorce!(man, 
            time, 
            houses(model), 
            towns(model), 
            fuse(divorceParameters(parameters),workParameters(parameters)))

select_divorce_alive(person)  = isMale(person) && !isSingle(person)
selectDivorce(person, pars) = alive(person) && select_divorce_alive(person)

function _verbose_dodivorce(ndivorced::Int) 
    delayedVerbose() do
        println("# of divorced : ndivorced")
    end
    nothing 
end 

_verbose_dodivorce(divorced::Vector{Person}) = 
    _verbose_dodivorce(length(divorced)) 

function _verbose_dodivorce(man::Person) 
    delayedVerbose() do
        println("man id $(man.id) got divorced")
    end
    nothing 
end 

function _dodivorces!(people, model, time)
    divorced = Person[] 
    pars = fuse(divorceParameters(model),workParameters(model))
    for man in people    
        if ! select_divorce_alive(man) continue end 
        wife = partner(man) 
        _assumption_divorce(man)
        if _divorce!(man, time, houses(model), towns(model), pars) 
        #if divorce!(man, time, model, allParameters(model))
            push!(divorced, man, wife) 
        end 
    end 
    _verbose_dodivorce(divorced)
    return (divorced = divorced,) 
end

function _dodivorces_noret!(people, model, time)
    pars = fuse(divorceParameters(model),workParameters(model))
    ndivorced = 0
    for man in people    
        if ! select_divorce_alive(man) continue end 
        if _divorce!(man, time, houses(model), towns(model), pars) 
            ndivorced += 2 
            _verbose_dodivorce(man)
        end 
    end 
    _verbose_dodivorce(ndivorced)
    nothing 
end

dodivorces!(model, time, ::FullPopulation, ::WithReturn) = 
    _dodivorces!(alivePeople(model) , model, time) 
dodivorces!(model, time, ::AlivePopulation, ::WithReturn) = 
    _dodivorces!(allPeople(model) , model, time)
dodivorces!(model, time, ::FullPopulation, ::NoReturn) = 
    _dodivorces_noret!(alivePeople(model) , model, time) 
dodivorces!(model, time, ::AlivePopulation, ::NoReturn) = 
    _dodivorces_noret!(allPeople(model) , model, time) 
dodivorces!(model, time) = dodivorces!(model, time, AlivePopulation(),NoReturn())
