:- module(constraints, [
    valid_assignment/6
]).

:- use_module(facts).
:- use_module(utils).
:- use_module(energy).

/*
valid_assignment(+Task, +Room, +Day, +StartSlot, +PartialSchedule, +EnergyState)

Task = task(Course, SessionIndex, Group, Equip, Duration, Enrollment)
*/
valid_assignment(
    task(Course, _SessionIndex, Group, _Equip, Duration, _Enrollment),
    Room,
    Day,
    StartSlot,
    PartialSchedule,
    EnergyState
) :-
    teacher_available(Course, Day, StartSlot),
    room_free(Room, Day, StartSlot, Duration, PartialSchedule),
    group_free(Group, Day, StartSlot, Duration, PartialSchedule),
    course_spread_ok(Course, Day, PartialSchedule),
    energy:energy_ok(Room, Day, Duration, EnergyState).

teacher_available(Course, Day, StartSlot) :-
    facts:availability(Course, Slots),
    utils:member_slot(slot(Day, StartSlot), Slots).

room_free(_Room, _Day, _Start, _Dur, []).
room_free(Room, Day, Start, Dur, [assign(_Course,_S,Room2,Day2,Start2,Dur2)|Rest]) :-
    \+ (
        Room = Room2,
        Day = Day2,
        utils:overlaps(Start, Dur, Start2, Dur2)
    ),
    room_free(Room, Day, Start, Dur, Rest).

group_free(_Group, _Day, _Start, _Dur, []).
group_free(Group, Day, Start, Dur, [assign(Course2,_S,_Room2,Day2,Start2,Dur2)|Rest]) :-
    facts:course(Course2, Group2, _Equip2, _SPW2, _Dur2Facts, _E2),
    \+ (
        Group = Group2,
        Day = Day2,
        utils:overlaps(Start, Dur, Start2, Dur2)
    ),
    group_free(Group, Day, Start, Dur, Rest).

/*
Safety Warning:
If a course has N sessions per week, it MUST be available on at least N distinct days 
for this constraint to be satisfiable. Otherwise, finding a completely valid schedule 
will quietly fail!
*/
course_spread_ok(_Course, _Day, []).
course_spread_ok(Course, Day, [assign(Course2,_S,_Room2,Day2,_Start2,_Dur2)|Rest]) :-
    \+ (
        Course = Course2,
        Day = Day2
    ),
    course_spread_ok(Course, Day, Rest).
