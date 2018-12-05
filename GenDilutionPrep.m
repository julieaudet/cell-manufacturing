function GenDilutionPrep

global XdoseRangeR UdoseRangeR
global filename sheetname numFact numComb numDose numChannel wellcodeS
global volDWPtoFP fHeader makeDWP factorNameList wellTotVol run numSetsCP
global CombList Key Stock DilutionPrep

F1000_cutoffvol = 970; F300_cutoffvol = 270; F50_cutoffvol = 40;
volFPtoCulture = 70; volDWPdead = 150; numExtraWells = 25;

%   Read in coded dose levels
Xdose = xlsread(filename,sheetname,XdoseRangeR);
Udose = xlsread(filename,sheetname,UdoseRangeR);
Xdose = Xdose + 1;
Udose = Udose + 1;

%   Calculate number of wells for each factor and dose level for transfer
%   from SourceDiltuionPlate to FormulationPlate
DilutionPrep = struct('StockConc',{},'TopConc',{},'PrepNumWells',{}, ...
    'PrepVolWell',{},'VolTopConc',{},'VolMedia',{});
outputdata = NaN(numFact,1);
targetConcFP = wellTotVol*Key/volFPtoCulture;
targetConcDWP = targetConcFP*(numFact*volDWPtoFP)/volDWPtoFP;
for prepDay=1:3
    switch prepDay
        case 1,
            filename1 = [fHeader '_G' num2str(run,'%02i') ' Outputfile (' num2str(prepDay) ') prepx2.xls'];
            setsPlating = numSetsCP;
            volDWPtoFP_toPrep = volDWPtoFP;
        case 2,
            filename1 = [fHeader '_G' num2str(run,'%02i') ' Outputfile (' num2str(prepDay) ') prepx1.xls'];
            setsPlating = numSetsCP/2;
            volDWPtoFP_toPrep = volDWPtoFP/2;
        case 3,
            filename1 = [fHeader '_G' num2str(run,'%02i') ' Outputfile_fullprepx3.xls'];
            setsPlating = 3;
            volDWPtoFP_toPrep = (volDWPtoFP+2.5);
    end
    for i=1:numFact
        DilutionPrep(i).StockConc = Stock(i,1);
        DilutionPrep(i).TopConc = targetConcDWP(i,numDose(i,1));
        for j=1:numDose(i,1)
            DilutionPrep(i).PrepNumWells(1,j) = ((nnz(find(Xdose(i,:)==j))+nnz(find(Udose(i,:)==j))))+numExtraWells;
                % volume needed for each factor [] prepared in
                % SourceDilutionPlate including extra wells prepared
            DilutionPrep(i).PrepVolWell(1,j) = (DilutionPrep(i).PrepNumWells(1,j)*volDWPtoFP_toPrep)+volDWPdead;
                % volume needed for each factor [] prepared in SourceDilutionPlate
            DilutionPrep(i).VolTopConc(1,j) = targetConcDWP(i,j)*DilutionPrep(i).PrepVolWell(1,j)/DilutionPrep(i).TopConc;
            DilutionPrep(i).VolMedia(1,j) = DilutionPrep(i).PrepVolWell(1,j) - DilutionPrep(i).VolTopConc(1,j);
        end
        %   To make sufficient volume of highest concentration sample of each
        %   factor, need..
        DilutionPrep(i).HiPrepReagent = sum(DilutionPrep(i).VolTopConc)*DilutionPrep(i).TopConc/DilutionPrep(i).StockConc;
        DilutionPrep(i).HiPrepMedia = sum(DilutionPrep(i).VolTopConc)-DilutionPrep(i).HiPrepReagent;
    end % Prepare highest concentration sample in DWP prior to loading into
    % liquid handler.
    
    %   Sanity check..
    S = NaN(numFact,1);
    for s=1:numFact
        S(s,1) = sum(DilutionPrep(s).PrepNumWells(1,:));
    end
    W = numDose*numExtraWells; S = S-W;
    if all(S == numComb*2)
        disp('Number of wells prepared sufficient');
    else
        disp('Check number of wells prepared + F5 to continue'); keyboard;
    end
    
    %   Generate transfer commands to complete dilutions in DWP
    wellcodeDWP = [wellcodeS(:,1:6); wellcodeS(:,7:12)];
    xlswrite(filename1,wellcodeDWP(:,6),'Dilution prep DWP','B2');
    xlswrite(filename1,wellcodeDWP(:,6),'Dilution prep DWP','E2');
    for i=1:size(numDose,1)
        if numDose(i,1) ~= size(wellcodeDWP,2)
            wellcodeDWP(i,numDose(i,1)) = wellcodeDWP(i,size(wellcodeDWP,2));
            for j=numDose(i,1)+1:size(wellcodeDWP,2)
                wellcodeDWP{i,j} = [];
            end
        end
    end
    for i=1:numFact
        outputdata(i,1) = DilutionPrep(i).HiPrepMedia;
    end
    xlswrite(filename1,outputdata,'Dilution prep DWP','C2');
    for i=1:numFact
        outputdata(i,1) = DilutionPrep(i).HiPrepReagent;
    end
    xlswrite(filename1,outputdata,'Dilution prep DWP','G2');
    xlswrite(filename1,factorNameList,'Dilution prep DWP','F2');
    colheader = [cellstr('DWP well ID') 'Media vol (ul)' ' ' 'DWP well ID' 'Reagent name' 'Reagent vol (ul)'];
    xlswrite(filename1,colheader,'Dilution prep DWP','B1');
    for i=1:numFact
        for j=1:numDose(i,1)-1
            makeDWP(i).DestWell(1,j) = wellcodeDWP(i,j);
            makeDWP(i).SourceTub(1,j) = 'Z'; % take from media reservoir
            makeDWP(i).VolMedia(1,j) = DilutionPrep(i).VolMedia(1,j);
            makeDWP(i).SourceWell(1,j) = wellcodeDWP(i,numDose(i,1));
            makeDWP(i).VolTopConc(1,j) = DilutionPrep(i).VolTopConc(1,j);
        end
    end
    
    e_process = actxserver('excel.application');
    activeFile = [pwd '\' filename1];
    e_file_source = e_process.Workbooks.Open(activeFile);
    e_process.ActiveWorkbook.Worksheets.Item('Sheet1').Delete;
    e_process.ActiveWorkbook.Worksheets.Item('Sheet2').Delete;
    e_process.ActiveWorkbook.Worksheets.Item('Sheet3').Delete;
    e_file_source.Save;
    e_process.Quit;
    
    makeDWPcmds = [];
    for i=1:max(numDose)
        for j=1:numChannel
            if i <= numel(makeDWP(j).DestWell)
                makeDWPcmds = [makeDWPcmds; transpose(num2cell(makeDWP(j).SourceTub(1,i))) transpose(makeDWP(j).DestWell(1,i)) transpose(num2cell(makeDWP(j).VolMedia(1,i)))];
            end
        end
    end
    for i=1:max(numDose)
        for j=numChannel+1:numFact
            if i <= numel(makeDWP(j).DestWell)
                makeDWPcmds = [makeDWPcmds; transpose(num2cell(makeDWP(j).SourceTub(1,i))) transpose(makeDWP(j).DestWell(1,i)) transpose(num2cell(makeDWP(j).VolMedia(1,i)))];
            end
        end
    end
    for i=1:max(numDose)
        for j=1:numChannel
            if i <= numel(makeDWP(j).DestWell)
                makeDWPcmds = [makeDWPcmds; transpose(makeDWP(j).SourceWell(1,i)) transpose(makeDWP(j).DestWell(1,i)) transpose(num2cell(makeDWP(j).VolTopConc(1,i)))];
            end
        end
    end
    for i=1:max(numDose)
        for j=numChannel+1:numFact
            if i <= numel(makeDWP(j).DestWell)
                makeDWPcmds = [makeDWPcmds; transpose(makeDWP(j).SourceWell(1,i)) transpose(makeDWP(j).DestWell(1,i)) transpose(num2cell(makeDWP(j).VolTopConc(1,i)))];
            end
        end
    end
    A = cell2mat(makeDWPcmds(:,3));
    makeDWPcmds(A(:,1)==0,:)=[];
    xlswrite(filename1,makeDWPcmds,'DPCmds_fullVolCheck','A2');
    colheader = [cellstr('Source well') 'Dest well' 'Volume'];
    xlswrite(filename1,colheader,'DPCmds_fullVolCheck','A1');
    
    %   Check dilution volumes prepared for each well in DWP
    dilTargetWells = reshape(wellcodeDWP,[numel(wellcodeDWP),1]);
    emptyCells = cellfun('isempty',dilTargetWells); dilTargetWells(all(emptyCells,2),:) = [];
    volT = makeDWPcmds(:,3);
    for t=1:length(dilTargetWells)
        idx = strcmp(dilTargetWells{t,1},makeDWPcmds(:,2));
        dilTargetWells(t,2) = num2cell(sum(cell2mat(volT(idx))));
    end
    dilTargetWells = sortrows(dilTargetWells,1); openvar('dilTargetWells');
    
    %   Split transfer volumes greater than 1000 ul (for media) or 300 ul
    %   (for reagent) into multiple transfer commands.
    lastRow = nnz(find(strcmp(makeDWPcmds(:,1),'Z')));
    makeDWPmedia = makeDWPcmds(1:lastRow,:);
    totalMedia = sum(cell2mat(makeDWPmedia(:,3)))/1000;
    xlswrite(filename1,totalMedia,'Dilution prep DWP','I14');
    colheader = cellstr('Media volume required (ml)');
    xlswrite(filename1,colheader,'Dilution prep DWP','I13');
    totalMedia = totalMedia + 7.5;
    xlswrite(filename1,totalMedia,'Dilution prep DWP','I17');
    colheader = cellstr('Media volume to load in reservoir (ml)');
    xlswrite(filename1,colheader,'Dilution prep DWP','I16');
    
    s = size(makeDWPmedia,1);
    rowInd = 1;
    while rowInd <= s
        if makeDWPmedia{rowInd,3} > F1000_cutoffvol
            splitVol = makeDWPmedia(rowInd,:);
            splitVol{1,3} = makeDWPmedia{rowInd,3} - F1000_cutoffvol;
            makeDWPmedia = [makeDWPmedia; splitVol];
            makeDWPmedia{rowInd,3} = F1000_cutoffvol;
        end
        rowInd = rowInd+1;
        s = size(makeDWPmedia,1);
    end
    makeDWPreagents = makeDWPcmds(lastRow+1:end,:);
    s = size(makeDWPreagents,1);
    rowInd = 1;
    while rowInd <= s
        if makeDWPreagents{rowInd,3} > F300_cutoffvol
            splitVol = makeDWPreagents(rowInd,:);
            splitVol{1,3} = makeDWPreagents{rowInd,3} - F300_cutoffvol;
            makeDWPreagents = [makeDWPreagents; splitVol];
            makeDWPreagents{rowInd,3} = F300_cutoffvol;
        end
        rowInd = rowInd+1;
        s = size(makeDWPreagents,1);
    end
    makeDWPcmdsSplitVol = [makeDWPmedia; makeDWPreagents];
    xlswrite(filename1,makeDWPcmdsSplitVol,'DilutionPlateCmds','A2');
    colheader = [cellstr('Source well') 'Dest well' 'Volume'];
    xlswrite(filename1,colheader,'DilutionPlateCmds','A1');
    
    %   Build FORMULATION PLATE transfer instructions
    makeFPCmds = [];
    rowstart = 0;
    while rowstart+numChannel <= numComb*2
        for i=1:numFact
            for j=1:numChannel
                if any(~isnan(CombList(rowstart+j).dose))
                    makeFPCmds = [makeFPCmds; num2cell(CombList(rowstart+j).plateNum) CombList(rowstart+j).wellName num2cell(i) num2cell(CombList(rowstart+j).dose(1,i))];
                else
                end
            end
        end
        rowstart = rowstart+numChannel;
    end
    if rowstart+numChannel > numComb*2
        for i=1:numFact
            for j=1:numComb*2-rowstart
                if any(~isnan(CombList(rowstart+j).dose))
                    makeFPCmds = [makeFPCmds; num2cell(CombList(rowstart+j).plateNum) CombList(rowstart+j).wellName num2cell(i) num2cell(CombList(rowstart+j).dose(1,i))];
                end
            end
        end
    end
    
    %   Replace [reagent # (col 3) and dose level (col 4)] information with
    %   dilution plate DWP well ID containing corresponding dilution.
    for i=1:size(makeFPCmds,1)
        reagentNum = makeFPCmds{i,3};
        dilutionNum = makeFPCmds{i,4}+1;
        sourceIDwell(i,1) = wellcodeDWP(reagentNum,dilutionNum);
    end
    fixedVol = volDWPtoFP_toPrep*ones(size(makeFPCmds,1),1);
    
    [A,idx] = natsortrows(sourceIDwell);
    B = makeFPCmds(:,1:2);
    xlswrite(filename1,B(idx,:),'FormulationCmds','A2'); % dest plate, dest well
    xlswrite(filename1,A,'FormulationCmds','C2'); % source well
    xlswrite(filename1,fixedVol,'FormulationCmds','D2'); % transfer volume
    colheader = [cellstr('Dest plate') 'Dest well' 'Source' 'Volume'];
    xlswrite(filename1,colheader,'FormulationCmds','A1');
    
    %   List plate and well IDs where formulations made
    platewellID = [];
    for i=1:numComb*2
        platewellID = [platewellID; num2cell(CombList(i).plateNum) CombList(i).wellName];
    end
    xlswrite(filename1,platewellID,'CultureDestID','A2');
    colheader = [cellstr('Dest plate') 'Dest well'];
    xlswrite(filename1,colheader,'CultureDestID','A1');
    
    %   Compare members of theoretical list vs formTargetWells
    [~,idx]=unique(strcat(B(:,1),B(:,2)),'rows');
    formTargetWells = B(idx,:);
    A = cellfun(@num2str,platewellID,'un',0);
    B = cellfun(@num2str,formTargetWells,'un',0);
    out = all(ismember(A,B),2);
    if sum(out) == numComb*2
        disp('All wells in formulation plate assigned as destination');
    else
    end
    
    %   Number of hits of each destination well in makeFPcmds
    B = makeFPCmds(:,1:2);
    [test2,~,ub] = unique(strcat(B(:,1),B(:,2)),'rows');
    test2counts = histc(ub,1:length(test2));
    if all(test2counts == numFact)
        disp(['All destination wells targeted ' num2str(numFact) ' times']);
    end
    
    %   Total volume per source (DWP) well
    [A,~] = natsortrows(sourceIDwell);
    for t=1:length(dilTargetWells)
        idx = strcmp(dilTargetWells{t,1},A);
        volTotal{t,1} = dilTargetWells{t,1};
        volTotal{t,2} = sum(idx)*volDWPtoFP_toPrep;
    end
    volTotPrep = cell2mat(volTotal(:,2))+(numExtraWells*volDWPtoFP_toPrep)+volDWPdead;
    volTotal(:,3) = num2cell(volTotPrep);
    openvar('volTotal'); openvar('DilutionPrep');
    
    %   Check number of transfer occurrences for each destination well in
    %   formulation plate. Same number of transfers (= number of factors)
    %   for all vectors expected = same final volume.
    a=unique(makeFPCmds(:,2),'stable');
    b=cellfun(@(x) sum(ismember(makeFPCmds(:,2),x)),a,'un',0);
end

disp('Completed generating dilutions + F5 to continue'); keyboard;