function GenTrialVectors
%   Function outputs trial vectors (U, product of crossover).

global filename numFact numDose numComb sheetname vectorState countVectors
global mutCon crossCon
global XdoseRangeR UdoseRangeW VectorSet

%   Generate a matrix R that contains r1, r2, r3 for the mutation of the
%   target vector (X).
disp('Generating trial vectors...');
R = randsrc(3,numComb,1:numComb);
for i = 1:numComb
    A = R(:,i);
    [~,~,c] = unique(A);
    idx = c == 3; % if column vector elements all unique, idx contains 1
    
    while ~any(idx)
        Rtemp = randsrc(3,1,1:numComb);        
        A = Rtemp(:,1);
        [~,~,c] = unique(A);
        idx = c == 3; % if column vector elements all unique, idx contains 1
        if ~any(idx) == 0
            R(:,i) = Rtemp(:,1);
        end
    end
    
    while ismember(i,A)
        if ismember(i,A)
            %   For every element in matrix R, the element should not be
            %   equal to the column number of the cell index of the
            %   element. The matrix R should not consist of any replicated
            %   elements.
            idx = find(A==i,1,'first');
            A(idx,1) = randsrc(1,1,1:numComb);
        elseif A(1,1) == A(2,1)
            A(1,1) = randsrc(1,1,1:numComb);
        elseif A(2,1) == A(3,1)
            A(2,1) = randsrc(1,1,1:numComb);
        elseif A(1,1) == A(3,1)
            A(3,1) = randsrc(1,1,1:numComb);
        end
    end
    R(:,i) = A;
end

%   Generate the donor vector (V) using X and R.
X = xlsread(filename,sheetname,XdoseRangeR);
V = NaN(numFact,numComb);
for i = 1:numComb
    r1 = R(1,i);
    r2 = R(2,i);
    r3 = R(3,i);
    V(:,i) = X(:,r1)+mutCon*(X(:,r2)-X(:,r3));
end

%   Perform cross-over to generate trial vectors (U).
C = rand(numFact,numComb);
U = NaN(numFact,numComb);
for i = 1:numFact
    for j = 1:numComb
        if C(i,j) <= crossCon
            U(i,j) = V(i,j);
        else
            U(i,j) = X(i,j);
        end
        
        %   Convert the concentrations to the coded dose level indicators.
        if U(i,j) < 0
            U(i,j) = 0;
        elseif U(i,j) > numDose(i,1)-1
            U(i,j) = numDose(i,1)-1;
        else
            U(i,j) = round(U(i,j));
        end
    end
end

%   Check for repeated vectors.
for i=1:numComb
    vectorState = 0;
    CheckDuplicate(U(:,i),i);
    countVectors = countVectors + 1;
end

vectorState = [];
VectorSet = [VectorSet U];
xlswrite(filename,U,sheetname,UdoseRangeW);
disp('Completed generating trial vectors.');