include "globals.mzn";

int: n_nurse; % Number of nurses
int: n_week; % Number of weeks in our horizon
int: n_day; % Number of days in our horizon (7 * n_week). Monday is the first day of the week
int: n_work_period; % Number of work period. It equals 4 (MATIN, SOIREE, NUIT, REPOS)

% Indexing the work periods
int: MATIN = 1;
int: SOIREE = 2;
int: NUIT = 3;
int: REPOS = 4;

int: dur_work_period; % Duration of the work periods (6h)

array[1..n_day,1..n_work_period] of int: demande_min; % Number of nurses required for each day and each work period (= 0 for REPOS)
array[1..n_nurse,1..n_day,1..n_work_period] of int: preference; % Work preference for each nurse

% Decision variables
array[1..n_nurse,1..n_day,1..n_work_period] of var 0..1: x; % work period [MATIN, SOIREE, NUIT, REPOS]
var int: sum_preference;


% Meet the baseline personnel demand for every shift
constraint forall(d in 1..n_day, p in 1..n_work_period)(
    count(i in x[.., d, p])(i = 1) >= demande_min[d, p]
);

% A nurse can only one shift in a day (including the rest shift)
constraint forall(n in 1..n_nurse, d in 1..n_day)(
    1 = sum(p in 1..n_work_period)(x[n, d, p])
);

% Alternate calculation of previous constraint for safety and possibly better
% adaptability
constraint forall(n in 1..n_nurse, d in 1..n_day)(
    count(i in x[n, d, ..])(i = 1) = 1
);

% Redundancy with previous constraint for performance
constraint forall(n in 1..n_nurse)(
    sum(p in 1..n_work_period)(count(i in x[n, .., p])(i = 1)) = n_day
);

% A nurse can only work up to 36 hours in a week
constraint forall(n in 1..n_nurse, w in 1..n_week)(
    sum(p in 1..n_work_period-1)(
        count(i in x[n, (w*7-6)..(w*7), p])(i = 1) * 6
    ) <= 36
);

% A nurse must work at least 4 days a week
constraint forall(n in 1..n_nurse, w in 1..n_week)(
    sum(p in 1..n_work_period-1)(
        count(i in x[n, (w*7-6)..(w*7), p])(i = 1)
    ) >= 4
);

% State machine for stmts 7, 8, 9
int: Q = 6; int: q0 = 1; set of int: STATE = 1..Q;
array[STATE,1..n_work_period] of int: t = array2d(STATE, 1..n_work_period, [
    2, 2, 4, 5,    % state 1: start
    3, 3, 4, 5,    % state 2: one day worked in normal (day/evening) shift
    4, 4, 4, 5,    % state 3: two days worked in normal shift
    0, 0, 0, 5,    % state 4: 3 days worked normal or night shift worked
    6, 6, 0, 5,    % state 5: rested
    3, 3, 4, 0]);  % state 6: 1 day worked normal after rest

% Nurses can only be assigned certain shifts depending on their previous shifts
constraint forall(n in 1..n_nurse)(
    regular([arg_max(x[n,j,..]) | j in 1..n_day], Q, n_work_period, t, q0, STATE)
);


% Nurses must rest after a night shift (redundant with state machine for better
% performance)
constraint forall(n in 1..n_nurse, d in 2..n_day)(
    if x[n, d-1, NUIT] = 1 then
        x[n, d, REPOS] = 1
    endif
);

% Make the nurses as happy as possible :)
constraint sum_preference = sum(n in 1..n_nurse, d in 1..n_day, p in 1..n_work_period)(
    x[n, d, p] * preference[n, d, p]
);

% COIN-BC is **much** faster at solving this
solve maximize sum_preference;

output
[
  "total: " ++ show(sum_preference) ++ "\n" ++
  "solution:\n\t    "
]
++
["Day \(j)\t" | j in 1..n_day]
++ 
[ 
  if j = 1 then "\n NURSE \(i): " else "\t" endif ++
    if fix(x[i,j,4]) == 1 then "--" elseif fix(x[i,j,3]) == 1  then "NUIT" elseif fix(x[i,j,2]) == 1  then "SOIREE" elseif fix(x[i,j,1]) == 1 then "MATIN" else "NONE" endif
  | i in 1..n_nurse, j in 1..n_day
];

