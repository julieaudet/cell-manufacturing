function [evaltermin,TermCondDataAdd] = EvalTermCond

%   Function determines whether prespecified set of termination conditions
%   have been satisfied.

%   Termination conditions (case 1):
%   (1) The algorithm must have progressed at least 2 generations following
%   the implementation of memory structure-derived replacement vectors.
%   (2) The number of vectors assembled in the Pareto set must be at least
%   80% of the population size.
%   (3) The median of the Pareto set vector scores (Pareto population
%   median) must be within 10% of the maximum median score identified.
%   (4) Between consecutive generations, the two sets of Pareto set vector
%   median scores must not be significantly different (p > 0.05).
%   (5) *** establish method of measuring degree of similarity between
%   repeated/updated vectors ***
%   Termination conditions (case 2):
%   (1) The Pareto set size is equal to the full population size.

global run numFact numComb minParetoSize reqConvergCount scoreProxThresh
global minSimilarity convergCount mutCon redStatusF crossCon redStatusCR
global set1median set1scores set1vectors set2median set2scores set2vectors
global SelectedVectors

evaltermin = 0;
TermCondDataAdd = NaN(7,1+numComb);
CountSimilar = ones(1,numComb)*0; % counts number of factors in each vector
    % for consecutive generations that are 1 dose level apart.

disp(['Evaluating termination conditions for gen #' num2str(run)]);
disp(['   >>> Convergence count = ' num2str(convergCount)]);

TermCondDataAdd(1,1) = convergCount;

if nnz(~isnan(SelectedVectors(numFact+1,:))) > numComb*minParetoSize ...
        && convergCount == 0
    %   At least 80% of vectors have qualified into the Pareto set.
    convergCount = 1;
    set1median = nanmedian(SelectedVectors(numFact+1,:));
    set1scores = SelectedVectors(numFact+1,:);
    set1vectors = SelectedVectors(1:numFact,:);
    disp(['     > > 1st convergence occurrence at gen #' num2str(run)]);
    disp(['       > # vectors in Pareto set = ' num2str(nnz(~isnan(SelectedVectors(numFact+1,:))))]);
    TermCondDataAdd(2,2:numComb+1) = set1scores;
    TermCondDataAdd(3,1) = set1median;
elseif nnz(~isnan(SelectedVectors(numFact+1,:))) > numComb*minParetoSize ...
        && convergCount > 0
    %   Return of potential convergnece occurrence.
    disp(['       > # vectors in Pareto set = ' num2str(nnz(~isnan(SelectedVectors(numFact+1,:))))]);
    if convergCount == 1
        set2median = nanmedian(SelectedVectors(numFact+1,:)); 
        set2scores = SelectedVectors(numFact+1,:);
        set2vectors = SelectedVectors(1:numFact,:);
    elseif convergCount > 1
        set1median = set2median;
        set1scores = set2scores;
        set1vectors = set2vectors;
        set2median = nanmedian(SelectedVectors(numFact+1,:));
        set2scores = SelectedVectors(numFact+1,:);
        set2vectors = SelectedVectors(1:numFact,:);
    end
    TermCondDataAdd(2,2:numComb+1) = set1scores;
    TermCondDataAdd(3,1) = set1median;
    TermCondDataAdd(4,2:numComb+1) = set2scores;
    TermCondDataAdd(5,1) = set2median;
    
    maxMedian = max(set1median,set2median);
    
    if (maxMedian*(1-scoreProxThresh/100) <= set1median) && ...
            (maxMedian*(1-scoreProxThresh/100) <= set2median)
        %   Both median of population within desired score range of maximum
        %   population median.
        disp(['     > Medians in ' num2str(scoreProxThresh) '% range of max']);
        
        [~,h] = ranksum(set1scores,set2scores);
        if h == 0
            %   The difference of the population medians of the two
            %   consecutive sets are not significantly different.
            disp('     > Set scores not significantly different');
            
            if redStatusF == 0
                %   Median increase plateaued for at least 2 consecutive
                %   generations. Reuduce mutation coefficient.
                disp(repmat('  *',1,75/3));
                disp('     > Mutation coefficient reduced');
                mutCon = mutCon/2;
                redStatusF = 1;
            end
            
            if convergCount > 0
                %   Assess degree of similarity between set1vectors and
                %   set2vectors (Pareto sets of consecutive generations).
                for i=1:numComb
                    for j=1:numFact
                        if abs(set1vectors(j,i) - set2vectors(j,i)) <= 1
                            %   Factor 'j' in vector 'i' has not changed
                            %   between the consecutive generations.
                            CountSimilar(1,i) = CountSimilar(1,i) + 1;
                        end
                    end
                end
                
                TermCondDataAdd(6,2:numComb+1) = CountSimilar;
                
                if numComb*minParetoSize <= nnz(numFact*minSimilarity <= CountSimilar)
                    convergCount = convergCount + 1;
                    disp('     > Similarity requirement satisfied, convergCount +1');
                    load gong.mat; sound(y);
                end
            end
            
            if convergCount > 1 && redStatusCR == 0
                %   Overall convergence behavior (median & vector
                %   similarity) plateaued for at least 2 consecutive
                %   generations. Reduce crossover constant.
                disp(repmat('  *',1,75/3));
                disp('     > Crossover constant reduced');
                crossCon = crossCon/2;
                redStatusCR = 1;
            end
        else
            convergCount = 1; % reset counter
            set1median = nanmedian(SelectedVectors(numFact+1,:));
            set1scores = SelectedVectors(numFact+1,:);
            set1vectors = SelectedVectors(1:numFact,:);
            disp('     > Medians significantly diff, convergCount RESET to 1');
        end
    else
        convergCount = 1;
        set1median = nanmedian(SelectedVectors(numFact+1,:));
        set1scores = SelectedVectors(numFact+1,:);
        set1vectors = SelectedVectors(1:numFact,:);
        disp('     > Count RESET to 1');
    end
end

TermCondDataAdd(7,1) = convergCount;
disp(['   >>> Updated count = ' num2str(convergCount)]);
disp(['Completed evaluating termination conditions for gen #' num2str(run)]);
if convergCount == reqConvergCount
    evaltermin = 1; % all termination conditions satisfied.
end