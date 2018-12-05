function SelectStrategy

%   Function defines options to evaluate the statistical significance of a
%   candidate solution (performance result of a vector) that has been
%   tested.

global replicate numComb numFact filename run sheetname
global expMaximum interVarAlgo SelectedSums SelectedSumsSel minNumGoodVect
global SelectedVectors BestScores markCallMemory genFirstPop scoreThreshSS
global ParetoPlotData Xselect CurrScoresSS
global scoreProxThresh numFirstP numFirstV firstGenStat numCells
global XdoseRangeR UdoseRangeR SelectionRangeW XfinRangeR UfinRangeR PCfoldScoreW NCfoldScoreW

global DataSet

SelectedSums = 0; SelectedSumsSel = 0;

%   Initialize score arrays.
if run == 1
    CurrScoresSS = NaN(replicate,numComb);
    BestScores = NaN(replicate,numComb);
    SelectedVectors = NaN(numFact+1,numComb);
    scoreThreshSS = [];
    numFirstP = NaN;
    numFirstV = NaN;
else
    CurrScoresSS = NaN(replicate,numComb);
end

%   Read performance results and combination of vectors X and U from
%   previous generation.
PCscore = xlsread(filename,sheetname,PCfoldScoreW);
Xscore = []; Uscore = [];
for i=1:replicate
	Xscore = [Xscore; transpose(DataSet(run).RepSet(i).normFC(3:numComb+2))];
	Uscore = [Uscore; transpose(DataSet(run).RepSet(i).normFC(numComb+3:end))];
end
Xtemp = Xscore; Utemp = Uscore;
Xvectors = xlsread(filename,sheetname,XdoseRangeR);
Uvectors = xlsread(filename,sheetname,UdoseRangeR);

%   Screen for potential outliers within replicates
NCscore = DataSet(run).avgNormFC(2,1);
Xtemp(:,all(Xtemp < NCscore,1)) = NaN; Utemp(:,all(Utemp < NCscore,1)) = NaN;
DataSet(run).XsetCV_rev = DataSet(run).XsetCV;
DataSet(run).UsetCV_rev = DataSet(run).UsetCV;

for i=1:numComb
    if all(NCscore <= Xtemp(:,i)) % all replicates greater than NegCont score
    else
        arr = Xtemp(:,i);
        arr(arr < NCscore) = NaN; % if all replicates less than NegCont, replace with NaN
        if sum(isnan(arr)) == 1 % 1 replicate replaced with NaN
            XtempCV = std(Xtemp(:,i))/mean(Xtemp(:,i));
            arrCV = nanstd(arr)/nanmean(arr);
            if DataSet(run).posContCV <= abs(XtempCV-arrCV) % change in CV greater than estimated intra-exp variability
                Xtemp(:,i) = arr;
                DataSet(run).XsetCV_rev(i) = arrCV;
            else
                Xtemp(:,i) = NaN;
            end
%             SEM = std(x)/sqrt(length(x));               % Standard Error
%             ts = tinv([0.025  0.975],length(x)-1);      % T-Score
%             CI = mean(x) + ts*SEM;                      % Confidence Intervals
        end
    end
    if all(NCscore <= Utemp(:,i))
    else
        arr = Utemp(:,i);
        arr(arr < NCscore) = NaN;
        if sum(isnan(arr)) == 1
            UtempCV = std(Utemp(:,i))/mean(Utemp(:,i));
            arrCV = nanstd(arr)/nanmean(arr);
            if DataSet(run).posContCV <= abs(UtempCV-arrCV)
                Utemp(:,i) = arr;
                DataSet(run).UsetCV_rev(i) = arrCV;
            else
                Utemp(:,i) = NaN;
            end
        end
    end
end
% Xtemp(isnan(Xtemp)) = 0; Utemp(isnan(Utemp)) = 0;
Xtemp(:,all(isnan(Xtemp),1)) = 0; Utemp(:,all(isnan(Utemp),1)) = 0;
Xscore = Xtemp; Uscore = Utemp;

%   Define and initialize selection scoring vector.
Xselect = ones(1,numComb)*5;
for i=1:numComb
    %   1st round competition: Select from X vs U vector comparison based
    %   on the performance in the current generation. Using the Wilcoxon
    %   rank sum test, assign h=1 if significant difference at 5%.
    %   [p,h,stats] = ranksum(ref,query);
    [~,h,~] = ranksum(Xscore(:,i),Uscore(:,i));
    if nanmean(Xscore(:,i)) > 0 || nanmean(Uscore(:,i)) > 0
        switch h
            case 1
                %   X vs U significant -- select vector with higher score.
                if nanmean(Xscore(:,i)) > nanmean(Uscore(:,i))
                    CurrScoresSS(:,i) = Xscore(:,i); Xselect(i) = 1;
                else
                    CurrScoresSS(:,i) = Uscore(:,i); Xselect(i) = 0;
                end
                
            case 0
                %   X vs U not significant
                if nanmean(Xscore(:,i)) > 0 && nanmean(Uscore(:,i)) > 0
                    %   Both are within an equivalent range with positive
                    %   (away from zero) scores. Select one randomly.
                    r = randi(10);
                    if mod(r,2)
                        CurrScoresSS(:,i) = Xscore(:,i); Xselect(i) = 1;
                    else
                        CurrScoresSS(:,i) = Uscore(:,i); Xselect(i) = 0;
                    end
                elseif nanmean(Xscore(:,i)) > 0 && any(any(isnan(SelectedVectors),1))
                    CurrScoresSS(:,i) = Xscore(:,i); Xselect(i) = 1;
                elseif nanmean(Uscore(:,i)) > 0 && any(any(isnan(SelectedVectors),1))
                    CurrScoresSS(:,i) = Uscore(:,i); Xselect(i) = 0;
                else
                    CurrScoresSS(:,i) = 0; Xselect(i) = NaN;
                end
        end
    else % both X and U score negative or zero
        CurrScoresSS(:,i) = 0; Xselect(i) = NaN;
    end
    
    %   Populate SelectedVectors and calculate population rank sum. For
    %   generation 1, take selections made in current generation only. For
    %   all subsequent generations, conduct a secondary selection protocol
    %   that assesses the status of improvement in performance over
    %   previous generations.
    
    %   A vector selection is made if there is a siginificant difference in
    %   the cell expansion resulting from the X and U vector combinations,
    %   from which the vectors with higher score is selected.
    if run == 1
        switch Xselect(i)
            case 0
                [~,~,stats] = ranksum(Uscore(:,i),Xscore(:,i));
                BestScores(:,i) = Uscore(:,i);
                SelectedVectors(1:numFact,i) = Uvectors(:,i);
                SelectedVectors(numFact+1,i) = nanmean(Uscore(:,i));
                SelectedSums = SelectedSums + stats.ranksum;
                SelectedSumsSel = SelectedSumsSel + 1;
            case 1
                [~,~,stats] = ranksum(Xscore(:,i),Uscore(:,i));
                BestScores(:,i) = Xscore(:,i);
                SelectedVectors(1:numFact,i) = Xvectors(:,i);
                SelectedVectors(numFact+1,i) = nanmean(Xscore(:,i));
                SelectedSums = SelectedSums + stats.ranksum;
                SelectedSumsSel = SelectedSumsSel + 1;
            otherwise
                BestScores(:,i) = 0;
                Xselect(i) = 8; % mark vector pos for replacement vector
        end
        if i == numComb
            disp(['Pareto set updated for G' num2str(run)]);
        end
    else
        %   For run > 1: Make selections based on the performance of the
        %   current generation with consideration of the inter-experimental
        %   variability. First compare the scores of both X and U of the
        %   current generation to the selected vector score of the previous
        %   generation. Select according to statistical siginificance and
        %   improvement.
        upEnd = nanmean(BestScores(:,i))*(1+(interVarAlgo/100));
        lowEnd = nanmean(BestScores(:,i))*(1-(scoreProxThresh/100));
        
        if (Xselect(i) == 0 || Xselect(i) == 1) && upEnd < nanmean(CurrScoresSS(:,i))
            %   A vector selection has been made in current generation:
            %   The vector selected at the current generation scored
            %   beyond the equivalence range defined by
            %   inter-experimental variability. Update BestScores, keep
            %   Xselect.
            switch Xselect(i)
                case 0
                    BestScores(:,i) = Uscore(:,i);
                case 1
                    BestScores(:,i) = Xscore(:,i);
            end
        elseif (Xselect(i) == 0 || Xselect(i) == 1) && ...
                (lowEnd < nanmean(CurrScoresSS(:,i)) && nanmean(CurrScoresSS(:,i)) <= upEnd)
            %   The vector selected at the current generation scored
            %   within the equivalence range defined by the
            %   inter-experimental variability. Update BestScores if
            %   scores have improved, keep Xselect.
            switch Xselect(i)
                case 0
                    if nanmean(Uscore(:,i)) > BestScores(:,i)
                        BestScores(:,i) = Uscore(:,i);
                    end
                case 1
                    if nanmean(Xscore(:,i)) > BestScores(:,i)
                        BestScores(:,i) = Xscore(:,i);
                    end
            end
        elseif (Xselect(i) == 0 || Xselect(i) == 1) && ...
                (nanmean(CurrScoresSS(:,i) < lowEnd))
            %   A vector selection has been made in the current
            %   generation in the comparison between the target and
            %   trial vectors but the selected vector score below the
            %   lowEnd of the equivalent performance range of the
            %   expected performance. Require a new source vector as
            %   current vector performance is sub-par and/or on a
            %   decreasing trend.
            
            %   Find (global) best score encountered so far.
            highScore = max(SelectedVectors(numFact+1,:));
            scoreThreshSS = highScore*(1-(scoreProxThresh/100));
            
            if all(~isnan(SelectedVectors(:,i)))
                %   A previously selected vector available for vector
                %   position 'i'.
                if scoreThreshSS <= SelectedVectors(numFact+1,i)
                    %   The previously selected vector has a good score.
                    Xselect(i) = NaN;
                else
                    %   The previously selected vector does not improve
                    %   overall performance.
                    if run < markCallMemory
                        Xselect(i) = 8;
                    else
                        Xselect(i) = 9;
                    end
                end
            else
                %   Previously selected vector at position 'i' is not
                %   available (first selection occuring at vector position
                %   'i'). With current state, the current score is most
                %   definitely less than scoreThreshSS.
                if run < markCallMemory
                    Xselect(i) = 8;
                else
                    Xselect(i) = 9;
                end
            end
        else
            %   A selection has not been made at the current generation or
            %   the vector selected at the current generation.
            if scoreThreshSS <= SelectedVectors(numFact+1,i)
                %   There is a previously selected vector at this vector
                %   position. Return to previously selected vector at
                %   target vector generation. De-select Xselect.
                Xselect(i) = NaN;
            elseif all(~isnan(SelectedVectors(:,i)))
                Xselect(i) = 9;
            elseif all(isnan(SelectedVectors(:,i)))
                %   A vector has never been selected at vector position.
                %   Mark to fill with replacement vector.
                if run < markCallMemory
                    %   If at 1st or 2nd run, generate random replacement
                    %   vector.
                    Xselect(i) = 8;
                else
                    %   If a non-zero scoring replacement vectors has not
                    %   been discovered, use a vector from the top scoring
                    %   SelectedVectors to populate vector location.
                    Xselect(i) = 9;
                end
            end
        end
        
        %   Populate SelectedVectors and calculate population rank sum for
        %   vector scores selected in current generation.
        switch Xselect(i)
            case 0
                CurrScoresSS(:,i) = Uscore(:,i);
                SelectedVectors(1:numFact,i) = Uvectors(:,i);
                SelectedVectors(numFact+1,i) = nanmean(Uscore(:,i));
                [~,~,stats] = ranksum(Uscore(:,i),Xscore(:,i));
                SelectedSums = SelectedSums + stats.ranksum;
                SelectedSumsSel = SelectedSumsSel + 1;
            case 1
                CurrScoresSS(:,i) = Xscore(:,i);
                SelectedVectors(1:numFact,i) = Xvectors(:,i);
                SelectedVectors(numFact+1,i) = nanmean(Xscore(:,i));
                [~,~,stats] = ranksum(Xscore(:,i),Uscore(:,i));
                SelectedSums = SelectedSums + stats.ranksum;
                SelectedSumsSel = SelectedSumsSel + 1;
        end
    end
    if Xselect(i) == 5
        disp('Xselect condition missing. Check + F5 to continue.'); beep; keyboard;
    end
end

%   Dynamic calling and implementation of memory structure-derived vector
%   generation.
%   Define: Minimum number of good vectors identified
if nnz(~isnan(SelectedVectors(numFact+1,:))) >= minNumGoodVect ...
        && markCallMemory == 10
    %   If a minimum of 'minNumGoodVect' number of 'good vectors' are
    %   identified, update markCallMemory from initial value of 10 to
    %   current generation number.
    markCallMemory = run;
    disp(['   > G' num2str(run) ' identified ' num2str(nnz(~isnan(SelectedVectors(numFact+1,:)))) ' potential vectors']);
    if nnz(Xselect == 8)
        Xselect(Xselect == 8) = 9;
    end
    if strcmp(genFirstPop,'d')
        firstGenStat = 1;
    end
end

%   3rd round selection strategy: vectors in the bottom n% scoring range
%   replaced with variations of vectors in the top n% scoring range.
if run > markCallMemory+1
    Xselect = miniReplaceWithGoodies(1);
    if nnz(Xselect == 7)
%         disp([' (' num2str(nnz(Xselect == 7)) ' vectors affected)']);
    end
end
xlswrite(filename,Xselect,sheetname,SelectionRangeW);

%   Summary of vector progress (Xselect) status.
disp([' > Total number of vectors evaluated = ' num2str(numComb*2)]);
if nnz(Xselect == 0) || nnz(Xselect == 1)
    disp(['  >> Selected vector progressing = ' num2str(nnz(Xselect == 0)+nnz(Xselect == 1))]);
end
if nnz(Xselect == 8)
    disp(['  >> Accept new random vector = ' num2str(nnz(Xselect == 8))]);
end