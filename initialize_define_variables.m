function initialize_define_variables

%%  VARIABLES
global DataRange KeyRange SelectionRangeR NCintRangeW NCintAvgW PCintRangeW PCintAvgW NCfinRangeW
global NCfinAvgW PCfinRangeW PCfinAvgW NCfoldScoreW PCfoldScoreW NClogScoreW PClogScoreW
global SelectionRangeW UdoseRangeR UdoseRangeW UfinAvgW UfinRangeR UfinRangeW UlogScoreR UlogScoreW
global UintAvgW UintRangeW UfoldScoreR UfoldScoreW XdoseRangeR XdoseRangeW XfinAvgW XfinRangeR 
global XfinRangeW XlogScoreR XlogScoreW XintAvgW XintRangeW XfoldScoreR XfoldScoreW NCintRangeR 
global PCintRangeR NCfinRangeR PCfinRangeR KeyRangeLow KeyRangeHigh ViabilityRange

global activateFCR activateTC activateVAR allListRange avgEM baseMedia
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
global wellTotVol Xint resvRowStart resvColStart carryFile cellName contVect numDimension handlerMode
global minTransferVol maxTransferVol detailsFile cultVol plateSize numCells numSetsCP
global assayVol resuspVol sampleVol resvTubNum numChannel seedingDensity volDWPtoFP
 
global BestScores BetterPool BetterVectors CarryScore CurrentStateMRWG
global CurrScoresSS DistCountP DistCountV  E ExpSolution Factors GenSimData
global GoodiesPool GoodiesUsedRWG HammLeven Key NewSourceMRWG NumConvergLog
global NumImproveLog NumSelectedLog NumTestVectors ParetoPlotData StockRange
global ParetoSimData QueryVPPS RankSumLog ScoreProxLog SelectedSums
global SelectedSumsSel SelectedVectors SeriesValues SeriesValuesL SimDistP
global SimDistV TabuList TermCondData TopVectors TrackProxLog TrackProxLog2
global VectorProxLog VectorProxLog2 VectorSet WinScoreLog WinScoreLogL
global Xselect BlankRange CalibRange NCint Xfin Ufin NCfin PCfin

%%  DIFFERENTIAL EVOLUTION ALGORITHM PARAMETERS
activateTC = 1;
    % 0 -- run full simulations up to (maxRunAllowed+1) generations
    % 1 -- activate termination conditions
activateVAR = 1;
    % 0 -- reset assessed variability values to zero (to ignore presence of
    %      variability)
    % 1 -- activate variability assessment in AssessVar
activateFCR = 1;
    % 0 -- maintain static DE parameters throughout
    % 1 -- activate dynamic reduction of DE parameters (F and CR)
genFirstPop = 'd';
    % define method to generate initial population
    % 'd' -- quasi-random/deterministic distributed vectors
    % 'r' -- classical DE approach of completely random vectors
quasiMethod = 's';
    % define type of quasi-random initial population generation
    % 'h' -- HALTON set
    % 's' -- SOBOL set
mutCon = 1;
    % starting value of mutation coefficient (F)
    % range = [0,2]
crossCon = 0.5;
    % starting value of cross-over constant (CR)
    % range = [0,1)
calcMax = 1;
    % define prior knowledge of problem solution
    % 0 -- for simulation purposes where mathematical solution is known
    % 1 -- for experimental purposes where solution (conventional culture
    %      condition/gold standard combination) is known as the positive
    %      control (PC)
numDimension = 14;
benchmarkName = 'rb';
maxRunAllowed = 7; % = maximum number of generations allowed - 1
popSizeFactor = 3;
replicate = 3;
minNumGoodVect = 1;
    % minimum number of source vectors required to initialize memory
    % structure and initiate memory structure information-driven vector
    % generation
numComb = popSizeFactor*numDimension;
    % population size (number of combinations tested per generation)
numFact = numDimension;

%%  ALGORITHM TERMINATION CONDITION PARAMETERS
redStatusF = 0;
redStatusCR = 0;
markCallMemory = 10;
    % generation number when vectors are marked to be replaced with
    % permutations of vectors in memory structure, initially set to '10' to
    % test dynamic implementation and activation of memory structure
    % information utilization
minParetoSize = 0.80;
minSimilarity = 0.50;
scoreProxThresh = 10; % desired score range threshold (%)
doseProxThresh = 10; % acceptable dose range threshold (%)
reqConvergCount = 3; % number of convergence occurences required
%	//////////////////////////////////////////////////////////////////////
%   Simulation condition settings
contVect = [0 0 0 1 0 0 0 0 0 0 0 0 0 0 0]; % define PC vector for calcMax = 0
intraVarComb = 10; % intra-experimental variability (%CV) to simulate
interVarComb = 10; % inter-experimental variability (%CV) to simulate

%%  EXPERIMENTAL CONDITION PARAMETERS
numChannel = 4;
seedingDensity = 5E5; % target initial seeding density (cells/ml)
cellName = 'Tcells';
baseMedia = 'DMEMF12';
wellTotVol = 100; % final culture volume (ul)
initialCount = seedingDensity*(wellTotVol/1000);
numCells = 0; % initialization step only
cultVol = 100; % (ul) volume of cell culture in each test formulation
assayVol = 100; % (ul) volume of cell culture removed from original
    % culture plate for count processing (entire culture volume is
    % processed for flow cytometry counting)
resuspVol = 100; % (ul) volume of culture resuspended in HF+7-AAD
sampleVol = 60; % (ul) volume taken from culture for cell count
plateSize = 96;
destRowWells = 8-2; % number of rows in destination plate (A,B,C, ..)
destColWells = 12-2; % number of columns in destination plate (1,2,3, ..)
numWells = destRowWells*destColWells; % number of wells in destination plate
numBlank = 0; % number of blank wells in destination plate
numSetsCP = 2; % max number of culture plate sets to generate
volDWPtoFP = 15; % (ul) fixed transfer volume from factor dilutions in DWP to vector formaultions in FP

%%  EXCEL SHEET READ/WRITE CELL RANGE
XdoseRangeR = 'C4:FF23'; XdoseRangeW = 'C4';
XfoldScoreR = 'C24:FF24'; XfoldScoreW = 'C24';
XlogScoreR = 'C25:FF25'; XlogScoreW = 'C25';
UdoseRangeR = 'C29:FF48'; UdoseRangeW = 'C29';
UfoldScoreR = 'C49:FF49'; UfoldScoreW = 'C49';
UlogScoreR = 'C50:FF50'; UlogScoreW = 'C50';
SelectionRangeR = 'C54:FF54'; SelectionRangeW = 'C54';
XfinRangeR = 'C58:FF67'; XfinRangeW = 'C58'; XfinAvgW = 'C68'; 
UfinRangeR = 'C70:FF79'; UfinRangeW = 'C70'; UfinAvgW = 'C80';
NCfinRangeR = 'C84:C93'; NCfinRangeW = 'C84'; NCfinAvgW = 'C94';
PCfinRangeR = 'D84:D93'; PCfinRangeW = 'D84'; PCfinAvgW = 'D94';
NCfoldScoreW = 'C98'; PCfoldScoreW = 'D98';
NClogScoreW = 'C99'; PClogScoreW = 'D99';
%   sheetname = 'Reagent Cf'
allListRange = 'C4:C17'; % range of factor names (text)
KeyRange = 'I4:N17'; StockRange ='G4:G17';
% KeyRangeLow = 'FI29:FS48'; KeyRangeHigh = 'FI54:FS73';
% BlankRange = 'H38:K38';

% DataRange = 'W2:W93'; % batch analysis data range
% DataRange for fortessa batch analysis export ..
% upto & including run #2 G2 (original) M2:M321
% starting at run #2 G3 (P3 count)      Q2:Q93
% starting at run #2 G3 (live count)    U2:U93
% starting at run #3 G3 (live count)    W2:W93
% DataRange for flowjo batch analysis export ..
% starting at run #3 G1 (live count)    C2:C93

%   CytoFlex batch analysis data range:
DataRange = 'J5:J124';
ViabilityRange = 'AB5:AB124';

%%  GENERAL ALGORITHM RUN PARAMETERS
run = 0;
vectorState = [];
TopVectors = [];
GoodiesPool = [];
BetterPool = [];
BetterVectors = [];
lastGoodies = 0;
lastBested = 0;
TabuList = [];
NumSelectedLog = [];
SeriesValues = [];
SeriesValuesL = [];
RankSumLog = [];
NumImproveLog = [];
NumConvergLog = [];
Xselect = [];
countVectors = 0;
textWidth = 76;
terminateOptim = 0;
maxRankSum = sum(replicate+1:replicate*2)*numComb;
ParetoPlotData = NaN(1,2);
NumTestVectors = [];
convergCount = 0;
TermCondData = [];
CarryScore = NaN(1,numComb);
reset = 0;
updateStatus = 0;
supplTotVol = 0; % to be calculated upon command generation
detailsFile = [];
resvTubNum = 0;