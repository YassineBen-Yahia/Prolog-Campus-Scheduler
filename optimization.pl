:- module(optimization, [
    schedule_score/3,
    best_schedule/3,
    load_imbalance/2,
    room_usage_variance/2
]).

:- use_module(facts).
:- use_module(energy).
:- use_module(scheduler).

/*
schedule_score(+Schedule, +EnergyState, -Score)

Lower score is better.
Score = TotalEnergy + LoadImbalance + RoomVariance
*/
schedule_score(Schedule, EnergyState, Score) :-
    energy:total_weekly_energy(EnergyState, TotalEnergy),
    load_imbalance(EnergyState, Imbalance),
    room_usage_variance(Schedule, Variance),
    Score is TotalEnergy + Imbalance + Variance.

/*
Load imbalance = max daily total - min daily total
Filters out 0 energy days to avoid artificially lowering the minimum.
*/
load_imbalance(EnergyState, Imbalance) :-
    facts:all_days(Days),
    daily_totals(Days, EnergyState, Totals),
    exclude(=(0), Totals, NonZeroTotals),
    ( NonZeroTotals = [] -> Imbalance = 0 ;
      max_list(NonZeroTotals, Max),
      min_list(NonZeroTotals, Min),
      Imbalance is Max - Min
    ).

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

/*
Room usage variance calculation
Var(R) = (1/m) * sum(Usage(r_j) - μ)²
*/
room_usage_variance(Schedule, Variance) :-
    findall(Room, facts:room(Room, _, _, _, _), Rooms),
    length(Rooms, M),
    ( M =:= 0 -> Variance = 0 ;
      room_usages(Rooms, Schedule, Usages),
      sum_list(Usages, SumUsages),
      Mu is SumUsages / M,
      sum_squared_diff(Usages, Mu, SumSq),
      Variance is SumSq / M
    ).

room_usages([], _Schedule, []).
room_usages([Room|Rest], Schedule, [Usage|Usages]) :-
    findall(Dur, member(assign(_C, _S, Room, _D, _Start, Dur), Schedule), Durs),
    sum_list(Durs, Usage),
    room_usages(Rest, Schedule, Usages).

sum_squared_diff([], _Mu, 0).
sum_squared_diff([U|Rest], Mu, Sum) :-
    sum_squared_diff(Rest, Mu, TailSum),
    Sum is TailSum + (U - Mu) ** 2.

best_schedule(BestSchedule, BestEnergyState, BestScore) :-
    BestRef = best(none),
    (
        scheduler:schedule(Schedule, EnergyState),
        schedule_score(Schedule, EnergyState, Score),
        update_best(BestRef, candidate(Schedule, EnergyState, Score)),
        fail
    ;
        arg(1, BestRef, Result),
        (   Result = candidate(BestSchedule, BestEnergyState, BestScore)
        ->  true
        ;   format('Error: No valid schedule could be found! Constraints may be too tight.~n'), fail
        )
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
