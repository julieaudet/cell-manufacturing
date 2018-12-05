function newInfo = miniReplaceWithGoodies(funcState)

%   Function sorts through SelectedVectors to use library of top scoring
%   vectors to replace poorly scoring vectors instead of randomly generated
%   replacement vectors.

global numFact numComb numDose interVarAlgo scoreProxThresh highScoreMRWG
global lowScoreMRWG calledMRWG nsMRWG
global SelectedVectors TabuList Xselect CurrentStateMRWG NewSourceMRWG

switch funcState
    case 1 % called from SelectStrategy (3rd round selection)
        CurrentStateMRWG = NaN(numFact+2,numComb);
        NewSourceMRWG = [];
        
        for i=1:numComb
            %   Consolidate information on vectors and observed scores.
            CurrentStateMRWG(1:numFact,i) = SelectedVectors(1:numFact,i);
            CurrentStateMRWG(numFact+1,i) = SelectedVectors(numFact+1,i);
            CurrentStateMRWG(numFact+2,i) = Xselect(i);
        end
        CurrentStateMRWG(numFact+3,:) = transpose(1:numComb);
        CurrentStateMRWG = transpose(CurrentStateMRWG); % each row contains vector
        NewSelect = CurrentStateMRWG(:,numFact+2);
        
        highScoreMRWG = max(CurrentStateMRWG(:,numFact+1))*(1-(scoreProxThresh/100));
        lowScoreMRWG = min(CurrentStateMRWG(:,numFact+1))*(1+(interVarAlgo*4/100));
        
        if highScoreMRWG <= lowScoreMRWG
            highScoreMRWG = max(CurrentStateMRWG(:,numFact+1))*(1-(scoreProxThresh/100));
            lowScoreMRWG = min(CurrentStateMRWG(:,numFact+1))*(1+(interVarAlgo*2/100));
            
            if highScoreMRWG <= lowScoreMRWG
                %   The top and bottom vector scores are closer than
                %   scoreProxThresh (%) apart.
                highScoreMRWG = max(CurrentStateMRWG(:,numFact+1))*(1-(scoreProxThresh/100));
                lowScoreMRWG = min(CurrentStateMRWG(:,numFact+1))*(1+(interVarAlgo/100));
                
                if highScoreMRWG <= lowScoreMRWG
                    highScoreMRWG = max(CurrentStateMRWG(:,numFact+1))*(1-(scoreProxThresh/100));
                    lowScoreMRWG = min(CurrentStateMRWG(:,numFact+1))*(1+(scoreProxThresh/100));
                    
                    if highScoreMRWG <= lowScoreMRWG
                        highScoreMRWG = max(CurrentStateMRWG(:,numFact+1));
                        lowScoreMRWG = max(CurrentStateMRWG(:,numFact+1))*(1-(scoreProxThresh/100));
                    end
                end
            end
        end
        
        NewSelect(CurrentStateMRWG(:,numFact+1) <= lowScoreMRWG & ...
            ~isnan(CurrentStateMRWG(:,numFact+1))) = 7;
        newInfo = transpose(NewSelect); % updated Xselect
        CurrentStateMRWG = flipud(sortrows(CurrentStateMRWG,numFact+1));
        CurrentStateMRWG = CurrentStateMRWG(~any(isnan(CurrentStateMRWG),2),:);
        calledMRWG = 0;
    case 2 % calledMRWG from GenTargetVectors (output newTarget)
        if calledMRWG == 0 % 1st time calledMRWG in current generation            
            %   Generate pool of new source target vectors created as
            %   variations from the top sorted vectors.
            r = nnz(Xselect == 7); % minimum number of new, unique vectors
                % that need to be generated.
            TopSorted = CurrentStateMRWG(highScoreMRWG <= CurrentStateMRWG(:,numFact+1),:);
            TopSortedCopy = TopSorted;
            [ts,~] = size(TopSortedCopy);
            [nsMRWG,~] = size(NewSourceMRWG);
            
            while nsMRWG < r
                if ts == 0
                    if nsMRWG == 0
                        highScoreMRWG = max(CurrentStateMRWG(:,numFact+1))*(1-(scoreProxThresh/100));
                        lowScoreMRWG = min(CurrentStateMRWG(:,numFact+1))*(1+(interVarAlgo*4/100));
                        
                        if highScoreMRWG <= lowScoreMRWG
                            highScoreMRWG = max(CurrentStateMRWG(:,numFact+1))*(1-(scoreProxThresh/100));
                            lowScoreMRWG = min(CurrentStateMRWG(:,numFact+1))*(1+(interVarAlgo*2/100));
                            
                            if highScoreMRWG <= lowScoreMRWG
                                highScoreMRWG = max(CurrentStateMRWG(:,numFact+1))*(1-(scoreProxThresh/100));
                                lowScoreMRWG = min(CurrentStateMRWG(:,numFact+1))*(1+(interVarAlgo/100));
                                
                                if highScoreMRWG <= lowScoreMRWG
                                    highScoreMRWG = max(CurrentStateMRWG(:,numFact+1))*(1-(scoreProxThresh/100));
                                    lowScoreMRWG = min(CurrentStateMRWG(:,numFact+1))*(1+(scoreProxThresh/100));
                                    
                                    if highScoreMRWG <= lowScoreMRWG
                                        highScoreMRWG = max(CurrentStateMRWG(:,numFact+1));
                                        lowScoreMRWG = max(CurrentStateMRWG(:,numFact+1))*(1-(scoreProxThresh/100));
                                    end
                                end
                            end
                        end
                        TopSorted = CurrentStateMRWG(highScoreMRWG <= CurrentStateMRWG(:,numFact+1),:);
                        TopSortedCopy = TopSorted;
                        [ts,~] = size(TopSortedCopy);
                        if ts == 0
                            disp('miniReplaceWithGoodies: TopSorted empty'); beep; keyboard;
                        end
                    else
                        %   Vectors in TopSorted not enough to generate
                        %   sufficient vectors to replace all required.
                        %   Take vectors from NewSourceMRWG to fill remaining
                        %   required.
                        NewSourceMRWGCopy = NewSourceMRWG;
                        [nsMRWG2,~] = size(NewSourceMRWGCopy);
                        if nsMRWG2 == 0
                            disp('miniReplaceWithGoodies: NewSourceMRWGCopy empty'); beep; keyboard;
                        end
                        
                        while nsMRWG < r
                            if nsMRWG2 == 0
                                disp('miniReplaceWithGoodies: NewSourceMRWGCopy empty'); beep; keyboard;
                            end
                            s = randi(nsMRWG2);
                            newRoot = NewSourceMRWGCopy(s,1:numFact);
                            AddToNS = repmat(newRoot,numFact*2,1);
                            for i=1:numFact
                                AddToNS(i,i) = AddToNS(i,i)+1;
                                AddToNS(numFact+i,i) = AddToNS(numFact+i,i)-1;
                                AddToNS(AddToNS > numDose(i,1)-1) = numDose(i,1)-1;
                            end
                            AddToNS(AddToNS < 0) = 0;
                            AddToNS = unique(AddToNS,'rows');
                            AddToNS = AddToNS(~ismember(AddToNS,TabuList,'rows'),:);
                            NewSourceMRWG = [NewSourceMRWG; AddToNS];
                            NewSourceMRWG = unique(NewSourceMRWG,'rows');
                            AddToNS = [];
                            NewSourceMRWGCopy(s,:) = [];
                            [nsMRWG2,~] = size(NewSourceMRWGCopy);
                            [nsMRWG,~] = size(NewSourceMRWG);
                        end
                    end
                else % ts > 0
                    s = randi(ts);
                    newRoot = TopSorted(s,1:numFact);
                    
                    %   Generate a pool of vectors from the newRoot vector
                    %   by +/- 1 dose level for a single factor.
                    AddToNS = repmat(newRoot,numFact*2,1);
                    for i=1:numFact
                        AddToNS(i,i) = AddToNS(i,i)+1;
                        AddToNS(numFact+i,i) = AddToNS(numFact+i,i)-1;
                        AddToNS(AddToNS > numDose(i,1)-1) = numDose(i,1)-1;
                    end
                    AddToNS(AddToNS < 0) = 0;
                    AddToNS = unique(AddToNS,'rows');
                        % remove duplicate vectors from within GoodiesPool
                    AddToNS = AddToNS(~ismember(AddToNS,TabuList,'rows'),:);
                        % remove previously tested vectors in TabuList that
                        % were regenerated in GoodiesPool
                    NewSourceMRWG = [NewSourceMRWG; AddToNS];
                    NewSourceMRWG = unique(NewSourceMRWG,'rows');
                    AddToNS = [];
                    TopSortedCopy(s,:) = [];
                    [ts,~] = size(TopSortedCopy);
                end
                [nsMRWG,~] = size(NewSourceMRWG);
            end
            
            calledMRWG = 1;
            [nsMRWG,~] = size(NewSourceMRWG);
            if nsMRWG == 0
                disp('miniReplaceWithGoodies: NewSourceMRWG empty'); beep; keyboard;
            end
            s = randi(nsMRWG);
            newTarget = transpose(NewSourceMRWG(s,1:numFact));
            NewSourceMRWG(s,:) = [];
            [nsMRWG,~] = size(NewSourceMRWG);
            newInfo = newTarget;
            TabuList = [TabuList; transpose(newTarget)];
        elseif calledMRWG == 1 % select random vector as replacement target
                % vector from pool of new, unique vectors generated
            s = randi(nsMRWG);
            newTarget = transpose(NewSourceMRWG(s,1:numFact));
            NewSourceMRWG(s,:) = [];
            [nsMRWG,~] = size(NewSourceMRWG);
            newInfo = newTarget;
            TabuList = [TabuList; transpose(newTarget)];
            calledMRWG = 1;
        end
end