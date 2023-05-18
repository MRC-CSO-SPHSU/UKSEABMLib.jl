export age_transition!, do_age_transitions!

selectedfor(p,pars,::AlivePopulation,::AgeTransition) = true
selectedfor(p,pars,::FullPopulation,::AgeTransition)  = alive(p)

function _age_transition!(person, maternityLeaveDuration, popfeature)
    if !selectedfor(person, nothing,popfeature,AgeTransition()) return false end
    ret = false
    if is_in_maternity(person)
        # count maternity months
        step_maternity!(person)
        # end of maternity leave
        if maternity_duration(person) >= maternityLeaveDuration
            end_maternity!(person)
            ret = true
        end
    end
        # TODO part of location module, TBD
        #if has_birthday(person, month)
        #    person.movedThisYear = false
        #    person.yearInTown += 1
        #end
    agestep!(person)
    if age(person) == 18
        # also updates guardian
        set_as_independent!(person)
        ret = true
    end
    return ret
end

age_transition!(person, model, popfeature::PopulationFeature = FullPopulation()) =
    _age_transition!(person, work_pars(model).maternityLeaveDuration, popfeature)

function _verbose_age_transition(cntind,cntendedM)
    delayedVerbose() do
        if cntind > 0 || cntendedM > 0
            println("# of persons who became independent : $(cntind)")
            println("# of persons who ended maternity leave: $(cntendedM)")
        end
    end
end

verbosemsg(::AgeTransition) = "persons who became independent or ended maternity"

function _do_age_transitions!(ret,model, popfeature)
    ret = init_return!(ret)
    people = select_population(model,nothing,popfeature,AgeTransition())
    maternityLeaveDuration = work_pars(model).maternityLeaveDuration
    cntind = 0
    cntendedM = 0
    for (ind,person) in enumerate(people)
        if _age_transition!(person, maternityLeaveDuration, popfeature)
            ret = progress_return!(ret,(ind=ind,person=person))
            if age(person) == 18
                cntind += 1
            else
                cntendedM += 1
            end
        end
    end
    verbose(ret,AgeTransition())
    _verbose_age_transition(cntind,cntendedM)
    return ret
end

do_age_transitions!(model, popfeature::PopulationFeature, ret=nothing) =
    _do_age_transitions!(ret, model, popfeature)
do_age_transitions!(model, ret=nothing) =
    do_age_transitions!(model, AlivePopulation(), ret)
