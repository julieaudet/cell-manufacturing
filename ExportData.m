function ExportData

global run filename numFact numComb markCallMemory firstGen
global TabuList NumSelectedLog SeriesValues SeriesValuesL
global TopVectors RankSumLog WinScoreLog WinScoreLogL 
global NumImproveLog NumConvergLog VectorProxLog VectorProxLog2 
global ScoreProxLog TrackProxLog TrackProxLog2 GoodiesPool 
global SelectedVectors ParetoPlotData NumTestVectors TermCondData
global ParetoSimData DistCountP DistCountV

headerRow = cell(1,numFact);
headerCol = cellstr('vectors tested');
for i=1:numFact
    headerRow(1,i) = cellstr(['factor #' num2str(i)]);
end
desc = cellstr('list of all vectors tested');
xlswrite(filename,desc,'TabuList','A1');
xlswrite(filename,headerRow,'TabuList','B2');
xlswrite(filename,headerCol,'TabuList','A3');
xlswrite(filename,TabuList,'TabuList','B3');
if ~isempty(SeriesValues)
    headerRow = cell(1,numComb);
    headerCol = cell(run,1);
    for i=1:numComb
        headerRow(1,i) = cellstr(['vector #' num2str(i,'%02i')]);
    end
    for i=1:run
        headerCol(i,1) = cellstr(['gen #' num2str(i,'%02i')]);
    end
    desc = cellstr('score of each vector through the generations');
    xlswrite(filename,desc,'SeriesValues','A1');
    xlswrite(filename,headerRow,'SeriesValues','B2');
    xlswrite(filename,headerCol,'SeriesValues','A3');
    xlswrite(filename,transpose(SeriesValues),'SeriesValues','B3');
    desc = cellstr('log exp fold change of each vector through the generations');
    xlswrite(filename,desc,'SeriesValues(Log)','A1');
    xlswrite(filename,headerRow,'SeriesValues(Log)','B2');
    xlswrite(filename,headerCol,'SeriesValues(Log)','A3');
    xlswrite(filename,transpose(SeriesValuesL),'SeriesValues(Log)','B3');
end

if ~isempty(TopVectors)
    [~,n] = size(TopVectors);
    headerRow = cell(1,n);
    headerCol = cell(numFact+1,1);
    for i=1:n
        headerRow(1,i) = cellstr(['topVect #' num2str(i,'%02i')]);
    end
    for i=1:numFact
        headerCol(i,1) = cellstr(['factor #' num2str(i)]);
    end
    headerCol(numFact+1,1) = cellstr('score');
    desc = cellstr('best performing vectors (within variability threshold of top score)');
    xlswrite(filename,desc,'TopVectors','A1');
    xlswrite(filename,headerRow,'TopVectors','B2');
    xlswrite(filename,headerCol,'TopVectors','A3');
    xlswrite(filename,TopVectors,'TopVectors','B3');
end

if ~isempty(GoodiesPool)
    [~,n] = size(GoodiesPool);
    headerRow = cell(1,n);
    for i=1:n
        headerRow(1,i) = cellstr(['goodVect #' num2str(i,'%02i')]);
    end
    desc = cellstr('vectors generated using selected vectors from TopVectors');
    xlswrite(filename,desc,'GoodiesPool','A1');
    xlswrite(filename,headerRow,'GoodiesPool','B2');
    xlswrite(filename,headerCol,'GoodiesPool','A3');
    xlswrite(filename,GoodiesPool,'GoodiesPool','B3');
end

if ~isempty(NumSelectedLog)
    headerRow = cellstr('# vectors selected');
    headerCol = cell(run,1);
    for i=1:run
        headerCol(i,1) = cellstr(['gen #' num2str(i,'%02i')]);
    end
    desc = cellstr('number of vectors selected (between X and U) in each generation');
    xlswrite(filename,desc,'NumSelected(Log)','A1');
    xlswrite(filename,headerRow,'NumSelected(Log)','B2');
    xlswrite(filename,headerCol,'NumSelected(Log)','A3');
    xlswrite(filename,NumSelectedLog,'NumSelected(Log)','B3');
end

if ~isempty(RankSumLog)
    headerRow = cellstr('pop rank sum');
    desc = cellstr('population rank sum of each generation by wilcoxon rank sum test');
    xlswrite(filename,desc,'RankSumLog','A1');
    xlswrite(filename,headerRow,'RankSumLog','B2');
    xlswrite(filename,headerCol,'RankSumLog','A3');
    xlswrite(filename,RankSumLog,'RankSumLog','B3');
end

if ~isempty(WinScoreLog) && ~isempty(WinScoreLogL)
    headerRow = cell(1,numComb);
    for i=1:numComb
        headerRow(1,i) = cellstr(['vector #' num2str(i,'%02i')]);
    end
    desc = cellstr('score of the winning combinations at each vector position through the generations');
    xlswrite(filename,desc,'WinScoreLog','A1');
    xlswrite(filename,headerRow,'WinScoreLog','B2');
    xlswrite(filename,headerCol,'WinScoreLog','A3');
    xlswrite(filename,WinScoreLog,'WinScoreLog','B3');
    desc = cellstr('log cell exp fold change of the winning combinations at each vector position through the generations');
    xlswrite(filename,desc,'WinScoreLog(Log)','A1');
    xlswrite(filename,headerRow,'WinScoreLog(Log)','B2');
    xlswrite(filename,headerCol,'WinScoreLog(Log)','A3');
    xlswrite(filename,WinScoreLogL,'WinScoreLog(Log)','B3');
end

if ~isempty(VectorProxLog) && ~isempty(VectorProxLog2)
    headerRow = cell(1,numComb);
    for i=1:numComb
        headerRow(1,i) = cellstr(['vector #' num2str(i,'%02i')]);
    end
    desc = cellstr('# of factors in each vector within SelectedVectors within the +/- dose range of the expected combination');
    xlswrite(filename,desc,'VectorProxLog','A1');
    xlswrite(filename,headerRow,'VectorProxLog','B2');
    xlswrite(filename,headerCol,'VectorProxLog','A3');
    xlswrite(filename,VectorProxLog,'VectorProxLog','B3');
    desc = cellstr('# of factors in each vector within SelectedVectors within +/- 1 dose level of the expected combination');
    xlswrite(filename,desc,'VectorProxLog(coded)','A1');
    xlswrite(filename,headerRow,'VectorProxLog(coded)','B2');
    xlswrite(filename,headerCol,'VectorProxLog(coded)','A3');
    xlswrite(filename,VectorProxLog2,'VectorProxLog(coded)','B3');
end

if ~isempty(ScoreProxLog)
    headerRow = cell(1,2);
    headerRow(1,1) = cellstr('desired score range');
    headerRow(1,2) = cellstr('assessed var range');
    desc = cellstr('# vectors that fall within the specified performance range in each generation');
    xlswrite(filename,desc,'ScoreProxLog','A1');
    xlswrite(filename,headerRow,'ScoreProxLog','B2');
    xlswrite(filename,headerCol,'ScoreProxLog','A3');
    xlswrite(filename,ScoreProxLog,'ScoreProxLog','B3');
end

if ~isempty(TrackProxLog) && ~isempty(TrackProxLog2)
    headerRow = cell(1,15);
    headerRow(1,1) = cellstr('all factors in vector');
    headerRow(1,4) = cellstr('75%+ factors in vector');
    headerRow(1,7) = cellstr('50%+ factors in vector');
    headerRow(1,10) = cellstr('25%+ factors in vector');
    headerRow(1,13) = cellstr('<25% factors in vector');
    for i=1:5
        headerRow(1,3*i-1) = cellstr('& within score range');
        headerRow(1,3*i) = cellstr('& within var range');
    end
    desc = cellstr('# vectors with the specified dose & score proximities to the expected combination/performance');
    xlswrite(filename,desc,'TrackProxLog','A1');
    xlswrite(filename,headerRow,'TrackProxLog','B2');
    xlswrite(filename,headerCol,'TrackProxLog','A3');
    xlswrite(filename,TrackProxLog,'TrackProxLog','B3');
    desc = cellstr('# vectors with the specified dose & log exp proximities to the expected combination/performance');
    xlswrite(filename,desc,'TrackProxLog(coded)','A1');
    xlswrite(filename,headerRow,'TrackProxLog(coded)','B2');
    xlswrite(filename,headerCol,'TrackProxLog(coded)','A3');
    xlswrite(filename,TrackProxLog2,'TrackProxLog(coded)','B3');
end

if ~isempty(NumImproveLog)
    headerRow = cellstr('count');
    desc = cellstr('# vectors converging into range of best performance of generation');
    xlswrite(filename,desc,'NumImproveLog','A1');
    xlswrite(filename,headerRow,'NumImproveLog','B2');
    xlswrite(filename,headerCol,'NumImproveLog','A3');
    xlswrite(filename,NumImproveLog,'NumImproveLog','B3');
end

if ~isempty(NumConvergLog)
    headerRow = cellstr('count');
    desc = cellstr('# vectors converging into expected performance range');
    xlswrite(filename,desc,'NumConvergLog','A1');
    xlswrite(filename,headerRow,'NumConvergLog','B2');
    xlswrite(filename,headerCol,'NumConvergLog','A3');
    xlswrite(filename,NumConvergLog,'NumConvergLog','B3');
end

if ~isempty(SelectedVectors)
    headerRow = cell(1,numComb);
    for i=1:numComb
        headerRow(1,i) = cellstr(['vector #' num2str(i,'%02i')]);
    end
    desc = cellstr('Pareto Set of SelectedVectors');
    headerCol = cell(numFact+1,1);
    for i=1:numFact
        headerCol(i,1) = cellstr(['factor #' num2str(i)]);
    end
    headerCol(numFact+1,1) = cellstr('score');
    xlswrite(filename,desc,'ParetoSet','A1');
    xlswrite(filename,headerRow,'ParetoSet','B2');
    xlswrite(filename,headerCol,'ParetoSet','A3');
    xlswrite(filename,SelectedVectors,'ParetoSet','B3');
end

if ~isempty(NumTestVectors)
    headerRow = cellstr('count');
    desc = cellstr('total number of vectors tested upto each generation');
    headerCol = cell(run,1);
    for i=1:run
        headerCol(i,1) = cellstr(['gen #' num2str(i,'%02i')]);
    end
    xlswrite(filename,desc,'NumTestVectors','A1');
    xlswrite(filename,headerRow,'NumTestVectors','B2');
    xlswrite(filename,headerCol,'NumTestVectors','A3');
    xlswrite(filename,NumTestVectors,'NumTestVectors','B3');
end

if ~isempty(TermCondData)
    headerRow = cell(1,numComb+1);
    headerRow(1,1) = cellstr('score');
    for i=1:numComb
        headerRow(1,i+1) = cellstr(['vector #' num2str(i,'%02i')]);
    end
    desc = cellstr('Termination condition evaluation data: countSimilar = # factors in each vector in consecutive lineage within 1 dose of each other');
    headerCol = cell(7*run,2);
    for i=markCallMemory+2:run
        headerCol(7*(i-1)+1:7*(i-1)+7,1) = cellstr(['gen #' num2str(i,'%02i')]);
        headerCol(7*(i-1)+1,2) = cellstr('convergCount (start)');
        headerCol(7*(i-1)+2,2) = cellstr('set1 scores');
        headerCol(7*(i-1)+3,2) = cellstr('set1 median');
        headerCol(7*(i-1)+4,2) = cellstr('set2 scores');
        headerCol(7*(i-1)+5,2) = cellstr('set2 median');
        headerCol(7*(i-1)+6,2) = cellstr('countSimilar');
        headerCol(7*(i-1)+7,2) = cellstr('convergCount (end)');
    end
    xlswrite(filename,desc,'TermCondData','A1');
    xlswrite(filename,headerRow,'TermCondData','B3');
    xlswrite(filename,headerCol,'TermCondData','A3');
    xlswrite(filename,TermCondData,'TermCondData','C3');
end

if ~isempty(ParetoSimData)
    headerRow = cell(1,numComb+1);
    headerRow(1,1) = cellstr('count');
    for i=1:numComb
        headerRow(1,i+1) = cellstr(['vector #' num2str(i,'%02i')]);
    end
    desc = cellstr('Evaluation of vector similarity with Hamming & Levenshtein distance counts');
    headerCol = cell(3*run,2);
    for i=firstGen:run
        headerCol(3*(i-1)+1:3*(i-1)+4,1) = cellstr(['gen #' num2str(i,'%02i')]);
        headerCol(3*(i-1)+1,2) = cellstr('Hamming');
        headerCol(3*(i-1)+2,2) = cellstr('Levenshtein');
        headerCol(3*(i-1)+3,2) = cellstr('Sørensen-Dice');
        headerCol(3*(i-1)+4,2) = cellstr('Median');
    end
    ParetoSimData = [ParetoSimData; SelectedVectors(numFact+1,:)];
    xlswrite(filename,desc,'ParetoSimData','A1');
    xlswrite(filename,headerRow,'ParetoSimData','B2');
    xlswrite(filename,headerCol,'ParetoSimData','A3');
    xlswrite(filename,ParetoSimData,'ParetoSimData','C3');
end

if ~isempty(DistCountV)
    headerRow = cell(1,6);
    headerRow(1,1) = cellstr('count');
    headerRow(1,2) = cellstr('leven = hamm+3 or more');
    headerRow(1,3) = cellstr('leven = hamm+2');
    headerRow(1,4) = cellstr('leven = hamm+1');
    headerRow(1,5) = cellstr('each 1 dose diff');
    headerRow(1,6) = cellstr('exact solution');
    desc = cellstr('Count of similarity distribution occurrences between pareto set at each gen and the known solution vector');
    headerCol = cell(run-firstGen+1,1);
    for i = firstGen:run
        headerCol(i,1) = cellstr(['gen #' num2str(i,'%02i')]);
    end
    xlswrite(filename,desc,'solVSParetoSim','A1');
    xlswrite(filename,headerRow,'solVSParetoSim','B2');
    xlswrite(filename,headerCol,'solVSParetoSim','A3');
    xlswrite(filename,DistCountV,'solVSParetoSim','C3');
end