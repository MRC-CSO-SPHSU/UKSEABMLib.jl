export dodivorces!, divorce!

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
        @assert ismale(man)
        @assert !issingle(man)
        agem = age(man)
        @assert typeof(agem) == Rational{Int}
    end
    nothing
end

selectedfor(person,pars,::AlivePopulation,::Divorce) =
    ismale(person) && !issingle(person)
selectedfor(person, pars,::FullPopulation,process::Divorce) =
    alive(person) && selectedfor(person,pars,AlivePopulation(),process)

function _divorce!(man, time, model, divorcepars, workpars, popfeature) #parameters)
    if !selectedfor(man,nothing,popfeature, Divorce()) return false end

    agem = age(man)
    ## This is here to manage the sweeping through of this parameter
    ## but only for the years after 2012
    if time < divorcepars.thePresent
        # Not sure yet if the following is parameter or data
        rawRate = divorcepars.basicDivorceRate *
            divorcepars.divorceModifierByDecade[ceil(Int, agem / 10 )]
    else
        rawRate = divorcepars.variableDivorce  *
            divorcepars.divorceModifierByDecade[ceil(Int, agem / 10 )]
    end

    divorceProb = _divorce_probability(rawRate, divorcepars) # TODO , man.classRank)

    if rand() < p_yearly2monthly(divorceProb)
        wife = partner(man)
        resolve_partnership!(man, wife)

        #=
        man.yearDivorced.append(self.year)
        wife.yearDivorced.append(self.year)
        =#
        if status(wife) == WorkStatus.student
            _start_working!(wife, workpars) # from workTransitions.jl
        end

        #peopleToMove = [man]
        move_to_empty_house!(man, model,
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
                resolve_dependency!(wife, child)
                move_to_person_house!(child,man)
            else
                resolve_dependency!(man, child)
            end
        end # for
        verbose(man, Divorce())
        return true
    end

    return false
end

divorce!(man, time, model, popfeature::PopulationFeature = FullPopulation()) =
    _divorce!(man,
            time,
            model,
            divorce_pars(model),
            work_pars(model),
            popfeature)

function _verbose_dodivorce(ndivorced::Int, model)
    delayedVerbose() do
        println("# of divorced : $ndivorced")
        nempty, nocc = num_houses(towns(model))
        println("# of houses : $(length(houses(model))) \
                    out of which $nempty empty and $nocc occupied")
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

verbosemsg(::Divorce) = "divorces"
function verbosemsg(person::Person,::Divorce)
    return "man $(person.id) divorced"
end

function _dodivorces!(ret, model, time, popfeature)
    ret = init_return!(ret)
    divorcepars = divorce_pars(model)
    workpars = work_pars(model)
    people = select_population(model, nothing, popfeature, Divorce())
    for (ind,man) in enumerate(people)
        if _divorce!(man, time, model, divorcepars, workpars, popfeature)
            ret = progress_return!(ret,(ind=ind,person=man))
        end
    end
    verbose(ret,Divorce())
    return ret
end

dodivorces!(model, time, popfeature::PopulationFeature, ret = nothing) =
    _dodivorces!(ret, model, time, popfeature)

dodivorces!(model, time, ret = nothing) =
    dodivorces!(model, time, AlivePopulation(), nothing)
