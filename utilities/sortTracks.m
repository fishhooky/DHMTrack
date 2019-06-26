function [ outputTracks ] = sortTracks( Tracks, column )
%Sorts the tracks based on a specific columns average value
%  Tracks - a 1xN array containing the N tracks
%  Column - the column of the ith array in Tracks that is used to order
%
%  Fall 2018 - Andrew Woodward
%  MAY BE REDUNDANT AS TRACKS SEEM TO BE SORTED BY TIME ALREADY....

% calculate the average time of each track
for i=1:size(Tracks,2)
    sum = 0;
    for j=1:size(Tracks{i},1)
        sum = sum + Tracks{i}(j,column);
    end
    averages{i} = [sum/size(Tracks{i},1) i];
end

% using the averages re-order the tracks from smallest to largest average
addedList = [];
for j=1:size(Tracks,2)
    min = averages{j};
    for i=2:size(Tracks,2)
        if averages{i}(1) < min(1) && ismember(averages{i}(2), addedList)==0
            min = averages{i};
        end
    end
    outputTracks{j} = Tracks{min(2)};
end




