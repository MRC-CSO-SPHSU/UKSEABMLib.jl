using Distributions: Normal, LogNormal

export do_social_transitions!, social_transition!

_working_age(person, pars) = pars.workingAge[classRank(person)+1]

selectedfor(person,pars,::AlivePopulation,::SocialTransition) =
    has_birthday(person) && age(person) == _working_age(person, pars) && status(person) == WorkStatus.student
selectedfor(person,pars,::FullPopulation,pr::SocialTransition) =
    alive(person) && selectedfor(person,pars,AlivePopulation(),pr)

# class sensitive versions
# TODO?
# * move to separate, optional module
# * replace with non-class version here
_initial_income_level(person, pars) = pars.incomeInitialLevels[classRank(person)+1]

function _income_dist(person, pars)
    # TODO make parameters
    if classRank(person) == 0
        LogNormal(2.5, 0.25)
    elseif classRank(person) == 1
        LogNormal(2.8, 0.3)
    elseif classRank(person) == 2
        LogNormal(3.2, 0.35)
    elseif classRank(person) == 3
        LogNormal(3.7, 0.4)
    elseif classRank(person) == 4
        LogNormal(4.5, 0.5)
    else
        error("unknown class rank!")
    end
end

# TODO dummy, replace
# or, possibly remove altogether and calibrate model
# properly instead
_social_class_shares(model, class) = 0.2

function studyClassFactor_(person, model, pars)
    if classRank(person) == 0
        return _social_class_shares(model, 0) > 0.2 ?  1/0.9 : 0.85
    end
    if classRank(person) == 1 && _social_class_shares(model, 1) > 0.35
        return 1/0.8
    end
    if classRank(person) == 2 && _social_class_shares(model, 2) > 0.25
        return 1/0.85
    end
    return 1.0
end

_done_studying(person, pars) = classRank(person) >= 4

# probability to start studying instead of working
function _start_studying_prob(person, model, pars)
    if isnoperson(father(person)) && isnoperson(mother(person))
        return 0.0
    end
    if isnoperson(provider(person))
        return 0.0
    end

    # renamed from python but same calculation
    perCapitaDisposableIncome = household_income_percapita(person)
    if perCapitaDisposableIncome <= 0
        return 0.0
    end

    forgoneSalary = _initial_income_level(person, pars) *
        pars.weeklyHours[careNeedLevel(person)+1]
    relCost = forgoneSalary / perCapitaDisposableIncome
    incomeEffect = (pars.constantIncomeParam+1) /
        (exp(pars.eduWageSensitivity * relCost) + pars.constantIncomeParam)

    # TODO factor out class
    targetEL = father(person) != nothing ?
        max(classRank(father(person)), classRank(mother(person))) :
        classRank(mother(person))
    dE = targetEL - classRank(person)
    expEdu = exp(pars.eduRankSensitivity * dE)
    educationEffect = expEdu / (expEdu + pars.constantEduParam)

    careEffect = 1/exp(pars.careEducationParam * (socialWork(person) + childWork(person)))
    pStudy = incomeEffect * educationEffect * careEffect
    pStudy *= studyClassFactor_(person, model, pars)

    return max(0.0, pStudy)
end

_start_studying!(person, pars) = increment_class_rank!(person)


# TODO here for now, maybe not the best place?
function _reset_work!(person, pars)
    status!(person, WorkStatus.unemployed)
    newEntrant!(person, true)
    workingHours!(person, 0)
    income!(person, 0)
    jobTenure!(person, 0)
    # TODO
    # monthHired
    # jobShift
    set_empty_job_schedule!(person)
    outOfTownStudent!(person, true)
end

function _start_working!(person, pars)
    _reset_work!(person, pars)
    dKi = rand(Normal(0, pars.wageVar))
    initialIncome!(person, _initial_income_level(person, pars) * exp(dKi))
    dist = _income_dist(person, pars)
    finalIncome!(person, rand(dist))
    # updates provider as well
    set_as_selfprovidingviding!(person)
# commented in original:
#        if person.classRank < 4:
#            dKf = np.random.normal(dKi, self.p['wageVar'])
#            person.finalIncome = self.p['incomeFinalLevels'][person.classRank]*math.exp(dKf)
#        else:
#            sigma = float(self.p['incomeFinalLevels'][person.classRank])/5.0
            # person.finalIncome = np.random.lognormal(self.p['incomeFinalLevels'][person.classRank], sigma)

#        person.wage = person.initialIncome
#        person.income = person.wage*self.p['weeklyHours'][int(person.careNeedLevel)]
#        person.potentialIncome = person.income
end

# TODO
function _addto_workforce!(person, model) end

# move newly adult agents into study or work
function _social_transition!(person, time, model, workpars, popfeature)
    if !selectedfor(person, workpars, popfeature, SocialTransition()) return false end
    probStudy = _done_studying(person, workpars)  ?
        0.0 : _start_studying_prob(person, model, workpars)
    if rand() < probStudy
        _start_studying!(person, workpars)
        return true
    else
        _start_working!(person, workpars)
        _addto_workforce!(person, model)
    end
    return false
end

social_transition!(person, time, model, popfeature::PopulationFeature = FullPopulation()) =
    _social_transition!(person, time, model, work_pars(model), popfeature)

verbosemsg(::SocialTransition) = "social transitions"
function verbosemsg(person::Person,::SocialTransition)
    y, = age2yearsmonths(age(person))
    return "person $(person.id) of age $(y) changed social status to ..."
end

function _do_social_transitions!(ret, model, time, popfeature)
    ret = init_return!(ret)
    people = select_population(model,nothing,AlivePopulation(),WorkTransition())
    workpars = work_pars(model)
    for (ind,person) in enumerate(people)
        if _social_transition!(person, time, model, workpars, AlivePopulation())
            ret = progress_return!(ret,(ind=ind,person=person))
        end
    end
    verbose(ret,SocialTransition())
    return ret
end

do_social_transitions!(model, time, popfeature::PopulationFeature, ret = nothing) =
    _do_social_transitions!(ret, model, time, popfeature)
do_social_transitions!(model, time, ret = nothing) =
    do_social_transitions!(model, time, AlivePopulation(), ret)
