:- module(energy, [
    empty_energy_state/1,
    energy_ok/4,
    add_energy/5,
    total_weekly_energy/2,
    daily_building_energy/4,
    building_daily_margin/4
]).

:- use_module(facts).

/*
EnergyState is a list of usage(Building, Day, EnergyUsed)
*/

empty_energy_state([]).

energy_ok(Room, Day, Duration, EnergyState) :-
    facts:room(Room, _Cap, _Equip, Building, EnergyPerSlot),
    AddedEnergy is EnergyPerSlot * Duration,
    current_energy(Building, Day, EnergyState, Current),
    NewTotal is Current + AddedEnergy,
    facts:building(Building, MaxDailyEnergy),
    NewTotal =< MaxDailyEnergy.

add_energy(Room, Day, Duration, OldState, NewState) :-
    facts:room(Room, _Cap, _Equip, Building, EnergyPerSlot),
    AddedEnergy is EnergyPerSlot * Duration,
    update_energy(Building, Day, AddedEnergy, OldState, NewState).

current_energy(_Building, _Day, [], 0).
current_energy(Building, Day, [usage(Building,Day,Energy)|_], Energy) :-
    !.
current_energy(Building, Day, [usage(B,D,_)|Rest], Energy) :-
    \+ (Building = B, Day = D),
    current_energy(Building, Day, Rest, Energy).

update_energy(Building, Day, Added, [], [usage(Building,Day,Added)]).
update_energy(Building, Day, Added, [usage(Building,Day,Energy)|Rest], [usage(Building,Day,NewEnergy)|Rest]) :-
    !,
    NewEnergy is Energy + Added.
update_energy(Building, Day, Added, [usage(B,D,E)|Rest], [usage(B,D,E)|NewRest]) :-
    \+ (Building = B, Day = D),
    update_energy(Building, Day, Added, Rest, NewRest).

total_weekly_energy([], 0).
total_weekly_energy([usage(_B,_D,E)|Rest], Total) :-
    total_weekly_energy(Rest, Tail),
    Total is E + Tail.

daily_building_energy(Building, Day, EnergyState, Energy) :-
    current_energy(Building, Day, EnergyState, Energy).

/*
Calculates how much energy a building has left on a specific day before hitting its maximum limit.
Useful for optimization scoring (e.g., maximizing the remaining daily margin across the week).
*/
building_daily_margin(Building, Day, EnergyState, Margin) :-
    facts:building(Building, MaxDailyEnergy),
    current_energy(Building, Day, EnergyState, Current),
    Margin is MaxDailyEnergy - Current.
