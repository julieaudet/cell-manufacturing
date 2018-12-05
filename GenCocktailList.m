function GenCocktailList(CodedVectors)

%   Function converts coded target and trial vector factor-dose
%   combinations that require testing (in numFact x numComb array V) and
%   output 'to test' list as excel spreadsheet.

global numFact destRowWells destColWells numDose run CombList DoseList
global Factors wellcodeD wellcodeS factorNameList

CombList = struct('wellNum',{},'wellName',{},'dose',{});
DoseList = struct('factor',{},'level',{},'wells',{});

if run == 1
    Factors = struct('name',{});
    
    col = transpose('A':'H'); % array of source (dilution DWP) well IDs
    for i=1:destRowWells+2
        for j=1:destColWells+2
            wellcodeS{i,j} = [col(i,1) num2str(j)];
        end
    end
    wellcodeD = wellcodeS; % array of destination (formulation plate) well IDs
    wellcodeD(end,:)=[];
    wellcodeD(1,:)=[];
    wellcodeD(:,end)=[];
    wellcodeD(:,1)=[];
end

%   Correlate each well code to coded vector.
rowInd = 1;
colInd = 1;
firstPlate = 1;
Vset = transpose(CodedVectors);
[n,~] = size(Vset);
for i=1:n
    CombList(i).wellNum = i;
    if i <= numel(wellcodeD)-2
        CombList(i).plateNum = 1;
    else
        CombList(i).plateNum = 2;
    end
    
    if firstPlate == 1
        rowInd = 3;
        firstPlate = 0;
    end
    CombList(i).wellName = wellcodeD{rowInd,colInd};
    CombList(i).dose = Vset(i,1:numFact);
    
    rowInd = rowInd + 1;
    if rowInd > destRowWells
        colInd = colInd + 1;
        rowInd = 1;
    end
    if i == numel(wellcodeD)-2
        rowInd = 1;
        colInd = 1;
    end
end

%   Assign well information for each factor & dose.
% [~,factorNameList,~] = xlsread(filename,sheetname,allListRange);
for k=1:numFact
    if run == 1
        switch k
            case 1,     Factors(k).name = factorNameList{k,1};
            case 2,     Factors(k).name = factorNameList{k,1};
            case 3,     Factors(k).name = factorNameList{k,1};
            case 4,     Factors(k).name = factorNameList{k,1};
            case 5,     Factors(k).name = factorNameList{k,1};
            case 6,     Factors(k).name = factorNameList{k,1};
            case 7,     Factors(k).name = factorNameList{k,1};
            case 8,     Factors(k).name = factorNameList{k,1};
            case 9,     Factors(k).name = factorNameList{k,1};
            case 10,    Factors(k).name = factorNameList{k,1};
            case 11,    Factors(k).name = factorNameList{k,1};
            case 12,    Factors(k).name = factorNameList{k,1};
            case 13,    Factors(k).name = factorNameList{k,1};
            case 14,    Factors(k).name = factorNameList{k,1};
%             case 15,    Factors(k).name = factorNameList{k,1};
        end
        disp(['factor #' num2str(k) ' = ' Factors(k).name]);
        disp(['number of doses = ' num2str(numDose(k,1))]);
    end
    DoseList(k).factor = cellstr(Factors(k).name);
    DoseList(k).level = [0:numDose(k,1)-1];
    
    for i=1:n
        if all(~isnan(CombList(i).dose))
            for j=1:numDose(k,1)
                if CombList(i).dose(1,k) == DoseList(k).level(1,j)
                    if isempty(DoseList(k).wells)
                        DoseList(k).wells = cell(1,numDose(k,1));
                        DoseList(k).wells(1,j) = cellstr(CombList(i).wellName);
                    else
                        DoseList(k).wells(end+1,j) = cellstr(CombList(i).wellName);
                    end
                end
            end
        end
    end
end

%   Output list of wells for each factor dose.
for i=1:numFact
    [n,~]=size(DoseList(i).wells);
    for j=1:numDose(i,1)
        colList = DoseList(i).wells(:,j);
        keepcells = ~cellfun('isempty',colList);
        colList = colList(keepcells);
        colList(end+1:n,1) = {[]};
        DoseList(i).wells(:,j) = colList;
    end
end