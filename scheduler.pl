:- module(scheduler, [
    schedule/2,
    generate_all_schedules/1
]).

:- use_module(facts).
:- use_module(utils).
:- use_module(constraints).
:- use_module(energy).

/*
schedule(-Schedule, -EnergyState)
*/
schedule(Schedule, EnergyState) :-
    utils:session_tasks(UnorderedTasks),
    order_tasks(UnorderedTasks, Tasks),
    energy:empty_energy_state(EmptyState),
    schedule_tasks(Tasks, [], Schedule, EmptyState, EnergyState).

schedule_tasks([], AccSchedule, Schedule, EnergyState, EnergyState) :-
    reverse(AccSchedule, Schedule).
schedule_tasks([Task|Rest], AccSchedule, FinalSchedule, AccEnergy, FinalEnergy) :-
    choose_assignment(Task, Room, Day, StartSlot),
    constraints:valid_assignment(Task, Room, Day, StartSlot, AccSchedule, AccEnergy),
    Task = task(Course, SessionIndex, _Group, _Equip, Duration, _Enrollment),
    energy:add_energy(Room, Day, Duration, AccEnergy, NewEnergy),
    schedule_tasks(
        Rest,
        [assign(Course, SessionIndex, Room, Day, StartSlot, Duration)|AccSchedule],
        FinalSchedule,
        NewEnergy,
        FinalEnergy
    ).

/*
Possible assignments are generated from facts.
*/
choose_assignment(task(Course, _SessionIndex, _Group, Equip, Duration, Enrollment), Room, Day, StartSlot) :-
    facts:availability(Course, AllowedSlots),
    member(slot(Day, StartSlot), AllowedSlots),
    fits_in_day(StartSlot, Duration),
    facts:room(Room, Capacity, Equip, _Building, _Energy),
    Capacity >= Enrollment.

/*
Ensure a session assignment starts and finishes strictly within the max slot range of the day.
*/
fits_in_day(StartSlot, Duration) :-
    facts:max_slot_index(MaxSlot),
    EndSlot is StartSlot + Duration - 1,
    EndSlot =< MaxSlot.

/*
Schedule the most constrained sessions first. This cuts failed branches early.
*/
order_tasks(Tasks, OrderedTasks) :-
    score_tasks(Tasks, ScoredTasks),
    keysort(ScoredTasks, SortedTasks),
    strip_scores(SortedTasks, OrderedTasks).

score_tasks([], []).
score_tasks([Task|Rest], [Count-Task|ScoredRest]) :-
    findall(
        assignment(Room, Day, StartSlot),
        choose_assignment(Task, Room, Day, StartSlot),
        Assignments
    ),
    length(Assignments, Count),
    score_tasks(Rest, ScoredRest).

strip_scores([], []).
strip_scores([_Count-Task|Rest], [Task|Tasks]) :-
    strip_scores(Rest, Tasks).

generate_all_schedules(Schedules) :-
    findall(
        result(Schedule, EnergyState),
        schedule(Schedule, EnergyState),
        Schedules
    ).
