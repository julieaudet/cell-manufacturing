function R = CheckDuplicate(R,vecPosition)

%   Function checks whether any newly generated combination set vector has
%   been previously generated and tested. All tested vectors are listed in
%   TabuList to prevent re-testing of previously tested vectors. Function
%   returns value 'duplicate = 0' if R is unique and returns 'duplicate =
%   1' if R has been previously tested.

global numFact numDose vectorState numComb
global TabuList

maxRep = 25;
numRep = 0;

if isempty(TabuList)
    %   Initialize TabuList to store vectors that are tested.
    TabuList = transpose(R);
else
    %   Check if input R is already present in TabuList.
    duplicate = ismember(transpose(R),TabuList,'rows');
    
    while (duplicate == 1) && (numRep < maxRep)
        %   Input R has been previously tested. Generate new combination
        %   until a unique combination is found (up to maxRep number of
        %   times, to prevent being stuck in an inifinite loop).
        numRep = numRep + 1;
        
        if vectorState == 1
            %   Need to generate replacement vector for target vector
            %   position.
            for i=1:numFact
                R = randsrc(1,numComb,0:numDose(i,1)-1);
            end
            duplicate = ismember(transpose(R),TabuList,'rows');
        elseif vectorState == 0
            %   Need to re-generate vector for trial vector position.
            R = miniGenTrialVectors(vecPosition);
            duplicate = ismember(transpose(R),TabuList,'rows');
        end
        
        if numRep == maxRep
            sprintf('numRep in CheckDuplicate reached maximum value of %d.\n',maxRep);
        end
    end
    
    if duplicate == 0
        %   Input R is a unique combination.
        TabuList = [TabuList; transpose(R)];
    end
end