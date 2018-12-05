function result = OptimProblem(M)

%   Function evaluates the performance result of a single combination from
%   the set of target (X) and trial (U) vectors according to the objective
%   function defined here. The variability in the datapoints is generated
%   by the pre-defined intra- and inter-experimental variability values
%   (intraVarComb & interVarComb).

%   Input vector (M) is a column vector [x1, x2, .., xn] where xi
%   correspond to doses for factors assigned to each index/row position of
%   the vector.
%   -----> can be vectorized such that each xi is a vector
%   -----> will need to vectorize EvalComb code to vector operations
%   instead of for loop + vectorize for loop summation oprations for each
%   function here

global benchmarkName

D = length(M);
sum = 0;

% -----------------------------------------------------------------------
%   benchmarkName:
%   rosenbrock        'rb'
% -----------------------------------------------------------------------

if strcmp(benchmarkName,'rb')
    %   BENCHMARK FUNCTION TO TEST: ______ ROSENBROCK ______
    xshift = 2;
    yshift = 5000;
    for i=1:(D-1)
        xi = M(i) - xshift;
        xnext = M(i+1) - xshift;
        new = 100*(xnext-xi^2)^2 + (xi-1)^2;
        new = -1*new;   % flip  minimization to maximization
        new = new/1000; % reduce scale
        sum = sum + new;
    end
    sum = sum + yshift; % shift function up on y-axis
else
    %   BENCHMARK FUNCTION TO TEST: ______ (name) ______
end

result = sum;