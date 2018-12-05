function newTarget = ReplaceWithGoodies

%   Function sorts through SelectedVectors to use library of top scoring
%   vectors to replace poorly scoring vectors instead of randomly generated
%   replacement vectors.

global numFact run lastGoodies numDose scoreProxThresh intraVarAlgo interVarAlgo
global SelectedVectors TopVectors GoodiesPool TabuList Xselect GoodiesUsedRWG

if lastGoodies ~= run
    %   TopVectors:
    %   columns [1:numComb] vector positions
    %   rows    [1:numFact] coded dose levels
    %   row     [numFact+1] mean score of corresponding vector
    lastGoodies = run;
    TopVectors = [TopVectors SelectedVectors];
    GoodiesUsedRWG = 0;
    
    %   Sort TopVectors -- mean score of vectors in row numFact+1 in
    %   descending order left to right (column 1 holds vector with highest
    %   score).
    TopVectors(:,all(isnan(TopVectors),1)) = [];
    TopVectors = transpose(unique(transpose(TopVectors),'rows'));
    TopVectors = transpose(flipud(sortrows(transpose(TopVectors),numFact+1)));
    
    %   Only keep vectors with scores within the interVarAlgo(%) range of
    %   the top score.
    topScore = TopVectors(numFact+1,1);
    scoreThresh = topScore*(1-(scoreProxThresh/100));
    TopVectors(:,TopVectors(numFact+1,:)<scoreThresh)=[];
    
    %   Minimum number of new, unique vectors that need to be generated.
    r = nnz(Xselect == 9);
    TopVectorsCopy = TopVectors;
    [~,n] = size(TopVectorsCopy);
    [~,p] = size(GoodiesPool);
    
    while p < r && n > 0
        s = randi(n);
        newRoot = TopVectors(1:numFact,s);
        
        %   Generate a pool of vectors from the newRoot vector by +/- 1
        %   dose level for a single factor.
        AddToGP = repmat(transpose(newRoot),numFact*2,1);
        for i=1:numFact
            AddToGP(i,i) = AddToGP(i,i)+1;
            AddToGP(numFact+i,i) = AddToGP(numFact+i,i)-1;
            AddToGP(AddToGP > numDose(i,1)-1) = numDose(i,1)-1;
        end
        AddToGP(AddToGP < 0) = 0;
        AddToGP = unique(AddToGP,'rows');
            % remove duplicate vectors from within GoodiesPool
        AddToGP = AddToGP(~ismember(AddToGP,TabuList,'rows'),:);
            % remove previously tested vectors in TabuList that were
            % regenerated in GoodiesPool
        GoodiesPool = [GoodiesPool transpose(AddToGP)];
        GoodiesPool = unique(transpose(GoodiesPool),'rows');
        GoodiesPool = transpose(GoodiesPool);
        AddToGP = [];
        TopVectorsCopy(:,s) = [];
        [~,n] = size(TopVectorsCopy);
        [~,p] = size(GoodiesPool);
    end
    
    GoodiesPoolCopy = GoodiesPool;
    [~,p2] = size(GoodiesPoolCopy);
        
    while p < r && n == 0 && p2 > 0
        %   If # vectors in GoodiesPool still not enough:
        %   Select a random vector from the pool to further generate
        %   permuatations with +/- 1 dose level for single factor.
        s = randi(p2);
        newRoot = GoodiesPoolCopy(1:numFact,s);
        AddToGP = repmat(transpose(newRoot),numFact*2,1);
        for i=1:numFact
            AddToGP(i,i) = AddToGP(i,i)+1;
            AddToGP(numFact+i,i) = AddToGP(numFact+i,i)-1;
            AddToGP(AddToGP > numDose(i,1)-1) = numDose(i,1)-1;
        end
        AddToGP(AddToGP < 0) = 0;
        AddToGP = unique(AddToGP,'rows');
        AddToGP = AddToGP(~ismember(AddToGP,TabuList,'rows'),:);
        GoodiesPool = [GoodiesPool transpose(AddToGP)];
        GoodiesPool = unique(transpose(GoodiesPool),'rows');
        GoodiesPool = transpose(GoodiesPool);
        AddToGP = [];
        GoodiesPoolCopy(:,s) = [];
        [~,p2] = size(GoodiesPoolCopy);
        [~,p] = size(GoodiesPool);
        
        if p < r && p2 == 0
            GoodiesPoolCopy = GoodiesPool;
            [~,p2] = size(GoodiesPoolCopy);
        end
    end
end

%   Select a random vector from the pool, ensuring that the same vector has
%   not been selected previously from GoodiesPool.
[~,p] = size(GoodiesPool);
if p == 0
    attemptcount = 1;
    while p == 0
        attemptcount = attemptcount + 1;
        switch attemptcount
            case 2
                newThresh = intraVarAlgo/2;
            case 3
                newThresh = intraVarAlgo;
            case 4
                newThresh = interVarAlgo/2;
            case 5
                newThresh = interVarAlgo;
            case 6
                disp('ReplaceWithGoodies: error'); beep; keyboard;
        end
        p = expandReplaceWithGoodies(attemptcount,newThresh);
    end
end
i = randi(p);
posUsed = ismember(i,GoodiesUsedRWG,'rows');
if posUsed == 0
    newTarget = GoodiesPool(1:numFact,i);
    GoodiesUsedRWG = [GoodiesUsedRWG; i];
else
    while posUsed == 1
        i = randi(p);
        posUsed = ismember(i,GoodiesUsedRWG);
    end
    newTarget = GoodiesPool(1:numFact,i);
    GoodiesUsedRWG = [GoodiesUsedRWG; i];
end

TabuList = [TabuList; transpose(newTarget)];