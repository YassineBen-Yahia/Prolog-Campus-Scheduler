:- module(facts, [
    course/6,
    availability/2,
    room/5,
    building/2,
    slot/2,
    equipment_type/1,
    all_days/1
]).

/*
course(Course, Group, RequiredEquipment, SessionsPerWeek, Duration, Enrollment).
*/
course(ai,        g1, lab,       2, 2, 18).
course(math,      g1, board,     2, 1, 18).
course(physics,   g2, lab,       2, 2, 16).
course(english,   g2, board,     1, 1, 16).
course(databases, g3, projector, 2, 2, 25).

/*
availability(Course, AllowedSlots).
Slots are represented as slot(Day, Index).
*/
availability(ai,        [slot(mon,1), slot(mon,2), slot(mon,4), slot(tue,1), slot(tue,4), slot(wed,2)]).
availability(math,      [slot(mon,3), slot(tue,2), slot(tue,4), slot(wed,1), slot(thu,1), slot(thu,3), slot(fri,4)]).
availability(physics,   [slot(mon,1), slot(mon,3), slot(tue,1), slot(tue,3), slot(thu,2), slot(thu,4), slot(fri,2)]).
availability(english,   [slot(wed,1), slot(wed,3), slot(thu,1), slot(thu,4), slot(fri,1), slot(fri,3)]).
availability(databases, [slot(mon,2), slot(mon,4), slot(tue,3), slot(wed,2), slot(wed,4), slot(fri,3), slot(fri,4)]).

/*
room(Room, Capacity, Equipment, Building, EnergyPerSlot).
*/
room(r101, 20, board,     b1, 3).
room(r102, 30, projector, b1, 5).
room(lab1, 20, lab,       b2, 5).
room(lab2, 25, lab,       b2, 5).
room(r201, 40, projector, b3, 4).

/*
building(Building, MaxDailyEnergy).
*/
building(b1, 40).
building(b2, 45).
building(b3, 35).

/*
slot(Day, Index).
You can adapt the number of slots per day.
*/
slot(mon, 1). slot(mon, 2). slot(mon, 3). slot(mon, 4). slot(mon, 5).
slot(tue, 1). slot(tue, 2). slot(tue, 3). slot(tue, 4). slot(tue, 5).
slot(wed, 1). slot(wed, 2). slot(wed, 3). slot(wed, 4). slot(wed, 5).
slot(thu, 1). slot(thu, 2). slot(thu, 3). slot(thu, 4). slot(thu, 5).
slot(fri, 1). slot(fri, 2). slot(fri, 3). slot(fri, 4). slot(fri, 5).

equipment_type(board).
equipment_type(projector).
equipment_type(lab).

all_days([mon, tue, wed, thu, fri]).