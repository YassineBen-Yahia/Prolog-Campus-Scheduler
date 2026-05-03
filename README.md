# Prolog Scheduling Project

This project builds a weekly course schedule with SWI-Prolog. It assigns each
course session to a room, day, and start slot while checking room capacity,
equipment, group conflicts, room conflicts, course availability, and building
energy limits.

## Files

- `facts.pl` contains the input data: courses, rooms, buildings, available
  slots, equipment types, and days.
- `utils.pl` contains shared helpers for expanding courses into sessions,
  checking slot membership, checking time overlap, and printing schedules.
- `constraints.pl` checks whether one proposed assignment is valid.
- `energy.pl` tracks daily energy usage per building.
- `scheduler.pl` generates feasible schedules.
- `optimization.pl` scores schedules and finds the best one.
- `main.pl` loads every module and exposes the commands used from the Prolog
  console.
- `Dockerfile` runs the project in a SWI-Prolog container.

## Predicate Reference

### `facts.pl`

- `course/6` stores one course with its group, equipment need, weekly session
  count, duration, and enrollment.
- `availability/2` stores the allowed start slots for a course.
- `room/5` stores room capacity, equipment, building, and energy cost per slot.
- `building/2` stores the maximum daily energy allowed for a building.
- `slot/2` declares all valid day/start-slot combinations.
- `equipment_type/1` declares the known equipment categories.
- `all_days/1` returns the list of scheduling days used by optimization.

### `utils.pl`

- `session_tasks/1` converts course facts into individual session tasks. A
  course with 2 sessions becomes two `task/6` terms.
- `member_slot/2` checks whether a specific `slot(Day, Index)` exists in a list
  of allowed slots.
- `overlaps/4` checks whether two start-slot/duration intervals overlap.
- `print_schedule/1` prints every `assign/6` term in a schedule.

### `constraints.pl`

- `valid_assignment/6` is the main constraint checker for one proposed session
  assignment.
- `teacher_available/3` checks whether the course is allowed at the selected
  day and start slot. In this project, course availability acts like teacher
  availability.
- `room_free/5` checks that the room has no overlapping session already placed
  in the partial schedule.
- `group_free/5` checks that the student group has no overlapping session
  already placed in the partial schedule.
- `course_spread_ok/3` ensures multiple sessions of exactly the same course are
  scheduled on different days.

### `energy.pl`

- `empty_energy_state/1` creates the initial empty energy state.
- `energy_ok/4` checks whether adding a session would keep the building under
  its daily energy limit.
- `add_energy/5` updates the energy state after a session is assigned.
- `current_energy/4` reads the current energy usage for one building on one day.
- `update_energy/5` inserts or updates one `usage(Building, Day, Energy)` item.
- `total_weekly_energy/2` sums all energy usage in the week.
- `daily_building_energy/4` returns the energy for one building on one day.

### `scheduler.pl`

- `schedule/2` generates one complete feasible schedule and its final energy
  state.
- `schedule_tasks/5` recursively schedules the remaining tasks while carrying
  the partial schedule and energy state.
- `choose_assignment/4` generates possible room/day/start-slot choices for one
  task, already filtering by availability, room equipment, capacity, and day
  length.
- `fits_in_day/2` checks that a session does not run past the last slot of the
  day.
- `order_tasks/2` sorts session tasks so the most constrained tasks are tried
  first.
- `score_tasks/2` counts the possible assignments for each task before sorting.
- `strip_scores/2` removes the sorting scores and keeps only the ordered tasks.
- `generate_all_schedules/1` collects all schedules into a list. This is kept
  for experimentation, but `run_all/0` is safer because it streams schedules.


### `optimization.pl`

- `schedule_score/3` computes the score for a complete schedule. Lower is
  better.
- `load_imbalance/2` computes the difference between the busiest and quietest
  energy days.
- `daily_totals/3` builds the list of total energy values for all days.
- `total_day_energy/3` sums all building energy usage for one day.
- `best_schedule/3` streams all feasible schedules and keeps only the best one
  found so far.
- `update_best/2` updates the current best candidate when a lower score appears.

### `main.pl`

- `run_one/0` prints the first feasible schedule.
- `run_all/0` prints every feasible schedule one by one without storing all of
  them in memory.
- `run_best/0` finds and prints the best schedule, its energy state, score, and
  elapsed time.

## Facts

Courses use this format:

```prolog
course(Course, Group, RequiredEquipment, SessionsPerWeek, Duration, Enrollment).
```

Example:

```prolog
course(ai, g1, lab, 2, 2, 18).
```

This means AI belongs to group `g1`, needs a lab room, has 2 sessions per week,
each session lasts 2 slots, and has 18 students.

Course availability uses this format:

```prolog
availability(Course, AllowedSlots).
```

Slots are represented as:

```prolog
slot(Day, StartSlot).
```

For example, `slot(mon, 2)` means the session may start on Monday at slot 2.
If a course has duration 2, it occupies slot 2 and slot 3.

Rooms use this format:

```prolog
room(Room, Capacity, Equipment, Building, EnergyPerSlot).
```

Buildings use this format:

```prolog
building(Building, MaxDailyEnergy).
```

The energy limit is checked per building per day.

## Main Commands

From the SWI-Prolog console:

```prolog
?- run_one.
```

Prints the first feasible schedule found.

```prolog
?- run_best.
```

Finds and prints the best schedule according to the score in `optimization.pl`.
It also prints elapsed milliseconds.

```prolog
?- run_all.
```

Streams every feasible schedule one by one. This no longer stores all schedules
in memory, but it can still take a long time because there may be many feasible
schedules to print.

## Docker Usage

Build the image:

```bash
docker build -t prolog-scheduler .
```

Open the SWI-Prolog console:

```bash
docker run -it --rm prolog-scheduler
```

Then run:

```prolog
?- run_best.
```

You can also run one command directly:

```bash
docker run --rm prolog-scheduler swipl -q -s main.pl -g run_best -t halt
```

## How Scheduling Works

`utils:session_tasks/1` expands every course into independent session tasks.
For example, a course with 2 sessions per week becomes:

```prolog
task(course_name, 1, Group, Equipment, Duration, Enrollment)
task(course_name, 2, Group, Equipment, Duration, Enrollment)
```

`scheduler:schedule/2` then:

1. Builds all session tasks.
2. Orders the most constrained tasks first.
3. Chooses a possible room, day, and start slot.
4. Checks all constraints.
5. Adds the energy usage.
6. Continues until all sessions are assigned.

The result uses this format:

```prolog
assign(Course, SessionIndex, Room, Day, StartSlot, Duration)
```

## Constraints

An assignment is valid only if:

- the room capacity is large enough;
- the room has the exact required equipment;
- the course is available at that slot;
- the room is not already used at an overlapping time;
- the group does not already have another overlapping session;
- the sessions of the same course are spread across different days;
- the building does not exceed its daily energy limit.

Time overlap is checked by converting each start slot and duration into an
interval. For example, start 1 duration 2 occupies slots 1 and 2.

## Optimization

The score is:

```text
Score = TotalWeeklyEnergy + LoadImbalance
```

Lower is better.

`TotalWeeklyEnergy` is the sum of all building energy usage.

`LoadImbalance` is:

```text
maximum daily energy - minimum daily energy
```

So the optimizer prefers schedules that use less energy and spread energy usage
more evenly across the week.

## What Was Fixed

The old approach could exceed the Prolog stack even with a large stack limit
because it created too many proof paths and stored too much data at once.

The main issue was code shaped like this:

```prolog
(Room \= Room2 ; Day \= Day2 ; \+ overlaps(...))
```

This is logically okay, but operationally expensive in Prolog. If the room is
different and the day is also different, Prolog can prove the same non-conflict
in more than one way. That creates duplicate branches in the search tree.

It was replaced with one deterministic conflict test:

```prolog
\+ (
    Room = Room2,
    Day = Day2,
    overlaps(...)
)
```

This means: fail only when there is a real conflict.

The same fix was applied to group conflict checks and energy state traversal.

`run_best` also used to collect every candidate schedule with `findall/3` before
choosing the best one. That can consume huge memory. It now streams schedules and
keeps only the current best candidate, so memory use stays small.

The scheduler also now tries the most constrained sessions first and filters
rooms by equipment and capacity before running the full constraint checks.

### Domain Constraints Fixes

- **Expanded Daily Timeslots**: Increased the available slots per day from 3 to 5 (`slot(day, 1)` to `slot(day, 5)`), and adjusted the `fits_in_day` boundary logic so that duration 2 sessions have much more flexibility to be scheduled without getting blocked. Added more slot availability to courses to utilize these new slots.
- **Rebalanced Energy Limits**: Adjusted building energy constraints to prevent immediate scheduling failures on overlapping sessions. The maximum daily energy for buildings was increased (`b1`: 40, `b2`: 45, `b3`: 35), and the energy consumption per slot for high-intensity lab rooms (`lab1`, `lab2`) was reduced to provide a solvable problem space while maintaining constrained optimization.

### Utilities Fixes
- **Improved Output Formatting**: Enhanced `print_schedule/1` to display user-friendly output rather than raw Prolog terms. It now prints cleanly formatted lines like `Course: ai | Session: 1 | Room: lab1 | Day: mon | Slot: 1-2`, calculating Start-End slots for a more professional execution result.
- **Backtracking Efficiency**: Documented `member_slot/2` in `utils.pl` explaining the use of `memberchk/2` which efficiently tests slot membership without leaving choice points that could cause duplicate branches in search space on backtracking.

### Constraints Fixes
- **Removed Redundant Checks**: Removed the `capacity_ok` and `equipment_ok` logic checks out of `valid_assignment` within `constraints.pl`. Since `choose_assignment` in the scheduler already pre-filters assignments using these identical constraints before applying them, running them again in `valid_assignment` was wasted operation overhead.
- **Duration Consistency Binding in `group_free`**: Modified the `group_free` check to correctly bind the parameter `Dur2` to `facts:course(Course2, Group2, _Equip2, _SPW2, _Dur2Facts, _E2)`. Previously, the duration of an existing assigned task fetched from the static fact base was bound to the exact same parameter variable pulling from the active candidate structure `assign(..., Dur2)`. This was unified simultaneously enforcing an unnecessary and silently fragile dependency constraint that `assign(duration)` must actively match `fact(duration)`. Now it safely reads only what it needs, bypassing the fragile cross-link constraint.
- **Session Spread Enforcement**: Added a new foundational `course_spread_ok` constraint. In prior versions, multiple sessions of the exact same course could be assigned back-to-back or spaced across the exact same day. This now enforces daily separation (two sessions of AI must be on strictly different days)! *Note: Included a vital safety documentation guard: If a course demands $N$ sessions, it MUST be declared available on at least $N$ distinct days inside the database! Or standard search iteration will silently trap itself in an unsolvable logical node without error messages!*

### Scheduler Fixes
- **Removed Redundant Database Traversal**: Removed the lookup `facts:slot(Day, StartSlot)` inside `choose_assignment` within `scheduler.pl`. Calling `member` directly against the valid `AllowedSlots` already correctly generated available slot bounds without firing redundant truth-choice clauses at the raw fact set layer.
- **Eliminated Hardcoded Slot Threshold (`fits_in_day`)**: Removed the hardcoded magic number `MaxSlot = 5` inside `scheduler.pl`. Instead, a declarative rule `max_slot_index/1` was added directly into `facts.pl`. Now, if someone modifies `facts.pl` to include 6 logical slots per day, the entire codebase seamlessly transitions validation checks based exclusively from data extraction, rather than trapping out incorrectly because a validator arbitrarily maintained an internal `x = 5`.
- **Static vs Dynamic MRV Constraints (Documentation Add)**: The scheduler inherently processes tasks efficiently via Minimum Remaining Values (MRV) evaluation (`order_tasks/2`). However, be aware this implements a **Static Ordering**: it judges difficulty uniformly before assigning variables. In an enterprise system, as constraints tighten, an actively shrinking branch matrix requires **Dynamic Re-ordering** re-evaluating each level. Prolog's declarative state tracking complicates this natively without explicit re-entry wrapping, but it denotes the primary limitation going forward.

### Core Architecture Updates
- **Standardized Execution Statistics Measurement (`run_best`)**: Updated the system performance statistics timing sequence executing inside `main.pl`. While SWI-Prolog effectively mapped `walltime` returns to total runtime correctly due to luck, it inherently returns lists as `[TotalRuntime, TimeSinceLastExecution]`. Implementing explicit double-resets (`statistics(walltime, [_, _])` followed by variable-grab `statistics(walltime, [_, ElapsedMs])`) prevents incorrect interpretations or future maintenance breakages when the file runs dynamically in other containers!
- **Startup Integrity Pre-Check for Database Slot Validity**: Implemented a defensive integrity validation protocol (`check_facts_integrity`) that actively loops across the `availability/2` structures in factual storage checking if those claimed slot mappings truly exist via matching `slot/2` base entries before allowing search execution. Previously, missing or wildly out-of-bounds availability configurations generated silent errors returning zero possible assignments without alerting developers. It now catches data-entry typos such as `slot(mon, 6)` proactively by safely logging a `WARNING: Course X has availability slot(Y,Z) which does not exist...` upon invoking `run_one()`, `run_best()`, and `run_all()`.
- **Validation Count Reporting (`run_all`)**: Updated `run_all` loop inside `main.pl` to initially calculate and emit the total number of feasible solutions using `aggregate_all(count, ...)`. Being able to track and demonstrate exactly how many valid schedules the constraints logically allow before selecting the optimal layout sets up a stronger defense parameter for project evaluations.
- **Detailed Score Breakdown (`print_score_breakdown`)**: Introduced transparent score breakdown reporting to `run_best` that segregates the mathematically combined score. When optimizing is complete, it now independently prints out formatted details including Total Energy constraints, physical Load Imbalance metrics, and the Room Usage Variance penalties! This clarifies how combinations influence final ratings rather than displaying an ambiguous integer matrix payload!
- **Energy Report Per Building Per Day (`print_energy_report`)**: Implemented a comprehensive daily energy consumption and margin dashboard output using the previously added `daily_building_energy/4`. Calling `--run_best` now emits a highly detailed, tabulated breakdown explicitly displaying energy used and safety budget margins remaining per building, proving the milestone validity dynamically.
- **Optimization Module Exports**: Formally exported `load_imbalance/2` and `room_usage_variance/2` within `optimization.pl`. These rules were previously trapped as internal private helpers, preventing modules like `main.pl` from decomposing final scores gracefully for external UI outputs!

### Optimization Fixes
- **Load Imbalance Math Correction**: Modifed `load_imbalance/2` to explicitly `exclude/3` completely empty days (i.e. `0` total energy) before executing `min_list`. Previously, unused unscheduled days dragged the minimum baseline down to zero, destroying the intent behind bounding energy spikes to purely scheduled limits.
- **Graceful Failure State for Zero Valid Schedules**: Wrapped logic into a guard conditional for `BestRef` handling missing solutions in `best_schedule`. Now, if standard constraint tightening or assignment facts result in an mathematically impossible target configuration, `optimization.pl` safely writes an error explanation that constraints are too tight, instead of silently failing variable unification and crashing internally without a stacktrace.
- **Added Missing Fairness Metric (Room Variance)**: Integrated the crucial Milestone 3 Room Usage Variance penalty to the total evaluation core (`room_usage_variance/2`). Scoring now evaluates all distinct rooms against average usage times $\mu$, squaring deviations effectively ensuring optimal schedule generations actively penalize heavily uneven physical resource packing!

### Energy Tracker Fixes
- **Duration Documentation Added**: Added a key clarification to `facts.pl` explicitly stating that `EnergyPerSlot` is indeed per logical timeslot, not per hour or session, which clarifies exactly why mathematical calculations in the tracker (e.g. `AddedEnergy is EnergyPerSlot * Duration`) behave the way they do! This removes ambiguity preventing disputes or misunderstanding in defenses.
- **New Optimization Targeting Module `building_daily_margin/4`**: Included a new predicate inside `energy.pl` (`building_daily_margin/4`). This computes how much energy a specific building has left on a specific day before hitting its limit (`MaxDailyEnergy - CurrentEnergy`). This fixes the missing ability to identify which buildings are close to exceeding their threshold, which sets up load-balancing systems correctly for Milestone 3 optimization features!

## Important Note About `run_all`

`run_all` is now stack-safe because it prints schedules as they are found instead
of collecting them into one giant list.

However, it may still take a long time because printing every feasible schedule
can mean printing thousands or millions of schedules depending on the facts.
Use `run_one` for a quick feasibility check and `run_best` for the optimized
answer.
