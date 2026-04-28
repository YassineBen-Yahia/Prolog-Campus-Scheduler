:- use_module(facts).
:- use_module(utils).
:- use_module(constraints).
:- use_module(energy).
:- use_module(scheduler).
:- use_module(optimization).

check_facts_integrity :-
    forall(
        (facts:availability(Course, Slots), member(slot(Day, Idx), Slots)),
        (   facts:slot(Day, Idx)
        ->  true
        ;   format('WARNING: Course ~w has availability slot(~w,~w) which does not exist in slot facts!~n', 
                   [Course, Day, Idx])
        )
    ).

run_one :-
    check_facts_integrity,
    scheduler:schedule(Schedule, EnergyState),
    write('Feasible schedule found:'), nl,
    utils:print_schedule(Schedule),
    write('Energy state: '), write(EnergyState), nl.

run_all :-
    check_facts_integrity,
    aggregate_all(count, scheduler:schedule(_, _), Count),
    format('Total valid schedules found: ~w~n~n', [Count]),
    scheduler:schedule(Schedule, EnergyState),
    write('Feasible schedule found:'), nl,
    utils:print_schedule(Schedule),
    write('Energy state: '), write(EnergyState), nl, nl,
    fail.
run_all.

run_best :-
    check_facts_integrity,
    statistics(walltime, [_,_]),          % reset the "since last" counter
    optimization:best_schedule(Schedule, EnergyState, _Score),
    statistics(walltime, [_, ElapsedMs]), % ElapsedMs = time since above call
    write('Best schedule found:'), nl,
    utils:print_schedule(Schedule),
    print_score_breakdown(Schedule, EnergyState),
    print_energy_report(EnergyState),
    write('Elapsed ms: '), write(ElapsedMs), nl.

print_energy_report(EnergyState) :-
    facts:all_days(Days),
    findall(B, facts:building(B, _), Buildings),
    format('~n=== Energy Report ===~n'),
    forall(
        member(Building, Buildings),
        (
            facts:building(Building, Max),
            format('Building ~w (max ~w/day):~n', [Building, Max]),
            forall(
                member(Day, Days),
                (
                    energy:daily_building_energy(Building, Day, EnergyState, Used),
                    Margin is Max - Used,
                    format('  ~w: used=~w, margin=~w~n', [Day, Used, Margin])
                )
            )
        )
    ),
    nl.

print_score_breakdown(Schedule, EnergyState) :-
    energy:total_weekly_energy(EnergyState, TotalEnergy),
    optimization:load_imbalance(EnergyState, Imbalance),
    optimization:room_usage_variance(Schedule, Variance),
    Score is TotalEnergy + Imbalance + Variance,
    format('  Total Energy   : ~2f~n', [TotalEnergy]),
    format('  Load Imbalance : ~2f~n', [Imbalance]),
    format('  Room Variance  : ~2f~n', [Variance]),
    format('  TOTAL SCORE    : ~2f~n', [Score]).
