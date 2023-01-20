export doWorkTransitions!

selectedfor(person,pars,::AlivePopulation,::WorkTransition) =
    status(person) != WorkStatus.retired && has_birthday(person)
selectedfor(p,pars,::FullPopulation,pr::WorkTransition) =
    alive(p) && selectedfor(p,pars,AlivePopulation(),pr)

verbosemsg(::WorkTransition) = "work transitions"
function verbosemsg(person::Person,::WorkTransition)
    y, = age2yearsmonths(age(person))
    return "person $(person.id) of age $(y) changed work status to ..."
end


function _work_transition!(person, time, pars, popfeature)
    if !selectedfor(person,nothing,popfeature,WorkTransition()) return false end
    if age(person) == pars.ageTeenagers
        status!(person, WorkStatus.teenager)
        verbose(person,WorkTransition())
        return true
    end

    if age(person) == pars.ageOfAdulthood
        status!(person, WorkStatus.student)
        #class!(person, 0)
        if rand() < pars.probOutOfTownStudent
            outOfTownStudent!(person, true)
        end
        verbose(person,WorkTransition())
        return true
    end

    if age(person) == pars.ageOfRetirement
        status!(person, WorkStatus.retired)
        set_empty_job_schedule!(person)
        wage!(person, 0)
        shareWorkingTime = workingPeriods(person) / pars.minContributionPeriods
        dK = rand(Normal(0, pars.wageVar))
        pension!(person, shareWorkingTime * exp(dK))
        verbose(person,WorkTransition())
        return true
    end

    false
end

work_transition!(person, time, model, popfeature::PopulationFeature = FullPopulation()) =
    _work_transition!(person, time, work_pars(model), popfeature)

function _do_work_transitions!(ret, model, time, popfeature)
    ret = init_return!(ret)
    people = select_population(model,nothing,popfeature,WorkTransition())
    workpars = work_pars(model)
    for (ind,person) in enumerate(people)
        if _work_transition!(person, time, workpars, popfeature)
            ret = progress_return!(ret,(ind=ind,person=person))
        end
    end
    verbose(ret,WorkTransition())
    return ret
end

do_work_transitions!(model, time, popfeature::PopulationFeature, ret = nothing) =
    _do_work_transitions!(ret, model, time, popfeature)
do_work_transitions!(model, time, ret = nothing) =
    do_work_transitions!(model, time, AlivePopulation(), ret)
