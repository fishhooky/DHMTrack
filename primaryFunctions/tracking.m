function Tracks = tracking(data,varargin)
% Use objects extracted from holography and turn into tracks
% Requires loading a data file {Frames,Objects,1:4 = {X,Y,Z,V}}
% Produces a Tracks matrix Track, Frame and then variable {X,Y,Z,volume,speed (um/s),t (s),Delta angle,Acceleration (um/s2)}
% 2D DIC data includes additional data 9=length, 10=width, 11=angle (radians)
% To use with DIC Z-Stack data ensure MinVol set to 0 and 4th coloumn data all = 0

% Written by Andrew Hook 2018
% Edited Fall 2018 Andrew Woodward

% data file should contain {Frame}(object,X,Y,Z,volume)
% varargin:
%   MIN_VOL        - Minimum volume that a object needs to be to be considered
%   MAX_VOL        - Maximum volume that a object needs to be to be considered
%   MAX_SPEED      - Set maximum speed of bacteria um/s
%   STEP_MIN       - Minimum number of steps for track to be recorded
%   DIST_MIN       - Minimum distance that an object must travel for a track to be recorded
%   ANGLE_CHANGE   - Set angle to prefer next particle position if required
%   DELTA_VOL_MIN  - Set maximum allowable change in volume between objects, will be imposed only when percentage change is below this value
%   DELTA_VOL_PERC - Set maximum allowable change in volume between objects, percentange change
%   FRAME_TIME     - time taken in ms for each frame
%   MAX_LOOK_AHEAD - Number of frames script will look ahead to find object

%% Process varargin
% ordered processing of the inputs
for num = 0:size(varargin,2)-1
    switch num
        case 0
            FRAME_TIME = varargin{num+1};
        case 1
            MIN_VOL = varargin{num+1};
        case 2
            MAX_VOL = varargin{num+1};
        case 3
            MAX_SPEED = varargin{num+1};
        case 4
            STEP_MIN = varargin{num+1};
        case 5
            DIST_MIN = varargin{num+1};
        case 6
            ANGLE_CHANGE = varargin{num+1};
        case 7
            DELTA_VOL_MIN = varargin{num+1};
        case 8
            DELTA_VOL_PERC = varargin{num+1};
        case 9
            MAX_LOOK_AHEAD = varargin{num+1};
    end 
end

%% Set limits and variables
AVERAGE_TRACKS = 100;           % The number of tracks usually found, used for the progress bar
FRAME_LIMIT = size(data,2);     % Total number of Frames
FRAME_TIME = FRAME_TIME/1000;   % 1/Frequency of image aquisition in Hz
RADIUS = MAX_SPEED*FRAME_TIME;  % Set maximum radial distance from first object
data1=data;                     % create data file that can be rewritten with nulled values
trackCount = 1;

progressBar = waitbar(0,'Detecting Tracks');

if STEP_MIN > FRAME_LIMIT
    STEP_MIN = 0;
end

%% Loop for building tracks
for frameOffset = 0:FRAME_LIMIT-STEP_MIN-1 % Starts at 0 for first frame. Continue to penultimate frame determined by StepMin.
    for iObj1 = 1:size(data{frameOffset+1},1) % loop through the total number of objects in the frame
        stepCount = 1; % Counter of steps in 1 track
        frameCount = 1; % frame counter
        object1 = data1{frameCount+frameOffset}(iObj1,:); % Select first object in a track
        if object1(3) < 10 % Allows for smaller volumes as it approaches the surface
            minVol = (MIN_VOL*0.99/10)*object1(3) + MIN_VOL/100;
        else
            minVol = MIN_VOL;
        end
        if object1(1) ~= -100 && object1(4) >= minVol && object1(4) <= MAX_VOL %Skips objects previously used and objects outside volume range
            if object1(4) == 0
                object1(6) = object1(5); %Extract time value for DIC Z-stack or 2D data
            else
                object1(6)=(frameCount+frameOffset-1)*FRAME_TIME; % Input time value
            end
            Tracks{trackCount}(frameCount,1:size(object1,2)) = object1; %Build tracks
            frameCount1 = 0; 
            frameCount2 = 1; % frame counter for frames looking ahead
            while frameCount2 < frameCount1 + MAX_LOOK_AHEAD % loop until the maximum look ahead has been met
                frameCount = frameCount + 1;
                if frameCount+frameOffset > FRAME_LIMIT
                    break
                end
                for iObj2 = 1:size(data{frameCount+frameOffset},1) %Loop builds an array of possible objects in next frame that are within a certain radius and similar volume. Stored in DistArray
                    object2 = data1{frameCount+frameOffset}(iObj2,:); %Selecting object in next frame for comparison
                    if object2(3)<10 %Allows for smaller volumes as it approaches the surface
                        minVol = (MIN_VOL*0.99/10)*object2(3) + MIN_VOL/100;
                    else
                        minVol = MIN_VOL;
                    end
                    if object2(1) ~= 0 && object2(1) ~= -100 && object2(4)>=minVol && object2(4) <= MAX_VOL; % Check object is not a null value or noise (small volume)
                        distance = sqrt((object1(1)-object2(1))^2+(object1(2)-object2(2))^2+(object1(3)-object2(3))^2); %find distance between object and original object
                    else
                        distance = RADIUS * frameCount2 + 1;
                    end
                    deltaVol = DELTA_VOL_PERC * object1(4);
                    if deltaVol<DELTA_VOL_MIN
                        deltaVol = DELTA_VOL_MIN;
                    end
                    % find distance with all objects in previous frame
                    % ensure object should not belong to a different track
                    clear dist1
                    for iObj3 = 1:size(data1{frameCount-frameCount2+frameOffset},1)
                        object3= data1{frameCount-frameCount2+frameOffset}(iObj3,:);
                        dist1(iObj3) = sqrt((object3(1)-object2(1))^2+(object3(2)-object2(2))^2+(object3(3)-object2(3))^2); %find distance between new object with objects in previous frame
                    end
                    if distance <= RADIUS * frameCount2 && abs(object1(4)-object2(4))<= deltaVol && min(dist1) >= distance ; %radius of selection and change in volume limit
                        % the next object has been successfully found
                        frameCount1 = frameCount1 + 1;
                        DistArray(frameCount1,1:size(object2,2)) = object2(:);
                        DistArray(frameCount1,5) = distance;
                        if object2(4) == 0
                            DistArray(frameCount1,6) = data1{frameCount+frameOffset}(iObj2,5);% Extract timepoint for new datapoint from DIC Z-stack data
                        else
                            DistArray(frameCount1,6) = (frameCount+frameOffset-1)*FRAME_TIME; %Find timepoint of new datapoint
                        end
                        DA(frameCount1) = iObj2;
                        if stepCount>2; %Calculates change in angle
                            a = sqrt((object2(1)-Tracks{trackCount}(stepCount-1,1))^2+(object2(2)-Tracks{trackCount}(stepCount-1,2))^2+(object2(3)-Tracks{trackCount}(stepCount-1,3))^2);
                            b = sqrt((Tracks{trackCount}(stepCount,1)-Tracks{trackCount}(stepCount-1,1))^2+(Tracks{trackCount}(stepCount,2)-Tracks{trackCount}(stepCount-1,2))^2+(Tracks{trackCount}(stepCount,3)-Tracks{trackCount}(stepCount-1,3))^2);
                            c = sqrt((object2(1)-Tracks{trackCount}(stepCount,1))^2+(object2(2)-Tracks{trackCount}(stepCount,2))^2+(object2(3)-Tracks{trackCount}(stepCount,3))^2);
                            Angle = 180 - acosd((b^2+c^2-a^2)/(2*b*c));
                            DistArray(frameCount1,7) = Angle;
                        else
                            DistArray(frameCount1,7) = 0;
                        end
                    end
                end
                if frameCount1 == 1 %Selecting next object from array, hence building track in Tracks
                    stepCount = stepCount + 1;
                    frameCount2=1;
                    Tracks{trackCount}(stepCount,1:size(DistArray,2))=DistArray(1,:);
                    object1(1:4)=DistArray(1,1:4);
                    data1{frameCount+frameOffset}(DA(1),1) = -100; %nulls used value
                elseif frameCount1 == 0 % if no object found then increment the next frame to look at
                     frameCount2=frameCount2+1;       
                else
                    DistArray1=DistArray;
                    b = 1;
                    for a=1:frameCount1 %Selects objects within an angle range
                        if DistArray1(b,7)> ANGLE_CHANGE
                            DistArray1(b,:) = [];
                        else
                            b = b + 1;
                        end
                    end
                    if size(DistArray1,1)>0 %Only use angle selection if hit found
                        DistArray = DistArray1;
                    end
                    stepCount = stepCount + 1;frameCount2=1;
                    if size(DistArray,1)==1
                        Tracks{trackCount}(stepCount,1:size(DistArray,2))=DistArray(1,:);
                        object1(1:4)=DistArray(1,1:4);
                        data1{frameCount+frameOffset}(DistArray(1,10),1:4) = -100; %nulls used value
                    else
                        [~,I] = min(DistArray); %Find smallest next value
                        Tracks{trackCount}(stepCount,1:size(DistArray,2))=DistArray(I(5),:);
                        object1(1:4)=DistArray(I(5),1:4);
                        data1{frameCount+frameOffset}(DA(I(5)),1) = -100; %nulls used value
                    end
                end
                frameCount1 = 0;
                DistArray = [];
                clear DistArray1
            end
            for i=2:size(Tracks{trackCount},1)
                Tracks{trackCount}(i,5)=Tracks{trackCount}(i,5)/(Tracks{trackCount}(i,6)-Tracks{trackCount}(i-1,6));
            end
            %% Select whether track is kept or binned
            TotalDist = sum(Tracks{trackCount}(:,5));
            if stepCount>=STEP_MIN && TotalDist >= DIST_MIN
                % Only records tracks above a limit of steps and with volume above a minimum threshold and with a total distance greater than a threshold
                clear store
                store=Tracks{trackCount}(:,1); % Change X and Y as holography output switches them
                Tracks{trackCount}(:,1)=Tracks{trackCount}(:,2);
                Tracks{trackCount}(:,2)=store;
                trackCount = trackCount + 1;
            else %Clears tracks that are too small
                Tracks{trackCount}(:,:)=[];
            end
        end   
    end
    if size(Tracks,2)/AVERAGE_TRACKS > 1
        AVERAGE_TRACKS = AVERAGE_TRACKS*1.25;
    end
    %str = ['Detecting Tracks: ' num2str(size(Tracks,2)) ' found'];
    waitbar(size(Tracks,2)/AVERAGE_TRACKS, progressBar, ['Detecting Tracks: ' num2str(size(Tracks,2)) ' found']);
end
delete(progressBar)
