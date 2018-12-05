function TrialVector = miniGenTrialVectors(vecPosition)
%   Function outputs trial vectors (U, product of crossover).

global filename numFact numDose numComb sheetname mutCon crossCon
global XdoseRangeR

idx = false;

%   Generate a matrix R that contains r1, r2, r3 for the mutation of the
%   target vector (X).
while ~any(idx)
    R = randsrc(3,1,1:numComb);
    A = R(:,1);
    [~,~,c] = unique(A);
    idx = c == 3; % if column vector elements all unique, idx contains 1
end

while ismember(vecPosition,A)
    if ismember(vecPosition,A)
        %   For every element in matrix R, the element should not be
        %   equal to the column number of the cell index of the
        %   element. The matrix R should not consist of any replicated
        %   elements.
        idx = find(A==vecPosition,1,'first');
        A(idx,1) = randsrc(1,1,1:numComb);
    elseif A(1,1) == A(2,1)
        A(1,1) = randsrc(1,1,1:numComb);
    elseif A(2,1) == A(3,1)
        A(2,1) = randsrc(1,1,1:numComb);
    elseif A(1,1) == A(3,1)
        A(3,1) = randsrc(1,1,1:numComb);
    end
end
R(:,1) = A;

%   Generate the donor vector (V) using X and R.
X = xlsread(filename,sheetname,XdoseRangeR);
V = NaN(numFact,1);

r1 = R(1,1);
r2 = R(2,1);
r3 = R(3,1);
V(:,1) = X(:,r1)+mutCon*(X(:,r2)-X(:,r3));

%   Perform cross-over to generate trial vectors (U).
C = rand(numFact,1);
U = NaN(numFact,1);
for i = 1:numFact
    if C(i,1) <= crossCon
        U(i,1) = V(i,1);
    else
        U(i,1) = X(i,1);
    end
    
    %   Convert the concentrations to the coded dose level indicators.
    if U(i,1) < 0
        U(i,1) = 0;
    elseif U(i,1) > numDose(i,1)-1
        U(i,1) = numDose(i,1)-1;
    else
        U(i,1) = round(U(i,1));
    end
end

TrialVector = U;