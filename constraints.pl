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
    task(Course, _SessionIndex, Group, Equip, Duration, Enrollment),
    Room,
    Day,
    StartSlot,
    PartialSchedule,
    EnergyState
) :-
    capacity_ok(Enrollment, Room),
    equipment_ok(Equip, Room),
    teacher_available(Course, Day, StartSlot),
    room_free(Room, Day, StartSlot, Duration, PartialSchedule),
    group_free(Group, Day, StartSlot, Duration, PartialSchedule),
    energy:energy_ok(Room, Day, Duration, EnergyState).

capacity_ok(Enrollment, Room) :-
    facts:room(Room, Capacity, _Equip, _Building, _Energy),
    Capacity >= Enrollment.

equipment_ok(RequiredEquip, Room) :-
    facts:room(Room, _Capacity, RoomEquip, _Building, _Energy),
    RoomEquip = RequiredEquip.

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
    facts:course(Course2, Group2, _Equip2, _SPW2, _D2, _E2),
    \+ (
        Group = Group2,
        Day = Day2,
        utils:overlaps(Start, Dur, Start2, Dur2)
    ),
    group_free(Group, Day, Start, Dur, Rest).
