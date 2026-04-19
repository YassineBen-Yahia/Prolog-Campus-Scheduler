:- use_module(facts).
:- use_module(utils).
:- use_module(constraints).
:- use_module(energy).
:- use_module(scheduler).
:- use_module(optimization).

run_one :-
    scheduler:schedule(Schedule, EnergyState),
    write('Feasible schedule found:'), nl,
    utils:print_schedule(Schedule),
    write('Energy state: '), write(EnergyState), nl.

run_all :-
    scheduler:schedule(Schedule, EnergyState),
    write('Feasible schedule found:'), nl,
    utils:print_schedule(Schedule),
    write('Energy state: '), write(EnergyState), nl, nl,
    fail.
run_all.

run_best :-
    statistics(walltime, [_Start|_]),
    optimization:best_schedule(Schedule, EnergyState, Score),
    statistics(walltime, [_End, ElapsedMs]),
    write('Best schedule found:'), nl,
    utils:print_schedule(Schedule),
    write('Energy state: '), write(EnergyState), nl,
    write('Score: '), write(Score), nl,
    write('Elapsed ms: '), write(ElapsedMs), nl.
