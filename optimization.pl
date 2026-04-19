:- module(optimization, [
    schedule_score/3,
    best_schedule/3
]).

:- use_module(facts).
:- use_module(energy).
:- use_module(scheduler).

/*
schedule_score(+Schedule, +EnergyState, -Score)

Lower score is better.
For now:
Score = TotalEnergy + LoadImbalance
You can extend later with fairness.
*/
schedule_score(_Schedule, EnergyState, Score) :-
    energy:total_weekly_energy(EnergyState, TotalEnergy),
    load_imbalance(EnergyState, Imbalance),
    Score is TotalEnergy + Imbalance.

/*
Load imbalance = max daily total - min daily total
*/
load_imbalance(EnergyState, Imbalance) :-
    facts:all_days(Days),
    daily_totals(Days, EnergyState, Totals),
    max_list(Totals, Max),
    min_list(Totals, Min),
    Imbalance is Max - Min.

daily_totals([], _EnergyState, []).
daily_totals([Day|Rest], EnergyState, [Total|TotalsRest]) :-
    total_day_energy(Day, EnergyState, Total),
    daily_totals(Rest, EnergyState, TotalsRest).

total_day_energy(Day, EnergyState, Total) :-
    findall(
        E,
        member(usage(_Building, Day, E), EnergyState),
        Energies
    ),
    sum_list(Energies, Total).

best_schedule(BestSchedule, BestEnergyState, BestScore) :-
    BestRef = best(none),
    (
        scheduler:schedule(Schedule, EnergyState),
        schedule_score(Schedule, EnergyState, Score),
        update_best(BestRef, candidate(Schedule, EnergyState, Score)),
        fail
    ;
        BestRef = best(candidate(BestSchedule, BestEnergyState, BestScore))
    ).

update_best(BestRef, Candidate) :-
    arg(1, BestRef, none),
    !,
    nb_setarg(1, BestRef, Candidate).
update_best(BestRef, candidate(_Schedule, _EnergyState, Score)) :-
    arg(1, BestRef, candidate(_BestSchedule, _BestEnergyState, BestScore)),
    Score >= BestScore,
    !.
update_best(BestRef, Candidate) :-
    nb_setarg(1, BestRef, Candidate).
