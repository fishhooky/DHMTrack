function outputArray = combineTracks( Tracks, trackList, MAX_DISTANCE, MAX_TIME, ACQUISITION_TIME, X_MAX, Y_MAX)
% Automatically will find links and combine if suitable for the tracks in tracksList
% if trackList is empty assumes all tracks are to be searched for possible links
%   
%   Tracks - array of all the possible tracks
%   trackList - list of track indexes for tracks to be search for possible links
%   MAX_DISTANCE - an absolute max distance threshold between tracks (may not be used anymore)
%   MAX_TIME - an absolute max time threshold between tracks (may not be used anymore)
%   ACQUISITION_TIME - ms between the frames of the tracks 
%   X_MAX - edge of frame in the x axis
%   Y_MAX - edge of frame in the y axis
%
%   Andrew Woodward - Fall 2018

import java.util.LinkedList % using the java implementation for a linked list

ACQUISITION_TIME = ACQUISITION_TIME/1000; % convert to s from ms

% weights for the confidence calculation for a link
WEIGHT_1 = 1; % weight multiplier for closeness to magnitude
WEIGHT_2 = 1; % weight multiplier for closeness of trajectory angle
WEIGHT_3 = 1; % weight multiplier for difference in volume

isYes = 0;
combineCount = 0; % counts the number of combinations performed
queue = LinkedList(); % create the queue using the java linkedlist data structure

for a=1:size(trackList,2)
    queue.add(trackList(a)); % add the objects in the trackList into the queue
    % calculate the average speed of the track
    meanSpeedArray(trackList(a)) = mean(Tracks{trackList(a)}(:,5));
end

while queue.size > 0    % loop until the queue is empty
    track = queue.remove();
    if size(Tracks{track},1) > 0
        %disp(['track ' num2str(track)]);
        object1 = Tracks{track}(size(Tracks{track},1),:); % object1 is last object in the trackList(a) track
        object1prev = Tracks{track}(size(Tracks{track},1)-1,:); % the previous object to object1
        % now calculate the trajectory between these two points
        trajectoryDirection = (object1(1,1:3) - object1prev(1,1:3))/norm(object1(1,1:3) - object1prev(1,1:3));
        % the magnitude of search can now be set by using the objects speed and the acquisition time
        trajectoryMagnitude =  meanSpeedArray(track) * ACQUISITION_TIME;
        confidenceQ = PriorityQueue(1); % create the priorityQueue object where the first column is the comparator
        % check if the object is anticipated to exit the x or y boundaries
        if ( object1(:,1)+(trajectoryDirection(:,1)*trajectoryMagnitude) < X_MAX && object1(:,1)+(trajectoryDirection(:,1)*trajectoryMagnitude) > 0 ) && ( object1(:,2)+(trajectoryDirection(:,2)*trajectoryMagnitude) < Y_MAX && object1(:,2)+(trajectoryDirection(:,2)*trajectoryMagnitude) > 0 )
            % if it is expected to stay then try to find a possible link
            for b=1:size(trackList,2)
                if track~=trackList(b) && size(Tracks{trackList(b)},1) > 0
                    object2 = Tracks{trackList(b)}(1,:); % object2 is first object in comparison object
                    distance = sqrt((object2(1)-object1(1))^2 + (object2(2)-object1(2))^2 + (object2(3)-object1(3))^2 );
                    if distance < trajectoryMagnitude*10 && abs(object2(6)-object1(6)) < MAX_TIME
                        % if object2 is within the maximum requirements add it to the potential links queue
                        linkConfidence = [0,trackList(b)];
                        % calculates the unit vector between object2 and object1
                        unitVector = (object2(1,1:3) - object1(1,1:3))/norm(object2(1,1:3) - object1(1,1:3));
                        % calculates the angle between the estimated trajectory and unitVector of obj1 and obj2
                        angle = acosd(dot(unitVector, trajectoryDirection));
                        % now calculate the weighted confidence (larger is higher confidence)
                        linkConfidence(1) = WEIGHT_1 * (1/abs(trajectoryMagnitude-distance)) + WEIGHT_2 * (1/angle) + WEIGHT_3 * (1/abs(object1(:,4)-object2(:,4)));
                        % insert the calculated confidence that trackList(b) is potential link to track
                        confidenceQ.insert(linkConfidence);
                    end
                end
            end
        end
        % if there is a at least one suitable link
        if confidenceQ.size > 0
            elementsData = confidenceQ.elements;
            linkIndex = elementsData{confidenceQ.size}(:,2); % get the largest confidence track index from priority queue
            if isYes == 0
                answer = questdlg(['Combine tracks: ' num2str(track) ' ' num2str(linkIndex)], ...
                    'Confirmation', ...
                    'Yes to all','Yes','No','Yes');
                if strcmp(answer,'Yes')
                    combineCount = combineCount + 1;
                    Tracks{track} = TimeAlign(Tracks{track}, Tracks{linkIndex},6);
                    Tracks{linkIndex} = [];
                    queue.add(track); % add the now combined track back to queue to ensure there arent any new possible connections
                elseif strcmp(answer,'Yes to all')
                    combineCount = combineCount + 1;
                    Tracks{track} = TimeAlign(Tracks{track}, Tracks{linkIndex},6);
                    Tracks{linkIndex} = [];
                    queue.add(track);
                    isYes = 1;
                end
            else
                % isYes was set to 1 so no need to confirm with user
                combineCount = combineCount + 1;
                Tracks{track} = TimeAlign(Tracks{track}, Tracks{linkIndex},6);
                Tracks{linkIndex} = [];
                queue.add(track);
            end
        end
    end
end

b = 1;
for a=1:size(trackList,2) % loop through all the tracks of the track list
    if size(Tracks{trackList(a)},1) > 0 % if it wasn't deleted
        % then add it to the outputArray
        outputArray{b} = Tracks{trackList(a)};
        b = b+1;
    end
end
disp([num2str(combineCount) ' Tracks combined']);

end

