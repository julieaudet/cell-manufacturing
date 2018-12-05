function GenTargetVectors
%   Function outputs target vectors (X, orginial combinations for first
%   generation).

%   Define global and persistent variables.
global run filename numFact numDose numComb sheetname vectorState q ps
global countVectors genFirstPop firstGenStat quasiStop CarryScore
global TabuList SelectedVectors quasiMethod VectorSet XlogScoreR
global XdoseRangeR XdoseRangeW UdoseRangeR SelectionRangeR UlogScoreR
X2 = NaN(numFact,numComb);

disp('Generating target vectors...');
if run == 1
    X = [];
    if strcmp(genFirstPop,'r')
        %   Generate target vectors by assigning randomly generate coded
        %   dose level indicators for each factor over the total number of
        %   combinations being investigaved in each run.
        for i=1:numFact
            AddToX = randsrc(1,numComb,0:numDose(i,1)-1);
            X = [X; AddToX];
        end
        for i=1:numComb
            vectorState = 1;
            X(:,i) = CheckDuplicate(X(:,i),i);
            countVectors = countVectors + 1;
        end
    elseif strcmp(genFirstPop,'d')
        %   Generate target vectors in a quasi-random manner such that
        %   combinations are distributed evenly over the solution space.
        
        %   ------      option 1
        %   Generate population size number of quasi-random vectors over
        %   unit space using haltonset. Elements are assigned [0,1] at
        %   intervals of 0.1.
        C = [];
        if strcmp(quasiMethod,'h')
            %   ------      option 2
            %   Generate sufficiently large pool of quasi-random vectors
            %   over unit space using haltonset.
            p = haltonset(numFact);
            ps = scramble(p,'RR2');
        elseif strcmp(quasiMethod,'s')
            %   Generate quasi-random sequence using sobolset.
            p = sobolset(numFact);
            ps = scramble(p,'MatousekAffineOwen');
        end
        for n=1:length(p)/5e+06
            %   Call scrambled quasi-random vector sequences in batched
            %   (due to memory resitrictions).
            if n == 1
                addC = ps(1:n*1e+05,:);
            else
                addC = ps((n-1)*1e+05+1:n*1e+05,:);
            end
            addC = addC*10;
            addC = round(addC);
            addC = unique(addC,'rows');
            
            %   The matrix of scatter coordinates are resized according to
            %   the number of doses available for each factor.
            for i=1:numFact
                idx = addC(:,i) > numDose(i,1)-1;
                addC(idx,:) = [];
            end
            
            %   Eliminate coordinates with more than half of the factors at
            %   zero.
            addC((sum(addC == 0,2) > numFact/2),:) = [];
            C = [C; addC];
            addC = [];
            
            %   Delete any duplicate row vectors.
            C = unique(C,'rows');
            [r,~] = size(C);
            
            %   If sufficient number of unique vectors generated, stop.
            if r > numComb
                quasiStop = n; break
            end
        end
        
        %   Select required number of vectors from pool.
        numDel = transpose(randperm(r,r-numComb));
        X1 = removerows(C,'ind',numDel);
        q = 1;
        X = X1(randperm(numComb),:);
        X = transpose(X);
        countVectors = numComb;
        TabuList = transpose(X);
    end
elseif strcmp(genFirstPop,'d') && run > 1 && firstGenStat == 0
    disp('GenTargetVectors 98: quasi-random generation repeat');
    q = q+1;
    C = [];
    for n=quasiStop:length(ps)/5e+06
        %   Call scrambled quasi-random vector sequences in batched
        %   (due to memory resitrictions).
        addC = ps((n-1)*1e+05+1:n*1e+05,:);
        addC = addC*10;
        addC = round(addC);
        addC = unique(addC,'rows');
        
        %   The matrix of scatter coordinates are resized according to
        %   the number of doses available for each factor.
        for i=1:numFact
            idx = addC(:,i) > numDose(i,1)-1;
            addC(idx,:) = [];
        end
        
        %   Eliminate coordinates with more than half of the factors at
        %   zero.
        addC((sum(addC == 0,2) > numFact/2),:) = [];
        [r,~] = size(addC);
        if ~isempty(addC)
            %   Delete any vectors already in TabuList.
            for i=r:-1:1
                duplicate = ismember(addC(i,:),TabuList,'rows');
                if duplicate == 1
                    addC(i,:) = [];
                end
            end
            C = [C; addC];
        end
        addC = [];
        
        %   Delete any duplicate row vectors.
        C = unique(C,'rows');
        [r,~] = size(C);
        
        %   If sufficient number of unique vectors generated, stop.
        if r > numComb
            quasiStop = n;
            break
        end
    end
    
    %   Select required number of vectors from pool.
    numDel = transpose(randperm(r,r-numComb));
    X1 = removerows(C,'ind',numDel);
    
    %   Test plot 3 factor combinations at a time.
    q = 1;
    X = X1(randperm(numComb),:);
    X = transpose(X);
    countVectors = countVectors + numComb;
    TabuList = transpose(X);
else
    %   For subsequent generations, acquire set of target vectors from the
    %   selection made in the previous run.
    X = NaN(numFact,numComb);
    prevsheet = ['vectors_gen' num2str(run-1,'%02i')];
    Xselect = xlsread(filename,prevsheet,SelectionRangeR);
    [~,c] = size(Xselect);
    Xselect(c+1:numComb) = NaN;
    Xprev = xlsread(filename,prevsheet,XdoseRangeR);
    Uprev = xlsread(filename,prevsheet,UdoseRangeR);
    Xscore = xlsread(filename,prevsheet,XlogScoreR);
    Uscore = xlsread(filename,prevsheet,UlogScoreR);
    for i=1:numComb
        if isempty(Xselect(i))
            Xselect(i) = NaN;
        end
        switch Xselect(i)
            case 1
                X(:,i) = Xprev(:,i);
                CarryScore(1,i) = Xscore(1,i);
                X2(:,i) = NaN;
            case 0
                X(:,i) = Uprev(:,i);
                CarryScore(1,i) = Uscore(1,i);
                X2(:,i) = NaN; 
            case 7
                X(:,i) = miniReplaceWithGoodies(2);
                CarryScore(1,i) = NaN;
                X2(:,i) = X(:,i);
                countVectors = countVectors + 1;
            case 8
                %   Generate replacement vector. Remove combination that
                %   was not selected for a winning combination between X
                %   and U competition, and replenish the corresponding
                %   vector slot with a new vector to maintain the size of
                %   the test population.
                for j=1:numFact
                    X(j,i) = randsrc(1,1,0:numDose(j,1)-1);
                end
                vectorState = 1;
                X(:,i) = CheckDuplicate(X(:,i));
                CarryScore(1,i) = NaN;
                X2(:,i) = X(:,i);
                countVectors = countVectors + 1;
            case 9
                %   Return to top scoring vector library (TopVectors,
                %   generated from SelectedVectors) to replace vector
                %   location with a 'goodie' vector as a randomly generated
                %   replacement vector has not identified a select-able
                %   vector to pursue.
                X(:,i) = ReplaceWithGoodies;
                CarryScore(1,i) = NaN;
                X2(:,i) = X(:,i);
                countVectors = countVectors + 1;
            otherwise
                %   Xselect(i) == NaN and there is a previously selected
                %   vector to return to.
                X(:,i) = ReturnToGoodies(SelectedVectors(1:numFact,i));
                countVectors = countVectors + 1;
        end
    end
end

vectorState = [];
VectorSet = X;
xlswrite(filename,X,sheetname,XdoseRangeW);
disp('Completed generating target vectors.');