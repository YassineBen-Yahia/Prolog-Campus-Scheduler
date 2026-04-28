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
    optimization:best_schedule(Schedule, EnergyState, Score),
    statistics(walltime, [_, ElapsedMs]), % ElapsedMs = time since above call
    write('Best schedule found:'), nl,
    utils:print_schedule(Schedule),
    write('Energy state: '), write(EnergyState), nl,
    write('Score: '), write(Score), nl,
    write('Elapsed ms: '), write(ElapsedMs), nl.
