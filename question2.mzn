include "globals.mzn"; 

int: n = 5;
% the given results
array[1..4] of int: res = [1,2,5,7];

% number of points for each player
array[1..n] of var 0..3*n: x;

% (i, j) is the result of player i against player j
array[1..n, 1..n] of var {0,1,3}: matches;

constraint forall(i in 1..n, j in 1..n)(
    if i = j then
        matches[i, j] = 0  % A player can't play against themselves
    else
        if matches[i, j] = 0 then
        % If you lose a match, then the other player wins
            matches[j, i] = 3
        else if matches[i, j] = 3 then
        % If you lose a match, then the other player loses
            matches[j, i] = 0
        else if matches[i, j] = 1 then
        % A tie is a tie for both players
            matches[j, i] = 1
        endif
        endif
        endif
    endif
);

constraint forall(i in 1..4)(
    x[i] = res[i] % Fill in the score of all the known players
);

constraint forall(i in 1..n)(
    % Cumulate the points for each player
    sum(matches[i, ..]) = x[i]
);


solve satisfy;

output 
[
  "Scores\n"
]
++
[
  show(x)
]
++	
[
  "\nMatches\n"
]
++
[ show(matches[i,j]) ++ 
         if j == n then "\n" else " " endif |
         i in 1..n, j in 1..n
]
;
