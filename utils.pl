:- module(utils, [
    session_tasks/1,
    member_slot/2,
    overlaps/4,
    print_schedule/1
]).

:- use_module(facts).

/*
Convert courses into independent session tasks:
task(Course, SessionIndex, Group, RequiredEquipment, Duration, Enrollment)
*/
session_tasks(Tasks) :-
    findall(
        task(Course, SessionIdx, Group, Equip, Duration, Enrollment),
        (
            facts:course(Course, Group, Equip, SessionsPerWeek, Duration, Enrollment),
            between(1, SessionsPerWeek, SessionIdx)
        ),
        Tasks
    ).

/*
member_slot uses memberchk to efficiently test membership.
This prevents Prolog from backtracking and generating duplicate solutions if a slot happens to be listed multiple times.
*/
member_slot(Slot, Slots) :-
    memberchk(Slot, Slots).

/*
Two intervals overlap on same day if: 
Start1 <= End2 and Start2 <= End1
Slots are discrete and duration-based.
*/
overlaps(Start1, Dur1, Start2, Dur2) :-
    End1 is Start1 + Dur1 - 1,
    End2 is Start2 + Dur2 - 1,
    Start1 =< End2,
    Start2 =< End1.

/*
Pretty print
Assignment format:
assign(Course, SessionIndex, Room, Day, StartSlot, Duration)
*/
print_schedule([]).
print_schedule([assign(Course,S,Room,Day,Start,Dur)|Rest]) :-
    End is Start + Dur - 1,
    format('Course: ~w | Session: ~w | Room: ~w | Day: ~w | Slot: ~w-~w~n', [Course, S, Room, Day, Start, End]),
    print_schedule(Rest).
