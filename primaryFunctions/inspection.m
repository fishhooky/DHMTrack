function [isCancel,filenameList] = inspection(Tracks,inspectSettings,pathname,varargin)
%  Allows for viewing the tracks in 3D and for visual inspection.
%  Gui buttons and sliders allow for the user to easily select and save specific
%  tracks and make new links between existing tracks.
%
%       Tracks          = the set of tracks previously detected
%       inspectSettings = the settings used as input for inspection
%       isManual        = varargin{1} = 'manual' if > 0 activates manual track sift
%       DIMENSION       = varargin{2} = 'dimension' select dimensions of tracks (default = 3)
%       MIN_STEP        = varargin{3} = 'minstep' minimum number of steps for track to be processed (default = 1)
%       MIN_DISPLACE    = varargin{4} = the minimum distance required for a track to be considered swimming
%       MAX_DISTANCE    = varargin{5} = the maximum distance allowed between tracks for them to be combined in the automated workflow
%       MAX_TIME        = varargin{6} = the maximum time between two tracks to be considered connected
%       AQUISITION_TIME = varargin{7} = the capture time between frames in ms
%       X_MAX           = varargin{8} = the maximum size of the x axis from the capture frame (used by combineTracks subfunction)
%       Y_MAX           = varargin{9} = the maximum size of the y axis from the capture frame (used by combineTracks subfunction)
%
% Fall 2018 - Andrew Woodward

%% Creating variables
filenameList = {};      % the filename strings when tracks are exported
exportArray = {};       % the cell array used to store the finalized tracks for exporting
outputTrackCount = 1;   % a count of the number of tracks outputted
TracksCopy = Tracks;    % used in the undo link function to revert back to the original tracks

savedList = [];         % list of track indexes for tracks that have been saved
linkList = [];          % list of track indexes for tracks in the current link
prevLinkList = [];      % the previous linked tracks (used by undoLink)
deleteList = zeros(1,size(Tracks,2)); % array to check if track has been deleted (if deleteList(i)==1 then i has been deleted )
plotList = [];          % list of the plots in the figure
txtList = [];           % list of the text in the figure
trackCategory = {};     % a cell array for storing the category of each track

saveCounter = 1;        % keeps track of the number of times saved was performed
lastSliderVal = 1;      % the last value stored by the slider
lastGCO = 0;            % the last clicked object in the figure
isTextOn = 1;           % boolean for checking if the number text of tracks are on or not
cancelBoolean = 0;      % used as a check for closing the popup window in the visibleHistCallback
openHist = 0;           % another boolean for the open visible hist callback
isShift = 0;            % keeps track of whether the shift key is currently pressed

% ordered processing
for num = 1:size(varargin,2)
    switch num
        case 1
            isManual = varargin{num}; 
        case 2
            DIMENSION = varargin{num};
        case 3
            MIN_STEP = varargin{num};
        case 4
            MIN_DISPLACE = varargin{num};
        case 5
            MAX_DISTANCE = varargin{num};
        case 6
            MAX_TIME = varargin{num};
        case 7
            ACQUISITION_TIME = varargin{num};
        case 8
            X_MAX = varargin{num};
        case 9
            Y_MAX = varargin{num};
    end
end

%% Cleanup the Tracks
% remove tracks under minstep
for i=1:size(Tracks,2)
    if size(Tracks{i},1) < MIN_STEP
        Tracks{i} = [];
    end
end

% remove blank tracks and zeros
Tracks = condense(Tracks);

% categorize the tracks into one of the categories
% currently just swimming, stationary, other, (NOTE)'all' is not a category
categories = {'stationary', 'swimming', 'other', 'all'};
for i=1:size(Tracks,2)
    trackCategory{i} = categorizeTrack(Tracks{i}, categories, MIN_DISPLACE);
end

%% Determine maximum limits of figures and graph coloring
MAX_X = 0;
MAX_Y = 0;
MAX_Z = 0;
MAX_COLOR_TIME = 0;
for i=1:size(Tracks,2)
    tmpMaxX = max(Tracks{1,i}(:,1));
    tmpMaxY = max(Tracks{1,i}(:,2));
    tmpMaxZ = max(Tracks{1,i}(:,3));
    tmpMaxTimeColor = max(Tracks{1,i}(:,6));
    if tmpMaxX > MAX_X
        MAX_X = tmpMaxX;
    end
    if tmpMaxY > MAX_Y
        MAX_Y = tmpMaxY;
    end
    if tmpMaxZ > MAX_Z
        MAX_Z = tmpMaxZ;
    end
    if tmpMaxTimeColor > MAX_COLOR_TIME
        MAX_COLOR_TIME = tmpMaxTimeColor; 
    end
end
MAX_X = MAX_X + 5; % extend the limits a bit
MAX_Y = MAX_Y + 5;
MAX_Z = MAX_Z + 5;

%% Create the figure
f1 = figure('NumberTitle','off','Name','Track Inspection Window'); % the main gui window
subplot(1,5,2:5);

str = version; % get the version number
if str2num_fast(str(1:3)) >= 9.5
    addToolbarExplorationButtons(f1); % this is for matlab r2018b might break on older versions
    disableDefaultInteractivity(gca); % another change in matlab r2018b might break on older versions
end

xlim([0 MAX_X]);
ylim([0 MAX_Y]);
zlim([0 MAX_Z]);
set(gcf, 'units','normalized','Position', [0.1, 0.15, 0.8, 0.7])
set(f1, 'WindowButtonUpFcn', @mouseUpCallback); % when the mouse is clicked this callback function is executed 
myColors = [1 0.75 0; 1 0.35 0; 0.8 0 0.2; 0.56 0.05 0.25; 0.35 0.1 0.27; 0 0 1; 0 1 0];

% plot all the tracks together
for i=1:size(Tracks,2)
    color = (max(Tracks{i}(size(Tracks{i},1),6)) / MAX_COLOR_TIME);
    if color < 0.2
        colorArray = myColors(5,:);
    elseif color < 0.4
        colorArray = myColors(4,:);
    elseif color < 0.6
        colorArray = myColors(3,:);
    elseif color < 0.8
        colorArray = myColors(2,:);
    else
        colorArray = myColors(1,:);
    end
    plotList(i) = plot3(Tracks{1,i}(:,1),Tracks{1,i}(:,2),Tracks{1,i}(:,3), 'Color', colorArray); 
    txtList(i) = text(Tracks{1,i}(1,1),Tracks{1,i}(1,2),Tracks{1,i}(1,3), num2str(i), 'Color', [0.2 0.2 0.2]);
    hold on
end

xlabel('X');
ylabel('Y');
zlabel('Z');

colormap(myColors);
cBar = colorbar('Position', [0.95 0.75 0.02 0.15], 'Ticks', [0.1, 0.25, 0.40, 0.55, 0.65, 0.8, 0.95],...
                'TickLabels', {'newest','.', '..', '...', 'oldest', 'selected', 'approved'},'AxisLocation','in');

toggleArray = zeros(1,12); % used as inputs for the filterUI.m function
minMaxArray = [0 100; -500 500; 0 MAX_X; 0 MAX_Y; 0 MAX_Z; 0 10; 0 2; 0 4; 0 8; 0 MAX_COLOR_TIME; 0 100; 0 1];               

MSDArray = [];
for i=1:size(Tracks,2)
    if size(Tracks{i},1) > 10
        if size(Tracks{i},2) < 9
            [msd,roc,msdGraph,msdGraph] = ROC_MSD(Tracks{i}, 3);
        else
            [msd,roc,msdGraph,msdGraph] = ROC_MSD(Tracks{i}, 2);
        end
        if size(msd,2)>0
            MSDArray(i) = msd(1);
        else
            MSDArray(i) = 0;
        end
    else
        MSDArray(i) = 0;
   end
end

% update the viewing angle if a 2d track file
if DIMENSION == 2
    view(0,90);
end

%% Setup gui elements
if isManual == 1
    % if manual setting is on then give the user GUI controls
    set(f1,'KeyPressFcn', @keyPressed); % if a key is pressed then function is called
    
    % make uipanel objects
    trackPanel = uipanel('Title','Track Controls', 'FontSize',12, 'BackgroundColor','white', 'Position',[0 0.25 0.25 0.55]);
    
    finalPanel = uipanel('Title','Finalization', 'FontSize', 12, 'BackgroundColor','white', 'Position',[0 0.8 0.25 0.2]);
    
    displayPanel = uipanel('Title','Display Settings', 'FontSize',12, 'BackgroundColor','white', 'Position',[0 0.05 0.25 0.2]);
    
    % the auto link button for linking and approving all tracks that are visible on the display
    autoLinkVisibleBtn = uicontrol('Parent',trackPanel,'Style', 'pushbutton', 'String', 'Auto Link and Approve all Visible',...
                                   'units','normalized','Position', [0.1 0.9 0.8 0.075], 'Callback', @autoLinkVisisbleTracks);
                        
    % the save all button for approving all tracks that are visible on the display
    approveAllVisibleBtn = uicontrol('Parent',trackPanel,'Style', 'pushbutton', 'String', 'Approve all Visible',...
                                     'units','normalized','Position', [0.1 0.8 0.8 0.075], 'Callback', @approveVisibleTracks);
                        
    % the save button for approving a specific track or created link
    approveBtn = uicontrol('Parent',trackPanel, 'Style','pushbutton', 'String','Approve selected tracks  ( a )',...
                           'units','normalized', 'Position',[0.1 0.65 0.8 0.075], 'Callback',@approveTrack);
    
    % the reject button for a specific track or link
    rejectBtn = uicontrol('Parent', trackPanel, 'Style', 'pushbutton', 'String', 'Reject selected tracks  ( r )',...
                          'units','normalized', 'Position',[0.1 0.55 0.8 0.075], 'Callback',@rejectTrack);                    
    
    % selecting the current track to be apart of a new or existing link
    linkBtn = uicontrol('Parent',trackPanel,'Style', 'pushbutton', 'String', 'Link selected tracks  ( l )',...
                        'units','normalized', 'Position',[0.1 0.41 0.45 0.075], 'Callback',@linkTrack);
                    
    % undo the previous link button
    undoBtn = uicontrol('Parent',trackPanel,'Style', 'pushbutton', 'String', 'Undo previous link ( u )',...
                        'units','normalized', 'Position',[0.575 0.41 0.325 0.075], 'Callback',@undoLink);
                        
    % text for displaying the current tracks in the linklist
    selectTxt = uicontrol('Parent',trackPanel, 'Style','text', 'units','normalized',...
                          'Position',[0.1 0.35 0.8 0.05], 'String','Selected: ');
                        
    % deselecting the current track or existing link
    deSelectBtn = uicontrol('Parent',trackPanel,'Style', 'pushbutton', 'String', 'Deselect all  ( d )','FontSize', 8,...
                            'units','normalized','Position', [0.1 0.275 0.375 0.075], 'Callback', @deSelectTrack);
                        
    % deselecting the current track or existing link
    deSelectLastBtn = uicontrol('Parent',trackPanel, 'Style','pushbutton', 'String','Deselect current', 'FontSize', 8,...
                                'units','normalized', 'Position',[0.525 0.275 0.375 0.075], 'Callback',@deSelectLastTrack);
    
    % button to display the objects in a track and adjacent objects                 
    objectAnimateBtn = uicontrol('Parent',displayPanel, 'Style','pushbutton', 'String','View objects in selected tracks  ( o )',...
                                 'units','normalized', 'Position',[0.1 0.7 0.8 0.2], 'Callback',@animateObjectsCallback); 
       
    % split tracks button
    splitTrackBtn = uicontrol('Parent',trackPanel, 'Style','pushbutton', 'units','normalized', 'Position',[0.1 0.1 0.8 0.075],...
                              'String','Split selected track  ( s )', 'Callback',@splitTrackCallback);
    
    % txt above the slider
    txt = uicontrol('Parent',trackPanel, 'Style','text', 'units','normalized',...
                    'Position',[0.1 0.2 0.6 0.05], 'String','Current Track Selected');
    
    % another method for selecting a track by inputting the track number
    numBox = uicontrol('Parent',trackPanel,'style','edit', 'units','normalized',...
                       'position',[0.75 0.2 0.1 0.05], 'string','1', 'Callback',@numberBox);
                        
    % import more tracks button
    importBtn = uicontrol('Parent',trackPanel,'Style','pushbutton','String','Import another track file',...
                          'units','normalized','Position',[0.1 0.01 0.8 0.075],'Callback',@importCallback);
                                
    % advanced filtering button
    filteringBtn = uicontrol('Parent',displayPanel, 'Style', 'pushbutton', 'String', 'Filter visible tracks options  ( f )',...
                             'units','normalized', 'Position', [0.1 0.4 0.8 0.2], 'Callback', @filteringCallback);
    
    % histogram of visible tracks button
    visibleHistBtn = uicontrol('Parent', displayPanel, 'Style', 'pushbutton', 'String', 'Histogram of visible',...
                               'units', 'normalized', 'Position', [0.1 0.1 0.4 0.2], 'Callback', @visibleHistCallback);
                         
    % check box for turning on/off the number labels
    txtCheckBox = uicontrol('Parent', displayPanel, 'Style', 'checkbox', 'units','normalized',...
                            'Position',[0.55 0.1 0.4 0.15], 'String', 'Hide numbers', 'Callback', @hideNumLabels);
                            
    % the final completion button, press to move onto the graphing stage
    completeBtn = uicontrol('Parent',finalPanel,'Style', 'pushbutton', 'String', 'Proceed to graphing',...
                            'units','normalized','Position',[0.1 0.15 0.8 0.2] , 'Callback', @complete, 'Visible','off');
   
    % the exit button
    exitBtn = uicontrol('Parent',finalPanel,'Style', 'pushbutton', 'String', 'Cancel and exit',...
                        'units','normalized','Position', [0.1 0.75 0.8 0.2], 'Callback', @exitCallback);
             
    saveBtn = uicontrol('Parent',finalPanel, 'Style', 'pushbutton', 'String', 'Export 0 approved tracks',...
                        'units','normalized', 'Position',[0.1 0.45 0.8 0.2], 'Callback', @saveTracksCallback);
else
    % else manual inspection setting was not chosen
    % automatically combine any tracks that have similar time and are located close to one another
    exportArray = combineTracks(Tracks, 1:size(Tracks,2), MAX_DISTANCE, MAX_TIME, ACQUISITION_TIME, X_MAX, Y_MAX);
    % save the tracks using the saveTracksCallback
    dummyControl = uicontrol('Parent',f1,'Visible','off'); % create a dummy uicontrol so saveTracksCallback doesn't throw an error
    saveTracksCallback(dummyControl);
    isCancel = 0;
    close(f1);
end

%% Defining the GUI callback functions
    function currentTrack(source, event)
        % change the colour of the current selected track
        newVal = round(source.Value); % round the slider input to an integer
        source.Value = newVal;
        numBox.String = num2str(newVal); % update the string to show the track number
        if ismember(lastSliderVal, savedList)==0 && ismember(lastSliderVal, linkList)==0
            color = (max(Tracks{lastSliderVal}(size(Tracks{lastSliderVal},1),6)) / MAX_COLOR_TIME);
            if color < 0.2
                colorArray = myColors(5,:);
            elseif color < 0.4
                colorArray = myColors(4,:);
            elseif color < 0.6
                colorArray = myColors(3,:);
            elseif color < 0.8
                colorArray = myColors(2,:);
            else
                colorArray = myColors(1,:);
            end
            set(plotList(lastSliderVal), 'Color', colorArray);
        end
        if ismember(newVal,savedList)==0 % if the newVal hasn't been added to the saveList
            set(plotList(newVal), 'Color', 'blue');
        end
        
        lastSliderVal = newVal;
        
        if ismember(newVal, linkList)==0 && ismember(newVal, savedList) == 0
            linkList = [linkList newVal];
            selectTxt.String = ['Selected: ' num2str(linkList)];
        end
    end

%% approveTrack button function
    function approveTrack(source, event)
        % will save the current track or link and update both figures
        if size(linkList,2) > 0
            if deleteList(linkList(1))==0 && ismember(linkList(1),savedList)==0
                % save the entire link
                exportArray{outputTrackCount} = Tracks{linkList(1)};
                outputTrackCount =outputTrackCount+1;
                set(plotList(linkList(1)), 'Color', 'green');
                for k=2:size(linkList,2) % loop through the tracks in the linkList and save
                    if deleteList(linkList(1))==0 && ismember(linkList(1),savedList)==0
                        exportArray{outputTrackCount} = Tracks{linkList(k)};
                        outputTrackCount =outputTrackCount+1;
                        set(plotList(linkList(k)), 'Color', 'green');
                    end
                end
                disp(['approving ' num2str(linkList)]);
                savedList = [savedList linkList];
                linkList = [];
                selectTxt.String = 'Selected: ';
            end
        end
        
        % update the save button text
        saveBtn.String = ['Export ' num2str(size(exportArray,2)) ' approved tracks'];
        
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% auto link and save visible tracks function
    function autoLinkVisisbleTracks(source, event)
        autoList = []; % list of the track indexes that are visible
        j = 1;
        for k=1:size(Tracks,2)
            if strcmp(get(plotList(k),'visible'),'on') && ismember(k, savedList)==0;
                % the plot for the k'th track is visible thus save it
                autoList(j) = k;
                j = j+1;
            end
        end
        newTracks = combineTracks( Tracks, autoList, MAX_DISTANCE, MAX_TIME, ACQUISITION_TIME, X_MAX, Y_MAX);
        for k=1:size(autoList,2) % loop through and save all the visible tracks
            set(plotList(autoList(k)), 'Color', 'green');
            savedList = [savedList autoList(k)];
        end
        for k=1:size(newTracks,2)
            exportArray{outputTrackCount} = newTracks{k}; % add the track to the exportArray
            outputTrackCount = outputTrackCount + 1;
        end
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% save all visible tracks function
    function approveVisibleTracks(source, event)
        % look through all the tracks that are visible and save
        linkCount = 1;
        for k=1:size(Tracks,2)
            if strcmp(get(plotList(k),'visible'),'on');
                % the plot for the k'th track is visible thus save it
                linkList(linkCount) = k;
                linkCount = linkCount + 1;
            end
        end
        approveTrack(approveBtn); % call the approveTrack function
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% linkTrack button function
    function linkTrack(source, event)
        % want to go through all the selected tracks and link them together
        % then need to replot them and hide the old plots and number labels
        if size(linkList,2) < 2
            return % multiple tracks are not selected
        end
        
        linkList = sort(linkList);
        prevLinkList = linkList; % store for undoing if needed
        indexNum = linkList(1);
        set(plotList(indexNum), 'Visible', 'off');
        set(txtList(indexNum), 'Visible','off');
        %delete(plotList(indexNum));
        %delete(txtList(indexNum));
        for k=2:size(linkList,2) % loop through all the selected tracks
            tmp = Tracks{linkList(k)};
            Tracks{indexNum} = TimeAlign(tmp,Tracks{indexNum},6);
            set(plotList(linkList(k)), 'Visible', 'off');
            set(txtList(linkList(k)), 'Visible', 'off');
            Tracks{linkList(k)} = zeros(1,11); % empty the track data
        end
        disp(['linking ' num2str(linkList)]);
        % replot the first part of the split track
        color = (max(Tracks{indexNum}(size(Tracks{indexNum},1),6)) / MAX_COLOR_TIME);
        if color < 0.2
            colorArray = myColors(5,:);
        elseif color < 0.4
            colorArray = myColors(4,:);
        elseif color < 0.6
            colorArray = myColors(3,:);
        elseif color < 0.8
            colorArray = myColors(2,:);
        else
            colorArray = myColors(1,:);
        end
        plotList(indexNum) = plot3(Tracks{indexNum}(:,1),Tracks{indexNum}(:,2),Tracks{indexNum}(:,3), 'Color', colorArray);
        txtList(indexNum) = text(Tracks{indexNum}(1,1),Tracks{indexNum}(1,2),Tracks{indexNum}(1,3), num2str(indexNum), 'Color', [0.2 0.2 0.2]);
    
        % update the ROC values for the combined track
        if size(Tracks{indexNum},1) > 10
            if size(Tracks{indexNum},2) < 9
                [msd,roc,msdGraph,msdGraph] = ROC_MSD(Tracks{indexNum}, 3);
            else
                [msd,roc,msdGraph,msdGraph] = ROC_MSD(Tracks{indexNum}, 2);
            end
            if size(msd,2) > 0
                MSDArray(indexNum) = msd(1);
            else
                MSDArray(indexNum) = 0;
            end
        else
            MSDArray(indexNum) = 0;
        end
        
        linkList = []; % reset linkList
        selectTxt.String = 'Selected: ';
        
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% undo the previous link that was created
    function undoLink(source,event)
        if size(prevLinkList,2) < 1
            return
        end
        
        % for each track in the prevLinkList
        % restore the values in Tracks{prevLinkList(k)}
        Tracks{prevLinkList(1)} = TracksCopy{prevLinkList(1)};
        
        
        color = (max(Tracks{prevLinkList(1)}(size(Tracks{prevLinkList(1)},1),6)) / MAX_COLOR_TIME);
        if color < 0.2
            colorArray = myColors(5,:);
        elseif color < 0.4
            colorArray = myColors(4,:);
        elseif color < 0.6
            colorArray = myColors(3,:);
        elseif color < 0.8
            colorArray = myColors(2,:);
        else
            colorArray = myColors(1,:);
        end
        
        % update the plotList
        set(plotList(prevLinkList(1)),'Visible', 'off');
        plotList(prevLinkList(1)) = plot3(Tracks{prevLinkList(1)}(:,1), Tracks{prevLinkList(1)}(:,2), Tracks{prevLinkList(1)}(:,3),'Color', colorArray);
        set(txtList(prevLinkList(1)),'Visible', 'on');
        
        for k=2:size(prevLinkList,2)
            % restore the values in Tracks{prevLinkList(k)}
            Tracks{prevLinkList(k)} = TracksCopy{prevLinkList(k)};
            % update the plotList
            set(plotList(prevLinkList(k)),'Visible', 'on');
            set(txtList(prevLinkList(k)),'Visible', 'on');
        end
        
        linkList = prevLinkList; % need to do this for deSelectTrack to work as intended
        deSelectTrack(deSelectBtn);
        
    end

%% reject track function
    function rejectTrack(source, event)
        % hides the current track from figure
        if ismember(lastSliderVal, savedList) == 0 && size(linkList,2) > 0
            for k=1:size(linkList,2) % loop through the tracks in the link and reject
                set(plotList(linkList(k)),'Visible','off');
                set(txtList(linkList(k)),'Visible','off');
                deleteList(linkList(k)) = 1;
            end
            disp(['rejecting ' num2str(linkList)]);
            linkList = [];
            selectTxt.String = 'Selected: ';
        end
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% deselect button function
    function deSelectTrack(source, event)
        % deselect the link (link is neither saved nor deleted)
        if size(linkList,2) > 0
            % there is a link selected
            for k=1:size(linkList,2)
                color = (max(Tracks{linkList(k)}(size(Tracks{linkList(k)},1),6)) / MAX_COLOR_TIME);
                if color < 0.2
                    colorArray = myColors(5,:);
                elseif color < 0.4
                    colorArray = myColors(4,:);
                elseif color < 0.6
                    colorArray = myColors(3,:);
                elseif color < 0.8
                    colorArray = myColors(2,:);
                else
                    colorArray = myColors(1,:);
                end
                set(plotList(linkList(k)), 'Color', colorArray);
                %disp(['deselecting ' num2str(linkList(k))]);
            end
            linkList = [];
            selectTxt.String = 'Selected: ';
            numBox.String = '';
        end
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% deselect last track
    function deSelectLastTrack(source, event)
        % only deselects the last track selected
        if size(linkList,2) > 0
            % there is a link selected
            lastLink = linkList(end);
            linkList = linkList(1:end-1);
            
            color = (max(Tracks{lastLink}(size(Tracks{lastLink},1),6)) / MAX_COLOR_TIME);
            if color < 0.2
                colorArray = myColors(5,:);
            elseif color < 0.4
                colorArray = myColors(4,:);
            elseif color < 0.6
                colorArray = myColors(3,:);
            elseif color < 0.8
                colorArray = myColors(2,:);
            else
                colorArray = myColors(1,:);
            end
            set(plotList(lastLink), 'Color', colorArray);
            %disp(['deselecting ' num2str(lastLink)]);
            
            selectTxt.String = ['Selected: ' num2str(linkList)];
            
            if size(linkList,2) > 0
                numBox.String = num2str(linkList(end));
            else
                numBox.String = '';
            end
            
        end
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% Split track callback
    function splitTrackCallback(source, event)
        if size(linkList,2)>0
            % call the splitTracks function to open a new UI
            splitNum = splitTracks(Tracks{lastSliderVal});
            
            if splitNum == 0 % zero means the split was cancelled or invalid
                return
            end
            % the new track is pushed to the end of the Tracks array
            tracksEND = size(Tracks,2)+1;
            Tracks{1,tracksEND} = Tracks{lastSliderVal}(splitNum+1:end,:);
            Tracks{1, lastSliderVal} = Tracks{1,lastSliderVal}(1:splitNum, :);
            
            % update the trackcopy array also
            TracksCopy{1,tracksEND} = Tracks{lastSliderVal}(splitNum+1:end,:);
            TracksCopy{1, lastSliderVal} = Tracks{1,lastSliderVal}(1:splitNum, :);
            
            % now need to clear these values from the original track and update the plots
            delete(plotList(lastSliderVal));
            % replot the first part of the split track
            color = (max(Tracks{lastSliderVal}(size(Tracks{lastSliderVal},1),6)) / MAX_COLOR_TIME);
            if color < 0.2
                colorArray = myColors(5,:);
            elseif color < 0.4
                colorArray = myColors(4,:);
            elseif color < 0.6
                colorArray = myColors(3,:);
            elseif color < 0.8
                colorArray = myColors(2,:);
            else
                colorArray = myColors(1,:);
            end
            plotList(lastSliderVal) = plot3(Tracks{1,lastSliderVal}(:,1),Tracks{1,lastSliderVal}(:,2),Tracks{1,lastSliderVal}(:,3), 'Color', colorArray);
            
            % update the ROC values for the first track
            if size(Tracks{lastSliderVal},1) > 10
                if size(Tracks{lastSliderVal},2) < 9
                    [msd,roc,msdGraph,msdGraph] = ROC_MSD(Tracks{lastSliderVal}, 3);
                else
                    [msd,roc,msdGraph,msdGraph] = ROC_MSD(Tracks{lastSliderVal}, 2);
                end
                MSDArray(lastSliderVal) = msd(1);
            else
                MSDArray(lastSliderVal) = 0;
            end
            
            % plot the other split part of the track
            color = (max(Tracks{tracksEND}(size(Tracks{tracksEND},1),6)) / MAX_COLOR_TIME);
            if color < 0.2
                colorArray = myColors(5,:);
            elseif color < 0.4
                colorArray = myColors(4,:);
            elseif color < 0.6
                colorArray = myColors(3,:);
            elseif color < 0.8
                colorArray = myColors(2,:);
            else
                colorArray = myColors(1,:);
            end
            plotList(tracksEND) = plot3(Tracks{1,tracksEND}(:,1),Tracks{1,tracksEND}(:,2),Tracks{1,tracksEND}(:,3), 'Color', colorArray);
            txtList(tracksEND) = text(Tracks{1,tracksEND}(1,1),Tracks{1,tracksEND}(1,2),Tracks{1,tracksEND}(1,3), num2str(tracksEND), 'Color', [0.2 0.2 0.2]);
            
            % update the ROC values for the first track
            if size(Tracks{tracksEND},1) > 10
                if size(Tracks{tracksEND},2) < 9
                    [msd,roc,msdGraph,msdGraph] = ROC_MSD(Tracks{tracksEND}, 3);
                else
                    [msd,roc,msdGraph,msdGraph] = ROC_MSD(Tracks{tracksEND}, 2);
                end
                MSDArray(tracksEND) = msd(1);
            else
                MSDArray(tracksEND) = 0;
            end
            
            % update the size of some of the deleteList vector
            deleteList(tracksEND) = 0;
            
            deSelectLastTrack(deSelectLastBtn); % remove the split tracks from the selected list
        end
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% numberBox input function
    function numberBox(source, event)
        % will change the current track that is highlighted
        newVal = str2num(source.String);
        if newVal <= size(Tracks,2) || newVal > 0
            slider.Value = newVal;
            currentTrack(slider);
        end
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% filterning callback
    function filteringCallback(source, event)
        % allows for multiple toggles and min/max values to be set to filter the visible tracks
        [toggleArray,minMaxArray] = filterUI(toggleArray, minMaxArray, Tracks, MSDArray);
        
        if size(toggleArray) == 0
            % if the exit button is pressed then reset the arrays
            toggleArray = zeros(1,12);
            minMaxArray = [0 100; -500 500; 0 MAX_X; 0 MAX_Y; 0 MAX_Z; 0 10; 0 2; 0 4; 0 8; 0 MAX_COLOR_TIME; 0 100; 0 1];    
        end
        
        % make all plots visible again
        for k = 1:size(Tracks,2)
            if deleteList(k)==0 && isequal(Tracks{k}, zeros(1,11))==0
                set(plotList(k), 'Visible','on');
                if isTextOn == 1
                    set(txtList(k),'Visible','on');
                end
            end
        end
        
        for k=1:size(toggleArray,2)
            if toggleArray(k) == 1
                tmpMin = minMaxArray(k,1);
                tmpMax = minMaxArray(k,2);
                switch k
                    case 1
                        %speed
                        for j = 1:size(Tracks,2)
                            if mean(Tracks{j}(:,5)) < tmpMin || mean(Tracks{j}(:,5)) > tmpMax
                                set(plotList(j), 'Visible', 'off');
                                set(txtList(j), 'Visible', 'off');
                            end
                        end
                    case 2
                        %accel
                        for j = 1:size(Tracks,2)
                            for b=1:size(Tracks{j},1)
                                if Tracks{j}(b,8) < tmpMin || Tracks{j}(b,8) > tmpMax
                                    set(plotList(j), 'Visible', 'off');
                                    set(txtList(j), 'Visible', 'off');
                                    break
                                end
                            end
                        end
                    case 3
                        %x
                        for j = 1:size(Tracks,2)
                            flag = 0;
                            for b=1:size(Tracks{j},1)
                                if Tracks{j}(b,1) > tmpMin && Tracks{j}(b,1) < tmpMax
                                    flag = 1;
                                    break % the track has part of it in the bounds
                                end
                            end
                            if flag == 0
                                set(plotList(j), 'Visible', 'off');
                                set(txtList(j), 'Visible', 'off');
                            end
                        end
                    case 4
                        %y
                        for j = 1:size(Tracks,2)
                            flag = 0;
                            for b=1:size(Tracks{j},1)
                                if Tracks{j}(b,2) > tmpMin && Tracks{j}(b,2) < tmpMax
                                    flag = 1;
                                    break % the track has part of it in the bounds
                                end
                            end
                            if flag == 0
                                set(plotList(j), 'Visible', 'off');
                                set(txtList(j), 'Visible', 'off');
                            end
                        end
                    case 5
                        %z
                        for j = 1:size(Tracks,2)
                            flag = 0;
                            for b=1:size(Tracks{j},1)
                                if Tracks{j}(b,3) > tmpMin && Tracks{j}(b,3) < tmpMax
                                    flag = 1;
                                    break % the track has part of it in the bounds
                                end
                            end
                            if flag == 0
                                set(plotList(j), 'Visible', 'off');
                                set(txtList(j), 'Visible', 'off');
                            end
                        end
                    case 6
                        %vol
                        for j = 1:size(Tracks,2)
                            if mean(Tracks{j}(:,4)) < tmpMin || mean(Tracks{j}(:,4)) > tmpMax
                                set(plotList(j), 'Visible', 'off');
                                set(txtList(j), 'Visible', 'off');
                            end
                        end
                    case 7
                        %msd
                        for j = 1:size(Tracks,2)
                            if MSDArray(j) < tmpMin || MSDArray(j) > tmpMax
                                set(plotList(j), 'Visible', 'off');
                                set(txtList(j), 'Visible', 'off');
                            end
                        end
                    case 8
                        %width
                        if size(Tracks{1},2) > 8
                            for j = 1:size(Tracks,2)
                                if mean(Tracks{j}(:,10)) < tmpMin || mean(Tracks{j}(:,10)) > tmpMax
                                    set(plotList(j), 'Visible', 'off');
                                    set(txtList(j), 'Visible', 'off');
                                end
                            end
                        end
                    case 9
                        %length
                        if size(Tracks{1},2) > 8
                            for j = 1:size(Tracks,2)
                                if mean(Tracks{j}(:,9)) < tmpMin || mean(Tracks{j}(:,9)) > tmpMax
                                    set(plotList(j), 'Visible', 'off');
                                    set(txtList(j), 'Visible', 'off');
                                end
                            end
                        end
                    case 10
                        % time
                        for j = 1:size(Tracks,2)
                            if mean(Tracks{j}(:,6)) < tmpMin || mean(Tracks{j}(:,6)) > tmpMax
                                set(plotList(j), 'Visible', 'off');
                                set(txtList(j), 'Visible', 'off');
                            end
                        end
                    case 11
                        % duration of track
                        for j = 1:size(Tracks,2)
                            if size(Tracks{j},1) < tmpMin || size(Tracks{j},1) > tmpMax
                                set(plotList(j), 'Visible', 'off');
                                set(txtList(j), 'Visible', 'off');
                            end
                        end
                    case 12
                        % confinement ratio of track
                        totalDist = [];
                        netDist = [];
                        for k=1:size(Tracks,2)
                            if size(Tracks{k},1) > 0
                                netDist(k) = sqrt((Tracks{k}(size(Tracks{k},1),1)-Tracks{k}(1,1))^2 + (Tracks{k}(size(Tracks{k},1),2)-Tracks{k}(1,2))^2 + (Tracks{k}(size(Tracks{k},1),2)-Tracks{k}(1,2))^2);
                                dist = 0;
                                for a=2:size(Tracks{k},1)
                                    dist = dist + sqrt((Tracks{k}(a,1)-Tracks{k}(a-1,1))^2 + (Tracks{k}(a,2)-Tracks{k}(a-1,2))^2 + (Tracks{k}(a,2)-Tracks{k}(a-1,2))^2);
                                end
                                totalDist(k) = dist;
                            end
                        end
                        confinementRatio = netDist ./ totalDist;
                        
                        for j = 1:size(Tracks,2)
                            if confinementRatio(j) < tmpMin || confinementRatio(j) > tmpMax
                                set(plotList(j), 'Visible', 'off');
                                set(txtList(j), 'Visible', 'off');
                            end
                        end
                end
            end
        end
        % ensure the limits are maintained
        figure(f1);
        xlim([0 MAX_X]);
        ylim([0 MAX_Y]);
        zlim([0 MAX_Z]);
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% histogram of visible callback
    function visibleHistCallback(source, event)
        % make a histogram of the selected variable with the visible tracks
        % create the ui figure
        type = '';
        fig = figure('NumberTitle','off','Name','Choose histogram');
        set(fig, 'units','normalized','Position', [0.15, 0.2, 0.2, 0.1], 'MenuBar', 'none', 'ToolBar', 'none');
        cancelBoolean = 0;
        openHist = 0;
        set(fig,'CloseRequestFcn',@closeFunctionRequest)
        
        histChoiceBtn = uicontrol('Parent',fig,'Style','popup','String',{'speed', 'accel', 'x','y','z','vol','MSD','width','length', 'time','duration'},...
                                  'units','normalized','Position',[0.1 0.2 0.8 0.2]);
                              
        histOpenBtn = uicontrol('Parent',fig,'Style','pushbutton','String','Open',...
                                  'units','normalized','Position',[0.1 0.5 0.8 0.2], 'Callback', @openHistCallback);
                              
        while openHist == 0
            type = histChoiceBtn.Value;
            pause(0.1);
        end
        
        if cancelBoolean == 1
            % to ensure key presses are recognized by the figure
            % this will change the focus off of the button to the figure
            set(source, 'Enable', 'off');
            drawnow;
            set(source, 'Enable', 'on');
            return;
        end
        
        close(fig);
        
        % determine the visible tracks and build the cell array histTracks
        histTracks = {};
        indexArray = [];
        count = 1;
        for k=1:size(plotList,2)
            if strcmp(get(plotList(k),'Visible'),'on')
                for j=1:size(Tracks,2)
                    if isequal(Tracks{1,j}(:,1)', get(plotList(k), 'XData'))
                        histTracks{count} = Tracks{1,j};
                        indexArray(count) = k;
                        count = count+1;
                        break
                    end
                end
            end
        end
        
        % make histogram plot
        switch type
            case 1
                % create the speed histogram
                speedFig = figure('NumberTitle','off','Name','Speed Histogram');
                set(speedFig, 'units','normalized','Position', [0.15, 0.4, 0.2, 0.3], 'Toolbar', 'none');
                tmp = [];
                iter = 1;
                for k=1:size(histTracks,2)
                    tmp(iter) = mean(histTracks{1,k}(:,5));
                    iter = iter+1;
                end
                hist(tmp);
            case 2
                % create the accel histogram
                accelFig = figure('NumberTitle','off','Name','Accel Histogram');
                set(accelFig, 'units','normalized','Position', [0.15, 0.4, 0.2, 0.3], 'Toolbar', 'none');
                tmp = [];
                iter = 1;
                for k=1:size(histTracks,2)
                    for j=1:size(histTracks{1,k},1)
                        tmp(iter) = histTracks{1,k}(j,8);
                        iter = iter+1;
                    end
                end
                hist(tmp);
            case 3
                % create the x axis histogram figure
                xFig = figure('NumberTitle','off','Name','X axis Histogram');
                set(xFig, 'units','normalized','Position', [0.15, 0.4, 0.2, 0.3], 'Toolbar', 'none');
                tmp = [];
                iter = 1;
                for k=1:size(histTracks,2)
                    for j=1:size(histTracks{1,k},1)
                        tmp(iter) = histTracks{1,k}(j,1);
                        iter = iter+1;
                    end
                end
                hist(tmp);
            case 4
                % create the y axis histogram figure
                yFig = figure('NumberTitle','off','Name','Y axis Histogram');
                set(yFig, 'units','normalized','Position', [0.15, 0.4, 0.2, 0.3], 'Toolbar', 'none');
                tmp = [];
                iter = 1;
                for k=1:size(histTracks,2)
                    for j=1:size(histTracks{1,k},1)
                        tmp(iter) = histTracks{1,k}(j,2);
                        iter = iter+1;
                    end
                end
                hist(tmp);
            case 5
                % create the z axis histogram figure
                zFig = figure('NumberTitle','off','Name','Z axis Histogram');
                set(zFig, 'units','normalized','Position', [0.15, 0.4, 0.2, 0.3], 'Toolbar', 'none');
                tmp = [];
                iter = 1;
                for k=1:size(histTracks,2)
                    for j=1:size(histTracks{1,k},1)
                        tmp(iter) = histTracks{1,k}(j,3);
                        iter = iter+1;
                    end
                end
                hist(tmp);
            case 6
                % create the volume histogram figure
                volFig = figure('NumberTitle','off','Name','Volume Histogram');
                set(volFig, 'units','normalized','Position', [0.15, 0.4, 0.2, 0.3], 'Toolbar', 'none');
                tmp = [];
                iter = 1;
                for k=1:size(histTracks,2)
                    tmp(iter) = mean(histTracks{1,k}(:,4));
                    iter = iter+1;
                end
                hist(tmp);
            case 7
                % create the MSD histogram figure
                MSDFig = figure('NumberTitle','off','Name','MSD Histogram');
                set(MSDFig, 'units','normalized','Position', [0.15, 0.4, 0.2, 0.3], 'Toolbar', 'none');
                tmpMSDArray = [];
                for k=1:size(indexArray,2)
                    tmpMSDArray(k) = MSDArray(indexArray(k));
                end
                hist(tmpMSDArray);
            case 8
                % create the width histogram figure
                if size(histTracks{1,1},2) > 8
                    widthFig = figure('NumberTitle','off','Name','Width Histogram');
                    set(widthFig, 'units','normalized','Position', [0.15, 0.4, 0.2, 0.3], 'Toolbar', 'none');
                    tmp = [];
                    iter = 1;
                    for k=1:size(histTracks,2)
                        tmp(iter) = mean(histTracks{1,k}(:,10));
                        iter = iter+1;
                    end
                    hist(tmp);
                end
            case 9
                % create the length histogram figure
                if size(histTracks{1,1},2) > 8
                    lengthFig = figure('NumberTitle','off','Name','Length Histogram');
                    set(lengthFig, 'units','normalized','Position', [0.15, 0.4, 0.2, 0.3], 'Toolbar', 'none');
                    tmp = [];
                    iter = 1;
                    for k=1:size(histTracks,2)
                        tmp(iter) = mean(histTracks{1,k}(:,9));
                        iter = iter+1;
                    end
                    hist(tmp);
                end
            case 10
                % create the time histogram figure
                timeFig = figure('NumberTitle','off','Name','Time Histogram');
                set(timeFig, 'units','normalized','Position', [0.15, 0.4, 0.2, 0.3], 'Toolbar', 'none');
                tmp = [];
                iter = 1;
                for k=1:size(histTracks,2)
                    tmp(iter) = mean(histTracks{1,k}(:,6));
                    iter = iter+1;
                end
                hist(tmp);
            case 11
                % create the time histogram figure
                durationFig = figure('NumberTitle','off','Name','Duration Histogram');
                set(durationFig, 'units','normalized','Position', [0.15, 0.4, 0.2, 0.3], 'Toolbar', 'none');
                tmp = [];
                iter = 1;
                for k=1:size(histTracks,2)
                    tmp(iter) = size(histTracks{k},1);
                    iter = iter+1;
                end
                hist(tmp);
        end
        
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% open Hist callback
    function openHistCallback(source, event)
        openHist = 1;
    end

%% close the hist figure function callback
    function closeFunctionRequest(source, event)
        cancelBoolean = 1;
        openHist = 1;
        closereq;
    end

%% text number labels function
    function hideNumLabels(source, event)
        % check what the value of the checkbox is
        if source.Value == 1
            % the check box is enabled so hide the number labels
            isTextOn = 0;
            for k=1:size(Tracks,2)
                set(txtList(k),'Visible','off');
            end
        else
            % the check box is disabled so show the number labels
            isTextOn = 1;
            for k=1:size(Tracks,2)
                if deleteList(k)==0 && strcmp(get(plotList(k),'visible'),'on')
                    set(txtList(k),'Visible','on');
                end
            end
        end
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% Key pressed function
    function keyPressed(source, event)
        % can use this to create shortcut functionality
        key = get(source, 'CurrentKey');
        switch key
            case 'shift'
                if isShift==1
                    return
                end
                
                isShift = 1;
                
                % shift button pressed
                % enable the click and drag functionality for selecting
                X=[]; Y=[]; Z=[];
                for k=1:size(Tracks,2)
                    if strcmp(get(plotList(k),'Visible'),'on') && ismember(k,savedList)==0
                        % add the points from all the visible tracks that
                        X = [X Tracks{k}(:,1)'];
                        Y = [Y Tracks{k}(:,2)'];
                        Z = [Z Tracks{k}(:,3)'];
                    end
                end
                
                % text for displaying the current tracks in the linklist
                drawRectangleTxt = uicontrol('Parent',f1, 'Style','text', 'units','normalized',...
                                             'Position',[0.3 0.92 0.2 0.05], 'String','Draw selection rectangle to select');
       
                maxLimit = max([MAX_X MAX_Y MAX_Z]);
                axis([0 maxLimit 0 maxLimit 0 maxLimit]) % set the axis limits to be uniform
                                          % this is required for rbb3select to work properly
                SS=rbb3select(X,Y,Z); 
                
                axis([0 MAX_X 0 MAX_Y 0 MAX_Z])
                
                Xselected = X(find(SS)); % all the selected X coordinates
                Yselected = Y(find(SS)); % all the selected Y coordinates
                Zselected = Z(find(SS)); % all the selected Z coordinates
                
                % now go through the list of coordinates and find tracks
                % that match the selected coordinates
                
                for k=1:size(Xselected,2)
                    flag = 0;
                    x = Xselected(k);
                    y = Yselected(k);
                    z = Zselected(k);
                    for a=1:size(Tracks,2)
                        for b=1:size(Tracks{a},1)
                            if Tracks{a}(b,1)==x && Tracks{a}(b,2)==y && Tracks{a}(b,3)==z
                                % matching track
                                slider.Value = a; % update the sliders chosen track
                                currentTrack(slider);
                                flag = 1;
                                break
                            end
                        end
                        if flag==1
                            break
                        end
                    end
                end
                
                delete(drawRectangleTxt);
                isShift = 0;
                
            case 'a'
                % a button pressed so approve selected tracks
                approveTrack(approveBtn);
            case 'r'
                % r button pressed so reject selected tracks
                rejectTrack(rejectBtn);
            case 'l'
                % l button pressed so link selected tracks
                linkTrack(linkBtn);
            case 'd'
                % deselect all tracks
                deSelectTrack(deSelectBtn);
            case 's'
                % split the current selected track
                splitTrackCallback(splitTrackBtn);
            case 'o'
                % view objects in the selected tracks
                animateObjectsCallback(objectAnimateBtn);
            case 'f'
                % filter tracks
                filteringCallback(filteringBtn);
            case 'u'
                % undo previous link created
                undoLink(undoBtn);
            otherwise
                %disp('other button');
        end  
    end

%% object animate button
    function animateObjectsCallback(source, event)
        % overlays the objects for a given track
        % future work to add adjacent objects for every frame of the track too
        if size(linkList,2)>0
            % loop through and diplay objects in ordered time
            q = PriorityQueue(6); % create the new priority queue object
            for j=1:size(linkList,2) % loop through every track in linkList
                for k=1:size(Tracks{linkList(j)},1) % loop though every object in track j of linkList
                    q.insert(Tracks{linkList(j)}(k,:)); % insert the k'th object of track j into the queue
                end
            end
            % now just need to loop through and display each object in queue now that it is sorted in chronological order
            for j=1:q.size
                object = q.remove();
                if object(1,4) <= 0
                    objectSize = 50; % for 2d case where object(:,4)==0
                else
                    objectSize = object(:,4)*50;
                end
                tmp = scatter3(object(:,1),object(:,2),object(:,3),objectSize, [0 0 0]);
                pause(0.1);
                delete(tmp);
            end
            clear q;
        end
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% Import button callback
    function importCallback(source, event)
        [FileName,PathName] = uigetfile({'*.*','*.*';'*.*','All Files (*.*)'},strcat('Pick a tracks file'));
        
        if FileName == 0
            % canceled import operation
            % to ensure key presses are recognized by the figure
            % this will change the focus off of the button to the figure
            set(source, 'Enable', 'off');
            drawnow;
            set(source, 'Enable', 'on');
            return
        end
        
        inputdata = load([PathName FileName]);
        innername = fieldnames(inputdata); % get the structures field names
        if strcmp(innername(1),'Export') > 0
            inputdata = inputdata.Export; % depending on the import file may be called export or tracks
        elseif strcmp(innername(1),'Tracks') > 0
            inputdata = inputdata.Tracks;
        else
            f = msgbox('The import files fieldnames must be either Tracks or Export','Import ERROR');
            waitfor(f);
            return
        end
        % now have the inputdata tracks need to add to the other tracks and replot the data
        %disp('display tracks');
        
        Tracks = [Tracks inputdata];
        
        % Cleanup the Tracks
        % remove tracks under minstep
        for k=1:size(Tracks,2)
            if size(Tracks{k},1) < MIN_STEP
                Tracks{k} = [];
            end
        end
        
        % remove blank tracks and zeros
        Tracks = condense(Tracks);
        
        % categorize the tracks into one of the categories
        % currently just swimming, stationary, other, (NOTE)'all' is not a category
        categories = {'stationary', 'swimming', 'other', 'all'};
        for k=1:size(Tracks,2)
            trackCategory{k} = categorizeTrack(Tracks{k}, categories, MIN_DISPLACE);
        end
        
        % Determine maximum limits of figures and graph coloring
        MAX_X = 0;
        MAX_Y = 0;
        MAX_Z = 0;
        MAX_COLOR_TIME = 0;
        for k=1:size(Tracks,2)
            tmpMaxX = max(Tracks{1,k}(:,1));
            tmpMaxY = max(Tracks{1,k}(:,2));
            tmpMaxZ = max(Tracks{1,k}(:,3));
            tmpMaxTimeColor = max(Tracks{1,k}(:,6));
            if tmpMaxX > MAX_X
                MAX_X = tmpMaxX;
            end
            if tmpMaxY > MAX_Y
                MAX_Y = tmpMaxY;
            end
            if tmpMaxZ > MAX_Z
                MAX_Z = tmpMaxZ;
            end
            if tmpMaxTimeColor > MAX_COLOR_TIME
                MAX_COLOR_TIME = tmpMaxTimeColor;
            end
        end
        MAX_X = MAX_X + 5; % extend the limits a bit
        MAX_Y = MAX_Y + 5;
        MAX_Z = MAX_Z + 5;
        
        % Reset the figure window size
        figure(f1);
        %subplot(1,5,2:5);
        xlim([0 MAX_X]);
        ylim([0 MAX_Y]);
        zlim([0 MAX_Z]);
        
        myColors = [1 0.75 0; 1 0.35 0; 0.8 0 0.2; 0.56 0.05 0.25; 0.35 0.1 0.27; 0 0 1; 0 1 0];
        
        delete(plotList);
        delete(txtList);
        % plot all the tracks together
        for k=1:size(Tracks,2)
            color = (max(Tracks{k}(size(Tracks{k},1),6)) / MAX_COLOR_TIME);
            if color < 0.2
                colorArray = myColors(5,:);
            elseif color < 0.4
                colorArray = myColors(4,:);
            elseif color < 0.6
                colorArray = myColors(3,:);
            elseif color < 0.8
                colorArray = myColors(2,:);
            else
                colorArray = myColors(1,:);
            end
            plotList(k) = plot3(Tracks{1,k}(:,1),Tracks{1,k}(:,2),Tracks{1,k}(:,3), 'Color', colorArray);
            txtList(k) = text(Tracks{1,k}(1,1),Tracks{1,k}(1,2),Tracks{1,k}(1,3), num2str(k), 'Color', [0.2 0.2 0.2]);
            hold on
        end
        
        %disp(size(deleteList,2))
        for k=size(deleteList,2):size(Tracks,2)
            deleteList(k) = 0; % update this array
        end
        
        %disp(size(deleteList,2))
        %disp(size(Tracks,2))
        %disp(size(trackCategory,2))
      
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

%% mouseUpCallback function when mouse is clicked
    function mouseUpCallback(source, event)
        clickedPlot = gco; % set clickedPlot to the handle of the current object
        if strcmp(get(clickedPlot,'type'),'line')>0 % check if a new line was selected
            for k=1:size(Tracks,2) % find the matching track
                if isequal(clickedPlot.XData, Tracks{k}(:,1)') % compares the x axis data of chosen line to tracks{i} x axis
                    slider.Value = k; % update the sliders chosen track
                    %lastSliderVal = k;
                    currentTrack(slider); % call the function to invoke the result
                    break;
                end
            end
            
        end
    end

%% complete button function
    function complete(source, event)
        % begins the exporting process for the saved tracks
        source.String = 'Exporting...';
        isCancel = 0;
        close(f1);
    end

%% exit button function
    function exitCallback(source, event)
        % exits the function without progressing further in the application processes
        source.String = 'EXITING...';
        isCancel = 1;
        close(f1);
    end

%% save tracks to export file
    function saveTracksCallback(source, event)
        if size(exportArray,2)==0
            disp('no tracks approved, no file saved');
            return
        end
        
        % save the export array
        filename = [pathname 'Tracks' num2str(saveCounter) '.mat'];
        
        [file,name,path] = uiputfile('.mat','Tracks save file location and name',filename);
        
        if file==0 % exit function if cancel is chosen from dialog box
            disp('user canceled save operation');
            return
        end
        
        tempTracks = Tracks;
        Tracks = condense(exportArray);
        save([name file], 'TracksCopy','Tracks','inspectSettings');
        filenameList{saveCounter} = [name file];
        saveCounter = saveCounter + 1;
        Tracks = tempTracks;
        
        % reset the outputArray
        exportArray = {};
        outputTrackCount = 1;
        
        % reset the savedList
        savedList = [];
               
        % recolor all the tracks
        for k = 1:size(Tracks,2)
            if size(Tracks{k},1) > 0
                color = (max(Tracks{k}(size(Tracks{k},1),6)) / MAX_COLOR_TIME);
                if color < 0.2
                    colorArray = myColors(5,:);
                elseif color < 0.4
                    colorArray = myColors(4,:);
                elseif color < 0.6
                    colorArray = myColors(3,:);
                elseif color < 0.8
                    colorArray = myColors(2,:);
                else
                    colorArray = myColors(1,:);
                end
                set(plotList(k), 'Color', colorArray);
            end
        end
        
        disp(['SAVED FILE: ' file]);
        
        completeBtn.Visible = 'on';
        
        % update the save button text
        saveBtn.String = 'Export 0 approved tracks';
        
        % to ensure key presses are recognized by the figure
        % this will change the focus off of the button to the figure
        set(source, 'Enable', 'off');
        drawnow;
        set(source, 'Enable', 'on');
    end

waitfor(f1)
end