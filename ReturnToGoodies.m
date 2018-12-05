function newTarget = ReturnToGoodies(newRoot)

%   Function uses a previously selected vector stored in SelectedVector and
%   generates a permutation of the vector at the called position and
%   introduces the vector as the new target vector.

global numFact numDose
global TabuList

%   Generate a pool of vectors from the newRoot vector by +/- 1 dose level
%   for a single factor.
Goodies = repmat(transpose(newRoot),numFact*2,1);
for i=1:numFact
    Goodies(i,i) = Goodies(i,i)+1;
    Goodies(numFact+i,i) = Goodies(numFact+i,i)-1;
end
Goodies(Goodies < 0) = 0;
for i=1:numFact
    Goodies(Goodies > numDose(i,1)-1) = numDose(i,1)-1;
end
Goodies = unique(Goodies,'rows');
    % remove duplicate vectors from within AddToGP
Goodies = Goodies(~ismember(Goodies,TabuList,'rows'),:);
    % remove previously tested vectors in TabuList that were regenerated in
    % AddToGP
[p,~] = size(Goodies);

%   Select a random vector from the pool.
if p == 0
    d = 1;
    while p == 0
        d = d + 1;
        Goodies = repmat(transpose(newRoot),numFact*2,1);
        for i=1:numFact
            Goodies(i,i) = Goodies(i,i)+d;
            Goodies(numFact+i,i) = Goodies(numFact+i,i)-d;
        end
        Goodies(Goodies < 0) = 0;
        for i=1:numFact
            Goodies(Goodies > numDose(i,1)-1) = numDose(i,1)-1;
        end
        Goodies = unique(Goodies,'rows');
        Goodies = Goodies(~ismember(Goodies,TabuList,'rows'),:);
        [p,~] = size(Goodies);
        if p == 0
            disp('Goodies still empty');
            disp(['cycle d = ' num2str(d)]);
        end
    end
end

i = randi(p);
newTarget = transpose(Goodies(i,1:numFact));

TabuList = [TabuList; transpose(newTarget)];