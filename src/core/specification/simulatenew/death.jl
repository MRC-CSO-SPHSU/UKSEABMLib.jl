
export dodeaths!, death!

function _death_probability(baseRate,person,poppars)
    #=
        Not realized yet  / to be realized in another module?
        classRank = person.classRank
        if person.status == 'child' or person.status == 'student':
            classRank = person.parentsClassRank
    =#

    mortalityBias = ismale(person) ?
        poppars.maleMortalityBias :
        poppars.femaleMortalityBias

    #=
    To be integrated in class modules
    a = 0
    for i in range(int(self.p['numberClasses'])):
        a += self.socialClassShares[i]*math.pow(mortalityBias, i)
    =#

    #=
    if a > 0:
        lowClassRate = baseRate/a
        classRate = lowClassRate*math.pow(mortalityBias, classRank)
        deathProb = classRate

        b = 0
        for i in range(int(self.p['numCareLevels'])):
            b += self.careNeedShares[classRank][i]*math.pow(self.p['careNeedBias'], (self.p['numCareLevels']-1) - i)

        if b > 0:
            higherNeedRate = classRate/b
            deathProb = higherNeedRate*math.pow(self.p['careNeedBias'], (self.p['numCareLevels']-1) - person.careNeedLevel) # deathProb
    =#

    # assuming it is just one class and without care need,
    # the above code translates to:

    deathProb = baseRate * mortalityBias

        ##### Temporarily by-passing the effect of Unmet Care Need   #############

    #   The following code is already commented in the python code
    #   a = 0
    #   for x in classPop:
    #   a += math.pow(self.p['unmetCareNeedBias'], 1-x.averageShareUnmetNeed)
    #   higherUnmetNeed = (classRate*len(classPop))/a
    #   deathProb = higherUnmetNeed*math.pow(self.p['unmetCareNeedBias'], 1-shareUnmetNeed)
    return deathProb
end # function deathProb

selectedfor(p,pars,::AlivePopulation,::Death) = true
selectedfor(p,pars,::FullPopulation,::Death)  = alive(p)
selectedfor(p,pars,process::Death) = selectedfor(p,pars,FullPopulation(),process)

# currently leaves dead agents in population
function _death!(person, currstep, data, poppars, popfeature)
    if !selectedfor(person,nothing,popfeature,Death()) return false end
    (curryear,currmonth) = date2yearsmonths(currstep)
    currmonth += 1 # adjusting 0:11 => 1:12
    #agep = age(person)
    agep = Float64(age(person))
    if curryear >= 1950
        agep = agep > 109 ? 109.0 : agep
        ageindex = trunc(Int,agep)
        rawRate = ismale(person) ? data.deathMale[ageindex+1,curryear-1950+1] :
                                            data.deathFemale[ageindex+1,curryear-1950+1]
        # lifeExpectancy = max(90 - agep, 3 // 1)  # ??? This is a direct translation
    else # curryear < 1950 / made-up probabilities
        babyDieProb = agep < 1 ? poppars.babyDieProb : 0.0 # does not play any role in the code
        ageDieProb  = ismale(person) ?
                        exp(agep / poppars.maleAgeScaling)  * poppars.maleAgeDieProb :
                        exp(agep / poppars.femaleAgeScaling) * poppars.femaleAgeDieProb
        rawRate = poppars.baseDieProb + babyDieProb + ageDieProb
        # lifeExpectancy = max(90 - agep, 5 // 1)  # ??? Does not currently play any role
    end # currYear < 1950

    #=
        Not realized yet
        classPop = [x for x in self.pop.livingPeople
                        if x.careNeedLevel == person.careNeedLevel]
        Classes to be considered in a different module
    =#

    deathProb = min(1.0, _death_probability(rawRate,person,poppars))

    #=
        The following is uncommented code in the original code < 1950
        #### Temporarily by-passing the effect of unmet care need   ######
        # dieProb = self.deathProb_UCN(rawRate, person.parentsClassRank, person.careNeedLevel, person.averageShareUnmetNeed, classPop)
    =#

    if rand() < p_yearly2monthly(deathProb)
        set_dead!(person)
        verbose(person, Death())
        return true
        # person.deadYear = self.year
        # deaths[person.classRank] += 1
    end # rand

    return false
end

function _assumption_death(person::Person)
    assumption() do
        @assert alive(person)
        @assert ismale(person) || isfemale(person) # Assumption
        @assert typeof(age(person)) == Rational{Int}
    end
    nothing
end

death!(person, model, popfeature::PopulationFeature = FullPopulation()) =
    _death!(person, currenttime(model), data_of(model), population_pars(model), popfeature)

function _assumption_dodeaths(people)
    assumption() do
        for person in people
            _assumption_death(person)
        end
    end
    nothing
end

verbosemsg(::Death) = "deads"
function verbosemsg(person::Person,::Death)
    y = age2years(age(person))
    return "person $(person.id) died with age of $y"
end

_remove_person!(model, person, idx,::AlivePopulation) = remove_person!(model,person,idx)
_remove_person!(model, person, idx,::FullPopulation)  = nothing

function _dodeaths!(ret,model,popfeature)
    verbose_houses(model,"before dodeaths!")
    ret = init_return!(ret)
    poppars = population_pars(model)
    people = select_population(model,nothing,popfeature,Death())
    data = data_of(model)
    len = length(people)
    for (ind,person) in enumerate(Iterators.reverse(people))
        if _death!(person, currenttime(model), data, poppars, popfeature)
            ret = progress_return!(ret,(ind=ind,person=person))
            @assert person === people[len-ind+1]
            _remove_person!(model, person, len-ind+1, popfeature)
        end
    end
    verbose(ret,Death())
    verbose_houses(model,"after dodeaths!")
    return ret
end

dodeaths!(model,::AlivePopulation,::SimFullReturn) =
    error("dodeaths!: returned indices are not meaningful due to deads removal")

dodeaths!(model,::AlivePopulation,::Tuple{Vector{Int},Vector{Person}}) =
    error("dodeaths!: returned indices are not meaningful due to deads removal")

dodeaths!(model, popfeature::PopulationFeature, ret=nothing) =
    _dodeaths!(ret, model, popfeature)

dodeaths!(model, ret=nothing) =
    dodeaths!(model, FullPopulation(), ret)
