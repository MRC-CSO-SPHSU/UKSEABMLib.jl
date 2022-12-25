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

#const _DIST_CHOICES = (InTown(),AdjTown(),AnyWhere())

function _divorce!(man, time, model, divorcepars) #parameters)
        
    agem = age(man) 
    
    ## This is here to manage the sweeping through of this parameter
    ## but only for the years after 2012
    if time < divorcepars.thePresent 
        # Not sure yet if the following is parameter or data 
        rawRate = divorcepars.basicDivorceRate * divorcepars.divorceModifierByDecade[ceil(Int, agem / 10 )]
    else 
        rawRate = divorcepars.variableDivorce  * divorcepars.divorceModifierByDecade[ceil(Int, agem / 10 )]           
    end

    divorceProb = _divorce_probability(rawRate, divorcepars) # TODO , man.classRank)

    if rand() < p_yearly2monthly(divorceProb) 
        wife = partner(man)
        resolvePartnership!(man, wife)
        
        #=
        man.yearDivorced.append(self.year)
        wife.yearDivorced.append(self.year)
        =# 
        if status(wife) == WorkStatus.student
            startWorking_!(wife, workParameters(model))
        end

        #peopleToMove = [man]
        move_person_to_emptyhouse!(man, model, 
                                    #rand(_DIST_CHOICES))
                                    rand((InTown(),AdjTown(),AnyWhere())))
        for child in dependents(man)
            @assert alive(child)
            # TODO check the following 
            if (father(child) == man && mother(child) != wife) ||
                # if both have the same status decide by probability
                (((father(child) == man) && (mother(child) == wife)) &&
                 rand() < divorcepars.probChildrenWithFather)
                #push!(peopleToMove, child)
                resolveDependency!(wife, child)
                move_person_to_person_house!(child,man)
            else
                resolveDependency!(man, child)
            end 
        end # for 

        return true 
    end

    return false 
end 

divorce!(man, time, model, pars) = 
    _divorce!(man, 
            time, 
            model,
            divorceParameters(pars))
            #fuse(divorceParameters(parameters),workParameters(parameters), mapParameters(parameters)))

select_divorce_alive(person)  = isMale(person) && !isSingle(person)
selectDivorce(person, pars) = alive(person) && select_divorce_alive(person)

function _verbose_dodivorce(ndivorced::Int, model) 
    delayedVerbose() do
        println("# of divorced : $ndivorced")
        nempty, nocc = number_of_houses(towns(model))
        println("# of houses : $(length(houses(model))) out of which $nempty empty and $nocc occupied")
    end
    nothing 
end 

function _verbose_dodivorce(divorced::Vector{Person}, model)  
    _verbose_dodivorce(length(divorced),model)
end

function _verbose_dodivorce(man::Person) 
    delayedVerbose() do
        println("man id $(man.id) got divorced")
    end
    nothing 
end 

function _dodivorces!(people, model, time)
    divorced = Person[] 
    #pars = fuse(divorceParameters(model),workParameters(model), mapParameters(model))
    for man in people    
        if ! select_divorce_alive(man) continue end 
        wife = partner(man) 
        _assumption_divorce(man)
        if _divorce!(man, time, model, divorceParameters(model)) 
            push!(divorced, man, wife) 
        end 
    end 
    if length(divorced) > 0
        _verbose_dodivorce(divorced)
    end 
    return (divorced = divorced,) 
end

function _dodivorces_noret!(people, model, time)
    #pars = fuse(divorceParameters(model),workParameters(model))
    ndivorced = 0
    for man in people    
        if ! select_divorce_alive(man) continue end 
        if _divorce!(man, time, model, divorceParameters(model))  
            ndivorced += 2 
            _verbose_dodivorce(man)
        end 
    end 
    if ndivorced > 0 
        _verbose_dodivorce(ndivorced, model)
    end 
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
