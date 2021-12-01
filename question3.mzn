include "globals.mzn"; 

int: n; % num rows and columns

int: L = 1; % Lamp
int: P = 2; % Plant

% 1 for a lamp, 2 for a plant and 0 for nothing 
array[1..n,1..n] of 0..2: garden;

% number of plants by row/col
array[1..n] of int: rows;
array[1..n] of int: cols;

% decision variables
array[1..n,1..n] of var 0..P: x;
    

constraint forall(i in 1..n)(
    count_eq(x[i, ..], P, rows[i]) /\
    count_eq(x[.., i], P, cols[i])
);


% There are lamps where the plan says there are lamps, and nowhere else.
constraint forall(i in 1..n, j in 1..n where garden[i, j] = L)(
    x[i, j] = L
);
constraint forall(i in 1..n, j in 1..n where garden[i, j] != L)(
        x[i, j] != L
);

% Keep plants away from each other
predicate no_plants_over_under(array[1..n,1..n] of var 0..P: x, int: i, int: j) =
        if j > 1 then
            x[i, j - 1] != P
        endif /\
        if j < n then
            x[i, j + 1] != P
        endif;

constraint forall(i in 1..n, j in 1..n where x[i, j] = P)(
    no_plants_over_under(x, i, j) /\
    if i > 1 then
        x[i - 1, j] != P /\
        no_plants_over_under(x, i - 1, j)
    endif /\
    if i < n then
        x[i + 1, j] != P /\
        no_plants_over_under(x, i + 1, j)
    endif
);

% Make sure each plant has a lamp
constraint forall(i in 2..n-1, j in 2..n-1 where x[i, j] = P)(
    % Check all plants not on edges
    member([x[i-1, j], x[i+1, j], x[i, j-1], x[i, j+1]], L)
);

% Check plants on edges
constraint forall(i in 2..n-1 where x[i, 1] = P)(
    member([x[i-1, 1], x[i+1, 1], x[i, 1+1]], L)
);

constraint forall(i in 2..n-1 where x[i, n] = P)(
    member([x[i-1, n], x[i+1, n], x[i, n-1]], L)
);

constraint forall(i in 2..n-1 where x[1, i] = P)(
    member([x[1, i-1], x[1, i+1], x[1+1, i]], L)
);

constraint forall(i in 2..n-1 where x[n, i] = P)(
    member([x[n, i-1], x[n, i+1], x[n-1, i]], L)
);

%Check plants in corners
constraint
    if x[1, 1] = P then
        member([x[1+1, 1], x[1, 1+1]], L)
    else
        true
    endif;

constraint
    if x[n, 1] = P then
        member([x[n-1, 1], x[n, 1+1]], L)
    else
        true
    endif;

constraint
    if x[n, n] = P then
        member([x[n-1, n], x[n, n-1]], L)
    else
        true
    endif;

constraint
    if x[1, n] = P then
        member([x[1+1, n], x[1, n-1]], L)
    else
        true
    endif;

% Make sure each lamp has a plant
constraint forall(i in 2..n-1, j in 2..n-1 where x[i, j] = L)(
    % Check all lamps not on edges
    member([x[i-1, j], x[i+1, j], x[i, j-1], x[i, j+1]], P)
);

% Check lamps on edges
constraint forall(i in 2..n-1 where x[i, 1] = L)(
    member([x[i-1, 1], x[i+1, 1], x[i, 1+1]], P)
);

constraint forall(i in 2..n-1 where x[i, n] = L)(
    member([x[i-1, n], x[i+1, n], x[i, n-1]], P)
);

constraint forall(i in 2..n-1 where x[1, i] = L)(
    member([x[1, i-1], x[1, i+1], x[1+1, i]], P)
);

constraint forall(i in 2..n-1 where x[n, i] = L)(
    member([x[n, i-1], x[n, i+1], x[n-1, i]], P)
);

%Check lamps in corners
constraint
    if x[1, 1] = L then
        member([x[1+1, 1], x[1, 1+1]], P)
    else
        true
    endif;

constraint
    if x[n, 1] = L then
        member([x[n-1, 1], x[n, 1+1]], P)
    else
        true
    endif;

constraint
    if x[n, n] = L then
        member([x[n-1, n], x[n, n-1]], P)
    else
        true
    endif;

constraint
    if x[1, n] = L then
        member([x[1+1, n], x[1, n-1]], P)
    else
        true
    endif;

solve satisfy;

output 
[
 if j = 1 then "\n" ++ show(rows[i]) ++ " " else " " endif ++
   if fix(x[i,j]) = L then "L" elseif fix(x[i,j]) = P then "P" else "_" endif
| i,j in 1..n
] ++ ["\n  "] ++ [show(cols[i]) ++ " " | i in 1..n];
