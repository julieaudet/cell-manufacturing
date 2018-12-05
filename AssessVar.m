function AssessVar

global run filename sheetname numComb textWidth activateVAR replicate numCells
global intraVarAlgo interVarAlgo Xint Uint PCint Xfin Ufin PCfin
global XlogScoreR UlogScoreR PClogScoreW interExpVarCV intraExpVarCV
global PCintRangeR PCfinRangeR DataSet

%   Use coefficient of variation (100x(standard deviation/mean)) to compare
%   variance between the different combinations (of control and test
%   samples).
disp(repmat('- ',1,textWidth/2));

%   Assess intra-experimental variability as the average of the individual
%   CoV for internal control combination replicates.
intraExpVarCV(run,1) = DataSet(run).posContCV;

%   Calculate the overall intra-experimental variability.
intraVarAlgo = intraExpVarCV(run,1);
if activateVAR == 1
    %   Active varibility assessment information feedback.
    disp(['ESTIMATED intra-experimental coefficient of variation = ' num2str(intraVarAlgo*100) ' %']);
elseif activateVAR == 0
    %   Reset assessed variability values to zero and ignore presence of
    %   varibility.
end

%   Calculate the rolling average of the overall inter-experimental
%   variability of the internal control combination evaluation result.
if run == 1
    interExpVarCV(run,3) = DataSet(run).avgPosFC;
    interExpVarCV(run,2) = mean(interExpVarCV(1:run,3));
    interExpVarCV(run,1) = NaN;
    interVarAlgo = interExpVarCV(run,1);
else
    interExpVarCV(run,3) = DataSet(run).avgPosFC;
    interExpVarCV(run,2) = mean(interExpVarCV(1:run,3));
    interExpVarCV(run,1) = std(interExpVarCV(1:run,3))/interExpVarCV(run,2);
    interVarAlgo = interExpVarCV(run,1);
end
if activateVAR == 1
    disp(['ESTIMATED inter-experimental coefficient of variation = ' num2str(interVarAlgo*100) ' %']);
elseif activateVAR == 0
    disp(['ESTIMATED inter-experimental coefficient of variation = ' num2str(interVarAlgo*100) ' % (not used) - check code']);
    intraVarAlgo = 0;
    interVarAlgo = 0;
end

if isnan(interVarAlgo) && run > 1
end

disp(repmat('- ',1,textWidth/2));