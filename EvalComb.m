function EvalComb(cFile)

%   Function evaluates the set of target vectors (X) and trial vectors (U)
%   defined for the current generation ('run') according to the objective
%   function.

global filename numComb sheetname run replicate expMaximum fHeader cellCount
global numCells assayVol resuspVol sampleVol cultVol
global destRowWells destColWells avgEM NCint initialCount Xfin Ufin NCfin PCfin
global DataRange Xint Uint PCint XfinRangeW XfinAvgW UfinRangeW UfinAvgW ViabilityRange 
global XfoldScoreW UfoldScoreW NCfoldScoreW PCfoldScoreW
global NCfinRangeW NCfinAvgW PCfinRangeW PCfinAvgW BlankRange XlogScoreW
global UlogScoreW NClogScoreW PClogScoreW CombList VectorSet

global DataSet

%   Extract cell count data from CytoFlex batch analysis stats file.
if run == 1
    DataSet = struct('RepSet',{});
end
for i=1:replicate
    SheetName = ['Sheet' num2str(i)];
    [~,name,~] = xlsread(cFile,SheetName,'A5:A124');
    A = {};
    for s=1:size(name,1)
        A(s,:) = strsplit(name{s,1},'-');
    end
    idx = find(strcmp(A(:,2),'PosCont')); A(idx,3) = A(idx,2);
    idx = find(strcmp(A(:,2),'NegCont')); A(idx,3) = A(idx,2);
    B = reshape(A(:,3),[10,12]);
    C = transpose(B);
    colvectC = [reshape(C(1:6,:),[60,1]); reshape(C(7:12,:),[60,1])];
    DataSet(run).RepSet(i).wellID = colvectC;
    
    A = xlsread(cFile,SheetName,DataRange);
    B = reshape(A,[10,12]);
    C = transpose(B);
    colvectC = [reshape(C(1:6,:),[60,1]); reshape(C(7:12,:),[60,1])];
    DataSet(run).RepSet(i).liveCount = colvectC;
    
    if isempty(DataSet(run).RepSet(i))
        disp('Error -- Repeat line 18'); beep; keyboard;
    end
end
disp('Check final cell count data imported & volumes ...');
disp(['        assay volume for cell count = ' num2str(assayVol) ' ul']);
disp(['        resuspension volume in HF+7-AAD = ' num2str(resuspVol) ' ul']);
disp(['        volume of cell sample taken from culture = ' num2str(sampleVol) ' ul']);
cellCtMult = (resuspVol/assayVol)*(cultVol/sampleVol); % multiplication
    % factor to estimate number of cells in original culture volume
    % based on cell count from sample volume
disp('Check volumes + F5 to continue'); keyboard;

%   Calculate final cell count and populate template datafile.
outArrPC = []; outArrNC = []; outArrX = []; outArrU = [];
for i=1:replicate
    DataSet(run).RepSet(i).liveCells = DataSet(run).RepSet(i).liveCount*cellCtMult; % estimate number of cells in 100 ul from cell count data from 60 ul sample
    outArrPC = [outArrPC; transpose(DataSet(run).RepSet(i).liveCells(1,1))];
    outArrNC = [outArrNC; transpose(DataSet(run).RepSet(i).liveCells(2,1))];
    outArrX = [outArrX; transpose(DataSet(run).RepSet(i).liveCells(3:numComb+2))];
    outArrU = [outArrU; transpose(DataSet(run).RepSet(i).liveCells(numComb+3:end))];
    DataSet(run).RepSet(i).foldChg = DataSet(run).RepSet(i).liveCells/numCells;
end
xlswrite(filename,outArrX,sheetname,XfinRangeW);
xlswrite(filename,mean(outArrX),sheetname,XfinAvgW);
xlswrite(filename,outArrU,sheetname,UfinRangeW);
xlswrite(filename,mean(outArrU),sheetname,UfinAvgW);
xlswrite(filename,outArrNC,sheetname,NCfinRangeW);
xlswrite(filename,mean(outArrNC),sheetname,NCfinAvgW);
xlswrite(filename,outArrPC,sheetname,PCfinRangeW);
xlswrite(filename,mean(outArrPC),sheetname,PCfinAvgW);

%   Calculate average fold change to populate template datafile.
outArrPC = []; outArrNC = []; outArrX = []; outArrU = [];
for i=1:replicate
    outArrPC = [outArrPC; DataSet(run).RepSet(i).foldChg(1,1)];
    outArrNC = [outArrNC; DataSet(run).RepSet(i).foldChg(2,1)];
    outArrX = [outArrX; transpose(DataSet(run).RepSet(i).foldChg(3:numComb+2))];
    outArrU = [outArrU; transpose(DataSet(run).RepSet(i).foldChg(numComb+3:end))];
end
xlswrite(filename,mean(outArrPC),sheetname,PCfoldScoreW);
xlswrite(filename,mean(outArrNC),sheetname,NCfoldScoreW);
xlswrite(filename,mean(outArrX,1),sheetname,XfoldScoreW);
xlswrite(filename,mean(outArrU,1),sheetname,UfoldScoreW);

%   Calculate CV of positive control fold change to estimate
%   inter-experimental (between generation) variability.
DataSet(run).avgPosFC = mean(outArrPC);
DataSet(run).posContCV = std(outArrPC)/mean(outArrPC);
DataSet(run).avgNegFC = mean(outArrNC);

for i=1:replicate
    posFC = DataSet(run).RepSet(i).foldChg(1,1);
    negFC = DataSet(run).RepSet(i).foldChg(2,1);
    DataSet(run).RepSet(i).normFC = DataSet(run).RepSet(i).foldChg/posFC;
    
    %   Sort PC-normalized fold change scores and vector IDs for each set.
    tempX = flipud(sortrows([transpose(1:numComb) DataSet(run).RepSet(i).normFC(3:numComb+2)],2));
    tempU = flipud(sortrows([transpose(1:numComb) DataSet(run).RepSet(i).normFC(numComb+3:end)],2));
    DataSet(run).XsortNormFC(:,i) = tempX(:,2); DataSet(run).XsortID(:,i) = tempX(:,1);
    DataSet(run).UsortNormFC(:,i) = tempU(:,2); DataSet(run).UsortID(:,i) = tempU(:,1);
end

%   Calculate CV for each of the test vectors.
outArrX = []; outArrU = [];
for i=1:replicate
    outArrX = [outArrX; transpose(DataSet(run).RepSet(i).normFC(3:numComb+2))];
    outArrU = [outArrU; transpose(DataSet(run).RepSet(i).normFC(numComb+3:end))];
end
for i=1:numComb
    DataSet(run).XsetCV(i,1) = std(outArrX(:,i))/mean(outArrX(:,i));
    DataSet(run).UsetCV(i,1) = std(outArrU(:,i))/mean(outArrU(:,i));
end

%   Plot option 1 - scatter
figure1 = figure;
axes1 = axes('Parent',figure1);
hold(axes1,'on');
Xrange = [1:numComb*2];
scatter(Xrange,DataSet(run).RepSet(1).normFC(3:end),'DisplayName','Set 1',...
    'MarkerEdgeColor',[0.929411768913269 0.694117665290833 0.125490203499794]);
scatter(Xrange,DataSet(run).RepSet(2).normFC(3:end),'DisplayName','Set 2',...
    'MarkerEdgeColor',[0.850980401039124 0.325490206480026 0.0980392172932625]);
scatter(Xrange,DataSet(run).RepSet(3).normFC(3:end),'DisplayName','Set 3',...
    'MarkerEdgeColor',[0 0.447058826684952 0.74117648601532]);
xlabel('Vector ID');
ylabel('PosCont-normalized fold change');
ylim(axes1,[0 1]);
legend(axes1,'show');

%   Plot option 2 - line
figure1 = figure;
axes1 = axes('Parent',figure1);
hold(axes1,'on');
plot(DataSet(run).RepSet(1).normFC(3:end),'DisplayName','Set 1',...
    'MarkerSize',3,'Marker','o','Parent',axes1,...
    'MarkerFaceColor',[0 0.447058826684952 0.74117648601532],...
    'Color',[0 0.447058826684952 0.74117648601532]);
plot(DataSet(run).RepSet(2).normFC(3:end),'DisplayName','Set 2',...
    'MarkerSize',3,'Marker','o','Parent',axes1,...
    'MarkerFaceColor',[0.850980401039124 0.325490206480026 0.0980392172932625],...
    'Color',[0.850980401039124 0.325490206480026 0.0980392172932625]);
plot(DataSet(run).RepSet(3).normFC(3:end),'DisplayName','Set 3',...
    'MarkerSize',3,'Marker','o','Parent',axes1,...
    'MarkerFaceColor',[0.929411768913269 0.694117665290833 0.125490203499794],...
    'Color',[0.929411768913269 0.694117665290833 0.125490203499794]);
xlabel('Vector ID');
ylabel('PosCont-normalized fold change');
ylim(axes1,[0 1]);

arrNormFC = [];
for i=1:2+numComb*2
    for j=1:replicate
        arrNormFC(i,j) = DataSet(run).RepSet(j).normFC(i,1);
    end
    DataSet(run).avgNormFC(i,1) = mean(arrNormFC(i,:));
end
xlswrite(filename,transpose(DataSet(run).avgNormFC(1,1)),sheetname,PClogScoreW);
xlswrite(filename,transpose(DataSet(run).avgNormFC(2,1)),sheetname,NClogScoreW);
xlswrite(filename,transpose(DataSet(run).avgNormFC(3:numComb+2,1)),sheetname,XlogScoreW);
xlswrite(filename,transpose(DataSet(run).avgNormFC(numComb+3:end,1)),sheetname,UlogScoreW);

plot(DataSet(run).avgNormFC(3:end),'DisplayName','Average',...
    'MarkerSize',4,'Marker','*','Parent',axes1,'LineStyle',':',...
    'MarkerFaceColor',[0.494117647409439 0.184313729405403 0.556862771511078],...
    'Color',[0.494117647409439 0.184313729405403 0.556862771511078]);
legend(axes1,'show');
figurename = [fHeader '_G' num2str(run,'%02i') '_plot'];
saveas(figure1,figurename,'fig');

close all

newname = [fHeader '_G' num2str(run,'%02i') ' cell count.xlsx'];
movefile(cFile,newname); % rename datafile name