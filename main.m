%   Differential evolution-based combinatorial optimization algorithm that
%   tests and builds on identified factor interactions to identify an
%   optimal combination of factors and respective doses.
%   Objective function of optimization problem used for the generation of
%   in silico data (with simulated response surface) defined in function
%   script OPTIMPROBLEM.
%   Initialize the random-number generator for reproducibility during
%   algorithm development and testing.
%   ----------------------------------------------------------------------
%   rng function options:
%       'twister'           Mersenne Twister
%       'multFibonacci'     Multiplicative Lagged Fibonacci
%       'v5normal'          Legacy MATLAB 5.0 normal generator
%       'v4'                Legacy MATLAB 4.0 generator
%   ----------------------------------------------------------------------
% rng(0,'twister');

global status
status = 'x';
while ~(strcmp(status,'n') || strcmp(status,'c'))
    status = input('Optimzation status ("n" for new optimzation, "c" for continuation)? ','s');
end

%   Define excel interaction cell ranges.
global DataRange KeyRange SelectionRangeR NCintRangeW NCintAvgW PCintRangeW PCintAvgW NCfinRangeW ViabilityRange 
global NCfinAvgW PCfinRangeW PCfinAvgW NCfoldScoreW PCfoldScoreW NClogScoreW PClogScoreW
global SelectionRangeW UdoseRangeR UdoseRangeW UfinAvgW UfinRangeR UfinRangeW UlogScoreR UlogScoreW
global UintAvgW UintRangeW UfoldScoreR UfoldScoreW XdoseRangeR XdoseRangeW XfinAvgW XfinRangeR 
global XfinRangeW XlogScoreR XlogScoreW XintAvgW XintRangeW XfoldScoreR XfoldScoreW NCintRangeR 
global PCintRangeR NCfinRangeR PCfinRangeR KeyRangeLow KeyRangeHigh

%   Define optimization mechanism parameters.
global cellName numDimension activateFCR activateTC activateVAR allListRange avgEM baseMedia
global benchmarkName calcMax calledMRWG cellSuspVol coeffA coeffB contComb
global contInd convergCount countCell countVectors interExpVarCV intraExpVarCV crossCon
global dataSaveDir destColWells destRowWells doseProxThresh evalResultPVS
global expMaximum expMaxPVS factorNameList fHeader fileHeader filename
global firstGen firstGenStat genFirstPop highScoreMRWG PCint initialCount
global interVarAlgo interVarComb intraVarAlgo intraVarComb lastBested
global lastGoodies lowScoreMRWG markCallMemory maxRankSum maxRunAllowed
global minNumGoodVect minParetoSize minSimilarity mutCon name nsMRWG
global numBlank numCatPPS numCatPVS numComb numDose numFact numFirstP
global numFirstV numWells outputfile outputsheet pathname popSizeFactor
global ps q quasiMethod quasiStop redStatusCR redStatusF replicate
global reqConvergCount reset resvColWells resvMaxVol resvMinVol maxTransfVol
global resvRowWells run scoreProxThresh scoreThreshSS set1median set1scores
global set1vectors set2median set2scores set2vectors sheetname sourcepathSES
global spath supplTotVol targetpathSES terminateOptim textWidth tpath Uint
global updateStatus vectorState wellcodeD wellcodeR wellListD wellListR
global wellTotVol Xint resvRowStart resvColStart cellCountFile plateSize
global minTransferVol maxTransferVol sourcefile detailsFile cultVol numCells
global assayVol resuspVol sampleVol resvTubNum volDWPtoFP numSetsCP makeDWP
global numChannel seedingDensity Stock DataSet

global BestScores BetterPool BetterVectors CarryScore CurrentStateMRWG
global CurrScoresSS DistCountP DistCountV  E ExpSolution Factors GenSimData
global GoodiesPool GoodiesUsedRWG HammLeven Key NewSourceMRWG NumConvergLog
global NumImproveLog NumSelectedLog NumTestVectors ParetoPlotData DilutionPrep
global ParetoSimData QueryVPPS RankSumLog ScoreProxLog SelectedSums
global SelectedSumsSel SelectedVectors SeriesValues SeriesValuesL SimDistP
global SimDistV TabuList TermCondData TopVectors TrackProxLog TrackProxLog2
global VectorProxLog VectorProxLog2 VectorSet WinScoreLog WinScoreLogL
global Xselect BlankRange CalibRange NCint Xfin Ufin NCfin PCfin StockRange

if strcmp(status,'n')
    initialize_define_variables; % initialize and define variables
    
    numComb = 118/2;
    genFirstPop = 'd';
    
    disp(['Population size set to = ' num2str(numComb)]);
    startTime = clock; % start optimization
    fprintf('Starting optimization at %s.\n', datestr(startTime,'mmm dd yyyy, HH:MM'));
    fileHeader = [datestr(startTime,'yyyy-mm-dd_HHMM') '_' cellName '_' num2str(numDimension) 'D'];
    fHeader = fileHeader(1:15);
    diary([fHeader '_cmdHist.txt']); % creates command history log file
    disp(repmat('*',1,textWidth));
    if strcmp(genFirstPop,'r')
        disp('RANDOM INITIAL POPULATION');
    elseif strcmp(genFirstPop,'d')
        disp('QUASI-RANDOM INITIAL POPULATION');
        firstGenStat = 0;
    end
    if calcMax == 0
        expMaximum = log(OptimProblem(transpose(contVect))/initialCount);
        disp(['main: Simulation mode, solution known: max score expected = ' num2str(expMaximum)]);
    elseif calcMax == 1
        disp('main: Experimental mode, conventional condition as positive control');
        expMaximum = 0;
    end
elseif strcmp(status,'c')
    diary([fHeader '_cmdHist.txt']); % append new log to existing log file
    uigetfile('*_workspace.mat','Select workspace datafile'); % load datafile
end

if run == 0
    run = run + 1;
    disp(repmat('- ',1,textWidth/2));
    SaveExcelSheet; % create new worksheet in excel workbook
    disp(['main: starting G' num2str(run)]);
    disp(['         F = ' num2str(mutCon) ', CR = ' num2str(crossCon)]);
    [numFact,~] = size(Key);
    for i=1:numFact
        numDose(i,1) = nnz(~isnan(Key(i,:))); % assign number of doses for
            % individual factors (numDose changes format from single,
            % universal value to data in array.
    end
    GenTargetVectors; % generate original combinations (X, target vectors)
    GenTrialVectors; % generate trial vectors (U) through mutation and crossover.
    GenCocktailList(VectorSet);
    GenDilutionPrep;
    disp(['main: G' num2str(run) ' test vector compositions output complete']);
else
    disp('main: Check datafile loaded to workspace + F5 to continue'); keyboard;
    if isempty(detailsFile)
        disp(['   Initial cell seeding density = ' num2str(seedingDensity) ' cells/ml, culture volume ' num2str(wellTotVol) ' ul/well in ' num2str(plateSize) '-well plate + F5 to continue']); keyboard;
        numCells = initialCount;
    end
    disp('main: Check cell count batch file well ID formatting (relocate NegCont well to row after well B11) + F5 to continue'); keyboard;
    [cellCountFile,~] = uigetfile('Batch_Analysis_*.xlsx',['select final cell count datafile for G' num2str(run)]);
    EvalComb(cellCountFile); % evalaute target (X) and trial (U) vectors
    AssessVar; % determine intra- and inter-experimental variability
    SelectStrategy; % determine statistical significance of performance
        % result comparison between X and U to select 'winning' vectors
    if run > markCallMemory+1
        [evaltermin,TermCondDataAdd] = EvalTermCond; % assess termination condition
        if evaltermin == 1  % termination conditions have been satisfied
            if activateTC == 0
                terminateOptim = 0; % static/inactive termination conditions
                disp('main: Termination conditions evaluation deactivated - continue iteration');
            elseif activateTC == 1
                terminateOptim = 1; % active termination conditions
                disp(['main: Termination conditions satisfied at end of G' num2str(run)]);
            end
            load gong.mat; sound(y);
        elseif run > maxRunAllowed
            terminateOptim = 2;
            disp('main: Max # of generations allowed reached before termination conditions satisfied.');
        else
            terminateOptim = 0;
            disp('main: Termination conditions not satisfied - continue iteration');
        end
        TermCondData = [TermCondData; TermCondDataAdd];
    end
    
    if run == maxRunAllowed+1
        disp(['main: End of G' num2str(run)]);
        disp(['main: Max # of generations limited to ' num2str(maxRunAllowed+1)]);
        update = input('> Update # generations allowed [y/n]? ','s');
        if update == 'y'
            maxRunAllowed = input('> New # generations allowed = ')-1;
            terminateOptim = 0;
        elseif update == 'n'
            disp('> No change');
            terminateOptim = 2;
        end
    elseif terminateOptim == 1 || terminateOptim == 2
        beep;
        overrideTerm = input('main: Override algorithm and continue interation [y/n]? ','s');
        if strcmp(overrideTerm,'y')
            disp('main: Continue iteration');
            terminateOptim = 0;
        elseif strcmp(overrideTerm,'n')
            disp('main: Will terminate process');
        end
        while ~(strcmp(overrideTerm,'y') || strcmp(overrideTerm,'n'))
            disp('main: Input error');
            overrideTerm = input('main: Override algorithm and continue interation [y/n]? ','s');
        end
    end
    close all;
    NumTestVectors(run,1) = countVectors;
    ExportData;
    disp(['main: G' num2str(run) ' results output complete']);
    disp(['> End of G' num2str(run)]);
    disp(['> Total number of unique vectors tested = ' num2str(countVectors)]);

    if terminateOptim == 0
        run = run + 1; vectorState = []; TopVectors = []; GoodiesPool = [];
        BetterPool = []; BetterVectors = [];
        
        diary([fHeader '_cmdHist.txt']); % should append new log to existing log file
        disp(repmat('- ',1,textWidth/2));
        SaveExcelSheet; 
        for i=1:numFact
            numDose(i,1) = nnz(~isnan(Key(i,:))); % assign number of
                % doses for individual factors (numDose changes format from
                % single, universal value to data in array.
        end
        disp(['main: Starting G' num2str(run)]);
        disp(['          F = ' num2str(mutCon) ', CR = ' num2str(crossCon)]); 
        GenTargetVectors;
        GenTrialVectors;
        GenCocktailList(VectorSet);
        GenDilutionPrep;
        disp(['main: G' num2str(run) ' test vector compositions output complete']);
    else
        disp('main: Continue iteration');
    end
end
resultFile = [fHeader '_workspace.mat'];
save(resultFile); % save workspace variables
disp('main: Workspace variables saved');

if terminateOptim == 1 || terminateOptim == 2
    movefile(resultFile,dataSaveDir);
    movefile(filename,dataSaveDir);
    movefile('*.mat',dataSaveDir);
    movefile('*.xlsx',dataSaveDir);
    disp(repmat('- ',1,textWidth/2));
    fprintf('Optimization completed at %s.\n', datestr(clock,'mmm dd yyyy, HH:MM'));
    disp(repmat('*',1,textWidth));
    diary off;
    movefile('*.txt',dataSaveDir);
    load chirp.mat; sound(y);
end
disp('main: Current run completed');
diary off;