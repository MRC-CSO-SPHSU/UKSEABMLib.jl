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
        @assert typeof(agem) == Rational{Int}
    end
    nothing 
end 

function _divorce!(man, time, allHouses, allTowns, parameters)
        
    agem = age(man) 
    _assumption_divorce(man)
    
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

function _verbose_dodivorce(divorced) 
    delayedVerbose() do
        println("# of divorced : $(length(divorced))")
    end
    nothing 
end 

function _dodivorces!(people, model, time)
    divorced = Person[] 
    pars = fuse(divorceParameters(model),workParameters(model))
    for man in people    
        if ! select_divorce_alive(man) continue end 
        wife = partner(man) 
        if _divorce!(man, time, houses(model), towns(model), pars) 
            push!(divorced,man, wife) 
        end 
    end 
    _verbose_dodivorce(divorced)
    return divorced  
end

dodivorces!(model, time, ::FullPopulation) = _dodivorces!(alivePeople(model) , model, time) 
dodivorces!(model, time, ::AlivePopulation) = _dodivorces!(allPeople(model) , model, time) 
dodivorces!(model, time) = dodivorces!(model, time, AlivePopulation())
