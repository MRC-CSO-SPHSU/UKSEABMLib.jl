export dobirths!, birth!

const _BIRTH_PROP_BEFORE_1951::Ref{Float64} = -1.0 
const _BIRTH_PROP = -ones(30,90)  

_birth_probability(womanage::Int,birthpars,data,curryear::Int) = 
	data.fertility[womanage-birthpars.minPregnancyAge+1,curryear-1950] * birthpars.fertilityBias

function cache_computation(model,::Birth)
	birthpars = birth_pars(model)
	_BIRTH_PROP_BEFORE_1951[] = birthpars.growingPopBirthProb * birthpars.fertilityBias 
	@assert birthpars.minPregnancyAge == 17 
	@assert birthpars.maxPregnancyAge - birthpars.minPregnancyAge < 30 
	data = data_of(model)
	for year in 1951:2040
		for womanage in birthpars.minPregnancyAge:birthpars.maxPregnancyAge 
			_BIRTH_PROP[womanage-birthpars.minPregnancyAge+1,year-1950] = 
				_birth_probability(womanage,birthpars,data,year)
		end
	end
	nothing 
end

function _birth_probability(rWoman,birthpars,data,currstep,::UseCache) 
	curryear, = date2yearsmonths(currstep)
	if curryear < 1951 
		return _BIRTH_PROP_BEFORE_1951[] 
	end 
	yearsold,_ = age2yearsmonths(age(rWoman)) 
	return _BIRTH_PROP[yearsold-birthpars.minPregnancyAge+1,curryear-1950]
end

function _birth_probability(rWoman,birthpars,data,currstep,::NoCaching)
    curryear, = date2yearsmonths(currstep)

    #=
    womanClassShares = []
    womanClassShares.append(len([x for x in womenOfReproductiveAge if x.classRank == 0])/float(len(womenOfReproductiveAge)))
    womanClassShares.append(len([x for x in womenOfReproductiveAge if x.classRank == 1])/float(len(womenOfReproductiveAge)))
    womanClassShares.append(len([x for x in womenOfReproductiveAge if x.classRank == 2])/float(len(womenOfReproductiveAge)))
    womanClassShares.append(len([x for x in womenOfReproductiveAge if x.classRank == 3])/float(len(womenOfReproductiveAge)))
    womanClassShares.append(len([x for x in womenOfReproductiveAge if x.classRank == 4])/float(len(womenOfReproductiveAge)))
    =#

    if curryear < 1951
		return birthpars.growingPopBirthProb * birthpars.fertilityBias 
	end 
	yearold, = age2yearsmonths(age(rWoman))
	#=
    a = 0
    for i in range(int(self.p['numberClasses'])):
        a += womanClassShares[i]*math.pow(self.p['fertilityBias'], i)
        baseRate = rawRate/a
        birthProb = baseRate*math.pow(self.p['fertilityBias'], womanRank)
    =#

    # The above formula with one single socio-economic class translates to:
	return	_birth_probability(yearold,birthpars,data,curryear)
end # computeBirthProb


function _effects_maternity!(woman)
    start_maternity!(woman)

    workingHours!(woman, 0)
    income!(woman, 0)
    potentialIncome!(woman, 0)
    availableWorkingHours!(woman, 0)
    # commented in sim.py:
    # woman.weeklyTime = [[0]*12+[1]*12, [0]*12+[1]*12, [0]*12+[1]*12, [0]*12+[1]*12, [0]*12+[1]*12, [0]*12+[1]*12, [0]*12+[1]*12]
    # sets all weeklyTime slots to 1
    # TODO copied from the python code, but does it make sense?
    set_full_weekly_time!(woman)
    #= TODO
    woman.maxWeeklySupplies = [0, 0, 0, 0]
    woman.residualDailySupplies = [0]*7
    woman.residualWeeklySupplies = [x for x in woman.maxWeeklySupplies]
    =#

    # TODO not necessarily true in many cases
    if isnoperson(provider(woman))
        set_as_provider_providee!(partner(woman), woman)
    end

    nothing
end

function _assumption_birth(woman, birthpars, birthProb)
    assumption() do
        @assert isfemale(woman)
        @assert age_youngest_alive_child(woman) > 1
        @assert !issingle(woman)
        @assert age(woman) >= birthpars.minPregnancyAge
        @assert age(woman) <= birthpars.maxPregnancyAge
        @assert birthProb >= 0
    end
    nothing
end

function _subject_to_birth(woman, currstep, data, birthpars,caching::CachingOperation)
    # womanClassRank = woman.classRank
    # if woman.status == 'student':
    #     womanClassRank = woman.parentsClassRank

    birthProb = _birth_probability(woman, birthpars, data, currstep,caching)

    _assumption_birth(woman, birthpars, birthProb)

    #=
    The following code is commented in the python code:
    #baseRate = self.baseRate(self.socialClassShares, self.p['fertilityBias'], rawRate)
    #fertilityCorrector = (self.socialClassShares[woman.classRank] - self.p['initialClassShares'][woman.classRank])/self.p['initialClassShares'][woman.classRank]
    #baseRate *= 1/math.exp(self.p['fertilityCorrector']*fertilityCorrector)
    #birthProb = baseRate*math.pow(self.p['fertilityBias'], woman.classRank)
    =#

    if rand() < p_yearly2monthly(birthProb)
        return true
    end # if rand()

    return false
end

function _givesbirth!(woman)
    # parentsClassRank = max([woman.classRank, woman.partner.classRank])
    # baby = Person(woman, woman.partner, self.year, 0, 'random', woman.house, woman.sec, -1,
    #              parentsClassRank, 0, 0, 0, 0, 0, 0, 'child', False, 0, month)
    baby = Person(pos=home(woman),
                    father=partner(woman),mother=woman,
                    gender=rand([male,female]))

    # this goes first, so that we know material circumstances
    _effects_maternity!(woman)

    set_as_guardian_dependent!(woman, baby)
    if !issingle(woman) # currently not an option
        set_as_guardian_dependent!(partner(woman), baby)
    end
    set_as_provider_providee!(woman, baby)

    return baby
end

_selectedfor(woman, birthpars, ::Birth) = isfemale(woman) &&
    !issingle(woman) &&
    age(woman) >= birthpars.minPregnancyAge &&
    age(woman) <= birthpars.maxPregnancyAge &&
    age_youngest_alive_child(woman) > 1

selectedfor(woman, birthpars, ::AlivePopulation, process::Birth) = 
	_selectedfor(woman, birthpars, process)
selectedfor(woman, birthpars, ::FullPopulation, process::Birth) =
    alive(woman) && _selectedfor(woman, birthpars, process)

function _birth!(woman, currstep, data, birthpars, popfeature,caching)
    if !(selectedfor(woman, birthpars, popfeature, Birth())) return false end
    if _subject_to_birth(woman, currstep, data, birthpars,caching)
        _givesbirth!(woman)
        verbose(woman, Birth())
        return true
    end
    return false
end

function birth!(woman, model, popfeature::PopulationFeature = FullPopulation(); 
	caching::CachingOperation = NoCache())
    if _birth!(woman, currenttime(model), data_of(model), birth_pars(model), popfeature, caching)
        add_person!(model,youngest_child(woman))
        return true
    end
    return false
end

function _verbose_dobirths(people, nbabies::Int, birthpars)
    delayedVerbose() do
        allFemales = [ woman for woman in people if isfemale(woman) ]
        adultWomen = [ aWoman for aWoman in allFemales if
                                age(aWoman) >= birthpars.minPregnancyAge ]
        notFertiledWomen = [ nfWoman for nfWoman in adultWomen if
                                age(nfWoman) > birthpars.maxPregnancyAge ]
        womenOfReproductiveAge = [ rWoman for rWoman in adultWomen if
                                age(rWoman) <= birthpars.maxPregnancyAge ]
        marriedWomenOfReproductiveAge =
                    [ rmWoman for rmWoman in womenOfReproductiveAge if
                                !issingle(rmWoman) ]
        womenWithRecentChild = [ rcWoman for rcWoman in adultWomen if
                                age_youngest_alive_child(rcWoman) <= 1 ]
        reproductiveWomen = [ rWoman for rWoman in marriedWomenOfReproductiveAge if
                                age_youngest_alive_child(rWoman) > 1 ]
        womenOfReproductiveAgeButNotMarried =
                    [ rnmWoman for rnmWoman in womenOfReproductiveAge if
                                issingle(rnmWoman) ]

        #   for person in self.pop.livingPeople:
    #
    #      if person.sex == 'female' and person.age >= self.p['minPregnancyAge']:
    #                adultLadies += 1
    #                if person.partner != None:
    #                    marriedLadies += 1
    #        marriedPercentage = float(marriedLadies)/float(adultLadies)

        numMarriedRepLadies = length(womenOfReproductiveAge) -
                            length(womenOfReproductiveAgeButNotMarried)
        repMarriedPercentage = numMarriedRepLadies / length(adultWomen)
        womenWithRecentChildPercentage = length(womenWithRecentChild) / numMarriedRepLadies

        println("# allFemales    : $(length(allFemales))")
        println("# adult women   : $(length(adultWomen))")
        println("# NotFertile    : $(length(notFertiledWomen))")
        println("# fertile women : $(length(womenOfReproductiveAge))")
        println("# non-married fertile women : $(length(womenOfReproductiveAgeButNotMarried))")
        println("# of women with recent child: $(length(womenWithRecentChild))")
        println("married reproductive percentage : $repMarriedPercentage")
        println("  out of which had a recent child : $womenWithRecentChildPercentage ")
        println("number of births : $nbabies")
    end
    nothing
end

_verbose_dobirths(people, babies, birthpars) =
    _verbose_dobirths(people, length(babies), birthpars)

function _assumption_dobirths(people, birthpars, currstep)
    assumption() do
        #@info currstep
        reproductiveWomen =
            [ woman for woman in people if
                selectedfor(woman, birthpars, FullPopulation(), Birth()) ]
        allFemales = [ woman for woman in people if isfemale(woman) && alive(woman) ]
        adultWomen = [ aWomen for aWomen in allFemales if
                         age(aWomen) >= birthpars.minPregnancyAge ]
        nonadultFemale = setdiff(Set(allFemales),Set(adultWomen))
        for woman in nonadultFemale
            @assert(issingle(woman))
            @assert !has_children(woman)
        end

        for woman in allFemales
            if !(woman in reproductiveWomen)
                @assert issingle(woman) ||
                age(woman) < birthpars.minPregnancyAge ||
                age(woman) > birthpars.maxPregnancyAge  ||
                age_youngest_alive_child(woman) <= 1
            end
        end
    end
    nothing
end

#=
function _dobirths!(people, currstep, data, birthpars)

    # numBirths =  0    # instead of [0, 0, 0, 0, 0]

    #reproductiveWomen = [ woman for woman in people if select_birth(woman, birthpars) ]
    _assumption_dobirths(people, birthpars, currstep)
    babies = Person[]

    adultLadies_1 = [x for x in adultWomen if x.classRank == 0]
    marriedLadies_1 = len([x for x in adultLadies_1 if x.partner != None])
    if len(adultLadies_1) > 0:
        marriedPercentage.append(marriedLadies_1/float(len(adultLadies_1)))
    else:
    marriedPercentage.append(0)
    adultLadies_2 = [x for x in adultWomen if x.classRank == 1]
    marriedLadies_2 = len([x for x in adultLadies_2 if x.partner != None])
    if len(adultLadies_2) > 0:
        marriedPercentage.append(marriedLadies_2/float(len(adultLadies_2)))
    else:
        marriedPercentage.append(0)
    adultLadies_3 = [x for x in adultWomen if x.classRank == 2]
    marriedLadies_3 = len([x for x in adultLadies_3 if x.partner != None])
    if len(adultLadies_3) > 0:
        marriedPercentage.append(marriedLadies_3/float(len(adultLadies_3)))
    else:
        marriedPercentage.append(0)
    adultLadies_4 = [x for x in adultWomen if x.classRank == 3]
    marriedLadies_4 = len([x for x in adultLadies_4 if x.partner != None])
    if len(adultLadies_4) > 0:
        marriedPercentage.append(marriedLadies_4/float(len(adultLadies_4)))
    else:
        marriedPercentage.append(0)
    adultLadies_5 = [x for x in adultWomen if x.classRank == 4]
    marriedLadies_5 = len([x for x in adultLadies_5 if x.partner != None])
    if len(adultLadies_5) > 0:
        marriedPercentage.append(marriedLadies_5/float(len(adultLadies_5)))
    else:
    marriedPercentage.append(0)
    ...
end  # function doBirths!
=#

verbosemsg(::Birth) = "births"
function verbosemsg(person::Person,::Birth)
    y, = age2yearsmonths(age(person))
    baby = youngest_child(person)
    @assert age(baby) == 0
    return "woman $(person.id) gave birth of $(baby.id) at age of $(y)"
end

function _dobirths!(ret, model, popfeature, caching::CachingOperation )
    ret = init_return!(ret)
    birthpars = birth_pars(model)
    people = select_population(model, nothing, popfeature, Birth())
    data = data_of(model)
    len = length(people)
    currstep = currenttime(model)
    _assumption_dobirths(people, birthpars, currstep)
    for (ind,woman) in enumerate(Iterators.reverse(people))
        if _birth!(woman, currenttime(model), data, birthpars, popfeature, caching)
           @assert people[len-ind+1] === woman
           add_person!(model,youngest_child(woman)::Person)
           ret = progress_return!(ret,(ind=len-ind+1,person=woman))
        end
    end # for woman
    _,m = date2yearsmonths(currstep)
    if m == 0
        nbabies = length(people) - len
        _verbose_dobirths(people, nbabies, birthpars)
    end
    verbose(ret,Birth())
    return ret
end

dobirths!(model, popfeature::PopulationFeature, ret = nothing; 
	caching::CachingOperation = NoCaching()) =
    	_dobirths!(ret, model, popfeature, caching)

"""
    dobirths!(model)

Accept a population and evaluates the birth rate upon computing
- the population of married fertile women according to
fixed parameters (minPregnenacyAge, maxPregnancyAge) and
- the birth probability data (fertility bias and growth rates)

Class rankes and shares are temporarily ignored.
"""
dobirths!(model, ret=nothing; caching::CachingOperation = NoCache()) =
	dobirths!(model, FullPopulation(), ret; caching)
