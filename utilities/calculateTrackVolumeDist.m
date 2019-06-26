% Calculate the volume distribution of each track
% Sept 2018 - Andrew Woodward
%

count = 1;
for i=1:size(Tracks,2)
    ave = mean(Tracks{i}(:,4));
    for j=1:size(Tracks{i},1)
        X(count) = Tracks{i}(j,4) - ave;
        count = count + 1;
    end
end

histogram(X)