function SaveExcelSheet

global run filename sheetname pathname dataSaveDir fileHeader Key KeyRange 
global Stock StockRange
global sourcepathSES targetpathSES sourcefile factorNameList allListRange

%   Open Excel application process.
e_process = actxserver('excel.application');
if run == 1
    [sourcefile,pathname] = uigetfile('DE_template_*.xlsx','Select template source file');
    sourcepathSES = strcat(pathname,sourcefile);
    disp(['Template file selected = ' sourcefile]);
    Key = xlsread(sourcefile,'Reagent Cf',KeyRange);
    Stock = xlsread(sourcefile,'Reagent Cf',StockRange);
    [~,factorNameList,~] = xlsread(sourcefile,'Reagent Cf',allListRange);
end

%   Open preformatted source file.
e_file_source = e_process.Workbooks.Open(sourcepathSES);

%   Designate file to save.
fHeader = fileHeader(1:15);
filename = [fHeader '_data.xlsx'];

if run == 1
    foldername = fileHeader;
    mkdir(foldername);
    dataSaveDir = fullfile(pathname,foldername);
end

targetpathSES = strcat(pathname,filename);
A = NaN(1,1);
xlswrite(filename,A);
e_file_target = e_process.Workbooks.Open(targetpathSES); % open target file

if run == 1
    %   Get source sheet/template from source file.
    sheet_source = e_file_source.Sheets.Item('Reagent Cf');
    sheet_source.Activate; % activate the sheet
    sheet_source.Select; % select the sheet

    %   Copy source sheet/template into target workbook.
    sheet_source.Copy(e_file_target.Sheets.Item(1));
end

sheet_source = e_file_source.Sheets.Item('Template');
sheet_source.Activate; % activate the sheet
sheet_source.Select; % select the sheet
sheet_source.Copy(e_file_target.Sheets.Item(1));
sheetname = ['vectors_gen' num2str(run,'%02i')];
e_file_target.Sheets.Item(1).Name = sheetname; % rename 1st sheet
e_file_target.Save; % save to the same file

%   Delete default worksheets (Sheet1, Sheet2, Sheet3).
if run == 1
    sheetName = 'Sheet';
    e_process.ActiveWorkbook.Worksheets.Item([sheetName '1']).Delete;
    e_process.ActiveWorkbook.Worksheets.Item([sheetName '2']).Delete;
    e_process.ActiveWorkbook.Worksheets.Item([sheetName '3']).Delete;
    e_file_target.Save; % save to the same file
end

e_file_target.Close(false);
e_process.Quit;