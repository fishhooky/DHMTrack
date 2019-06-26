function makeGif(Tracks, filename, inputFigure, COLOUR_CHAR,COLUMN,COLOUR_MAX, MAX_TIME, TIME_STEP, GIF_COUNT,XMAX, YMAX,ZMAX, FONT_FACE, FONT_SIZE, isPatch)
% Used by graphing.m to show gif making controls and exports the gif
%   Inputs:
%       Tracks          - all the potential tracks being plot
%       filename        - the filename and saving location
%       inputFigure     - the figure handle of containing the tracks
%       COLOUR_CHAR     - the colour character for input into colourcalc.m
%       COLUMN          - the column used in the Tracks data for the colourcalc function
%       COLOUR_MAX      - the maximum value for the colourcalc function
%       MAX_TIME        - the maximum time of the Tracks data objects
%       TIME_STEP       - the aquisition time between capture from the raw objects data (20 or 24 ms usually)
%       GIF_COUNT       - the number of gifs generated
%       XMAX            - the x axis max limit
%       YMAX            - the y axis max limit
%       ZMAX            - the z axis max limit
%       FONT_FACE       - the font name for the timetxt
%       FONT_SIZE       - the font size for the timetxt
%
%   Andrew Woodward - Fall 2018

%% Variables and figure creation
SURFACE_THRESHHOLD = 0; % the threshold for objects to be considered on the surface

plotList = [];
selectedTracks = []; % the tracks selected to be made into a gif
trackCount = 1; % the number of tracks selected
lastTrack = 0; % the last track plot selected

f3 = inputFigure; % the figure of tracks
figure(f3);
rotate3d off; % WindowButtonUpFcn cannot be set if rotate3d tool is selected
set(f3, 'WindowButtonUpFcn', @mouseUpCallback);
f4 = figure('NumberTitle','off','Name','GIFmaker'); % the figure for gif maker controls
set(f4, 'units','normalized', 'Position', [0.05 0.3 0.14 0.5], 'MenuBar', 'none', 'ToolBar', 'none')

isSelecting = 1; % is the select button clicked
isAllTracks = 0; % is the all tracks button clicked
isPreview = 0; % is the preview button clicked

%% Ensure track plots are visible
for k=1:size(Tracks,2)
    figure(f3);
    plotList(k) = plot3(Tracks{1,k}(:,1),Tracks{1,k}(:,2),Tracks{1,k}(:,3));
end

%% GUI control buttons and text boxes
% automatically selects all the visible tracks                        
selectAllTracksBtn = uicontrol('Parent',f4,'Style', 'pushbutton', 'String', 'Select all Tracks',...
                               'units','normalized', 'Position', [0.1 0.73 0.8 0.05], 'Callback', @selectAllTracksCallback);
                        
% starts the gif making process
startGifBtn = uicontrol('Parent',f4,'Style','pushbutton','String','Start making GIF',...
                        'units','normalized', 'Position', [0.1 0.81 0.8 0.05], 'Callback', @startGifCallback);
                       
% exit button
exitBtn = uicontrol('Parent',f4,'Style','pushbutton','String','Exit GIF maker',...
                    'units', 'normalized', 'Position', [0.1 0.89 0.8 0.05], 'Callback', @exitCallback);
                       
% allows input of the tail length                       
trackTailLengthBox = uicontrol('Parent',f4,'style','edit',...
                               'units','normalized','position',[0.1 0.55 0.2 0.03], 'string','10');
                         
trackTailTxt = uicontrol('Parent',f4,'style','text','String', 'Track Tail Length',...
                         'units','normalized', 'position', [0.3 0.55 0.5 0.03]);
         
% allows choice of whether surface level objects should be signified
surfaceCellBox = uicontrol('Parent', f4, 'Style', 'checkbox','Value', 0,...
                           'units', 'normalized', 'Position',[0.1 0.05 0.8 0.05], 'String', 'Show surface cell shape');
                            
% the azimuth start input box
azimuthStartBox = uicontrol('Parent',f4,'style','edit',...
                            'units','normalized','position',[0.1 0.15 0.15 0.05],...
                            'string','40','Callback',@viewCallback); 

% the elevation start input box
elevationStartBox = uicontrol('Parent',f4,'style','edit',...
                            'units','normalized','position',[0.5 0.15 0.15 0.05],...
                            'string','45','Callback',@viewCallback);
                        
% the azimuth end input box                        
azimuthEndBox = uicontrol('Parent',f4,'style','edit',...
                          'units','normalized','position',[0.3 0.15 0.15 0.05],...
                          'string','100','Callback',@viewCallback); 

% the elevation end input box
elevationEndBox = uicontrol('Parent',f4,'style','edit',...
                            'units','normalized','position',[0.7 0.15 0.15 0.05],...
                            'string','10','Callback',@viewCallback);
                        
viewTxt = uicontrol('Parent',f4,'style','text','String','Azimuth           Elevation',...
                    'units','normalized', 'position', [0.05 0.225 0.8 0.025]);
                        
viewSubTxt = uicontrol('Parent',f4,'style','text','String','Start       End      Start      End',...
                       'units','normalized', 'position', [0.05 0.2 0.8 0.025]);
                                                   
% displays the current time onto the figure being turned into a gif
timeTxt = uicontrol('Parent',f3,'style','text','String','time (s): ',...
                    'units', 'normalized', 'position', [0.85 0.9 0.1 0.025],...
                    'FontName', FONT_FACE, 'FontSize', FONT_SIZE, 'BackgroundColor', 'white');
                        
% checkbox for making the tails as tracks
tracksVisibleBox = uicontrol('Parent',f4,'style', 'checkbox','Value', 0,...
                             'units','normalized', 'Position',[0.1 0.27 0.8 0.05],...
                             'String', 'Show tails as line');

% checkbox for option to remove tracks in gif when at terminus
tracksRemoveBox = uicontrol('Parent',f4,'style', 'checkbox','Value', 0,...
                            'units', 'normalized', 'Position',[0.1 0.32 0.8 0.05],...
                            'String', 'Del tracks @ end');
                        
% the number of ticks on the axis                       
xAxisSpaceBox = uicontrol('Parent',f4,'style','edit',...
                          'units','normalized','position',[0.1 0.45 0.2 0.03], 'string','10');

% the number of ticks on the axis                       
yAxisSpaceBox = uicontrol('Parent',f4,'style','edit',...
                          'units','normalized','position',[0.4 0.45 0.2 0.03], 'string','10');
                      
% the number of ticks on the axis                       
zAxisSpaceBox = uicontrol('Parent',f4,'style','edit',...
                          'units','normalized','position',[0.7 0.45 0.2 0.03], 'string','20');


% number of axis label txt
numberAxisLabelsTxt = uicontrol('Parent',f4,'style','text','string','Axis tick spacing x y z',...
                                'units','normalized','position', [0.15 0.48 0.7 0.03]);
                            
% button for previewing what the axis sizes and tick will look like
previewAxisBtn = uicontrol('Parent',f4,'Style', 'pushbutton', 'String', 'Preview axis labels',...
                           'units','normalized', 'Position', [0.1 0.41 0.8 0.03], 'Callback', @previewAxisCallback);

% the time between frames in gif                      
gifTimeBox = uicontrol('Parent',f4,'style','edit',...
                       'units','normalized','position',[0.1 0.6 0.2 0.03], 'string','15');

gifTimeTxt = uicontrol('Parent',f4,'style','text','String', 'Frames per second',...
                       'units','normalized', 'position', [0.3 0.6 0.6 0.03]);                           

selectInstructionTxt = uicontrol('Parent',f3, 'style','text', 'String','Click tracks to select',...
                                 'units','normalized', 'position',[0.05 0.9 0.2 0.05],...
                                 'FontName', FONT_FACE, 'FontSize', FONT_SIZE, 'BackgroundColor', 'white');
                    
viewCallback(viewTxt); % just ensure the orientation matches the input boxes

%% Callback functions
% exit gif maker callback
    function exitCallback(source, event)
        % exits the function by closing ui window
        for i=1:size(plotList,2)
            set(plotList(i),'Visible','off');
        end
        selectInstructionTxt.Visible = 'off'; % hide instruction text
        close(f4);
    end

%% mouse click up callback
    function mouseUpCallback(source, event)
        currentTrack = gco;
        if strcmp(get(currentTrack,'type'),'line')>0 && ismember(currentTrack, selectedTracks) > 0
            % remove the current track from the selectedTracks list
            for a=1:size(selectedTracks,2)
                if selectedTracks(a) == currentTrack;
                    selectedTracks(a) = []; % clear this object
                    break;
                end
            end
            set(currentTrack, 'Color', [0.2 0.2 0.2]);
            trackCount = trackCount - 1;
        elseif strcmp(get(currentTrack,'type'),'line')>0 && currentTrack ~= lastTrack
            selectedTracks(trackCount) = currentTrack;
            set(currentTrack, 'Color', [0 1 0]);
            lastTrack = currentTrack;
            trackCount = trackCount + 1;
        end
        
    end
                        
%% select all the tracks callback function    
    function selectAllTracksCallback(source, event)
        % selects all the tracks
        isAllTracks = 1;
        % make all the tracks green
        for i=1:size(Tracks,2)
            set(plotList(i), 'Color', [0 1 0]);
        end
    end

%% view rotation callback
    function viewCallback(source, event)
        figure(f3);
        view(str2num_fast(azimuthStartBox.String),str2num_fast(elevationStartBox.String));
    end

%% preview axis labels
    function previewAxisCallback(source, event)
        % start the gif making process
        figure(f3);
        
        if isPreview == 0
            isPreview = 1;
            source.String = 'Exit preview';
            if size(selectedTracks, 2) > 0 || isAllTracks == 1 % make sure there are tracks selected
                % hide all the visible tracks except the selected tracks
                for i=1:size(plotList,2)
                    if isequal(get(plotList(i),'Color'),[0 1 0]) == 0;
                        set(plotList(i),'Visible','off');
                    end
                end
                
                % determine the index of the selected track objects by comparing to Tracks input
                trackIndex = [];
                if isAllTracks == 0
                    for i=1:size(selectedTracks,2)
                        for j=1:size(Tracks,2)
                            object = get(selectedTracks(i));
                            if Tracks{j}(1,1) == object.XData(1) && Tracks{j}(1,2) == object.YData(1) && Tracks{j}(1,3) == object.ZData(1)
                                trackIndex(i) = j;
                                break;
                            end
                        end
                    end
                else
                    trackIndex = 1:size(Tracks,2); % want all the tracks
                end
                
                % determine the min and max time and axis limits for the selected tracks
                timeMax = 0;
                timeMin = MAX_TIME;
                MAX_X = 0;
                MAX_Y = 0;
                MAX_Z = 0;
                MIN_X = XMAX;
                MIN_Y = YMAX;
                
                for i=1:size(trackIndex,2)
                    tmpMax = max(Tracks{1,trackIndex(i)}(:,6));
                    if tmpMax > timeMax
                        timeMax = tmpMax;
                    end
                    tmpMin = min(Tracks{1,trackIndex(i)}(:,6));
                    if tmpMin < timeMin
                        timeMin = tmpMin;
                    end
                    % axis maximums
                    tmpX= max(Tracks{1,trackIndex(i)}(:,1));
                    if tmpX > MAX_X
                        MAX_X = tmpX;
                    end
                    tmpY= max(Tracks{1,trackIndex(i)}(:,2));
                    if tmpY > MAX_Y
                        MAX_Y = tmpY;
                    end
                    tmpZ = max(Tracks{1,trackIndex(i)}(:,3));
                    if tmpZ > MAX_Z
                        MAX_Z = tmpZ;
                    end
                    % axis minimums
                    tmpX= min(Tracks{1,trackIndex(i)}(:,1));
                    if tmpX < MIN_X
                        MIN_X = tmpX;
                    end
                    tmpY= min(Tracks{1,trackIndex(i)}(:,2));
                    if tmpY < MIN_Y
                        MIN_Y = tmpY;
                    end
                end
                MIN_X = MIN_X - 5;
                MIN_Y = MIN_Y - 5;
                MAX_X = MAX_X + 5;
                MAX_Y = MAX_Y + 5;
                MAX_Z = MAX_Z + 1;
                
                xlim([MIN_X MAX_X]);
                ylim([MIN_Y MAX_Y]);
                zlim([0 MAX_Z]);
                
                ax = gca; % get the current axis
                
                xStepSize = str2num_fast(xAxisSpaceBox.String);
                yStepSize = str2num_fast(yAxisSpaceBox.String);
                zStepSize = str2num_fast(zAxisSpaceBox.String);
                
                % round x min and max to multiple of 5 or 10 whichever is closest
                xRounded10 = round(MIN_X/5)*5;
                xRounded5 = round(MIN_X/10)*10;
                if abs(xRounded10-MIN_X) < abs(xRounded5-MIN_X)
                    MIN_X = xRounded10;
                else
                    MIN_X = xRounded5;
                end
                
                xRounded10 = round(MAX_X/5)*5;
                xRounded5 = round(MAX_X/10)*10;
                if abs(xRounded10-MAX_X) < abs(xRounded5-MAX_X)
                    MAX_X = xRounded10;
                else
                    MAX_X = xRounded5;
                end
                
                % build the xTick label set
                xTick = [MIN_X];
                xValue = MIN_X;
                while xValue <= MAX_X
                    xValue = xValue + xStepSize;
                    xTick = [xTick xValue];
                end
                
                % round y min and max to multiple of 5 or 10
                yRounded10 = round(MIN_Y/5)*5;
                yRounded5 = round(MIN_Y/10)*10;
                if abs(yRounded10-MIN_Y) < abs(yRounded5-MIN_Y)
                    MIN_Y = yRounded10;
                else
                    MIN_Y = yRounded5;
                end
                
                yRounded10 = round(MAX_Y/5)*5;
                yRounded5 = round(MAX_Y/10)*10;
                if abs(yRounded10-MAX_Y) < abs(yRounded5-MAX_Y)
                    MAX_Y = yRounded10;
                else
                    MAX_Y = yRounded5;
                end
                
                % built the y label ticks
                yTick = [MIN_Y];
                yValue = MIN_Y;
                while yValue <= MAX_Y
                    yValue = yValue + yStepSize;
                    yTick = [yTick yValue];
                end
                
                % round the z value max
                zRounded10 = round(MAX_Z/5)*5;
                zRounded5 = round(MAX_Z/10)*10;
                if abs(zRounded10-MAX_Z) < abs(zRounded5-MAX_Z)
                    MAX_Z = zRounded10;
                else
                    MAX_Z = zRounded5;
                end
                if MAX_Z == 0
                    MAX_Z = MAX_Z + 0.1;
                end
                
                % built the y label ticks
                zTick = [0];
                zValue = 0;
                while zValue <= MAX_Z
                    zValue = zValue + zStepSize;
                    zTick = [zTick zValue];
                end
                
                % update the axis ticks and labels
                ax.XTick = xTick;
                ax.XTickLabel = xTick;
                ax.YTick = yTick;
                ax.YTickLabel = yTick;
                ax.ZTick = zTick;
                ax.ZTickLabel = zTick;
            end
        else
            source.String = 'Preview axis labels';
            % reset the axis ticks
            figure(f3);
            % reset axis limits
            xlim([0 XMAX]);
            ylim([0 YMAX]);
            zlim([0 ZMAX+0.1]);
            
            set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto',...
                'YTickMode', 'auto', 'YTickLabelMode', 'auto',...
                'ZTickMode', 'auto', 'ZTickLabelMode', 'auto');
            
            % ensure track plots are visible
            for i=1:size(Tracks,2)
                set(plotList(i),'Visible','on');
            end
            
            isPreview = 0;
        end
    end

%% start gif callback
    function startGifCallback(source, event)
        % start the gif making process
        figure(f3);
        %set(f3,'color','none');
        
        % hide all the visible tracks
        for i=1:size(plotList,2)
            set(plotList(i),'Visible','off');
        end
        
        selectInstructionTxt.Visible = 'off'; % hide instruction text
        
        tailLength = str2num_fast(trackTailLengthBox.String);
        
        if size(selectedTracks, 2) > 0 || isAllTracks == 1 % make sure there are tracks selected
            
            % determine the index of the selected track objects by comparing to Tracks input
            trackIndex = [];
            if isAllTracks == 0
                for i=1:size(selectedTracks,2)
                    for j=1:size(Tracks,2)
                        object = get(selectedTracks(i));
                        if Tracks{j}(1,1) == object.XData(1) && Tracks{j}(1,2) == object.YData(1) && Tracks{j}(1,3) == object.ZData(1)
                            trackIndex(i) = j;
                            break;
                        end
                    end
                end
            else
                trackIndex = 1:size(Tracks,2); % want all the tracks
            end
            
            % determine the min and max time and axis limits for the selected tracks
            timeMax = 0;
            timeMin = MAX_TIME;
            MAX_X = 0;
            MAX_Y = 0;
            MAX_Z = 0;
            MIN_X = XMAX;
            MIN_Y = YMAX;
                        
            for i=1:size(trackIndex,2)
                tmpMax = max(Tracks{1,trackIndex(i)}(:,6));
                if tmpMax > timeMax
                    timeMax = tmpMax;
                end
                tmpMin = min(Tracks{1,trackIndex(i)}(:,6));
                if tmpMin < timeMin
                    timeMin = tmpMin;
                end
                % axis maximums
                tmpX= max(Tracks{1,trackIndex(i)}(:,1));
                if tmpX > MAX_X
                    MAX_X = tmpX;
                end
                tmpY= max(Tracks{1,trackIndex(i)}(:,2));
                if tmpY > MAX_Y
                    MAX_Y = tmpY;
                end
                tmpZ = max(Tracks{1,trackIndex(i)}(:,3));
                if tmpZ > MAX_Z
                    MAX_Z = tmpZ;
                end
                % axis minimums
                tmpX= min(Tracks{1,trackIndex(i)}(:,1));
                if tmpX < MIN_X
                    MIN_X = tmpX;
                end
                tmpY= min(Tracks{1,trackIndex(i)}(:,2));
                if tmpY < MIN_Y
                    MIN_Y = tmpY;
                end
            end
            MIN_X = MIN_X - 5;
            MIN_Y = MIN_Y - 5;
            MAX_X = MAX_X + 5;
            MAX_Y = MAX_Y + 5;
            MAX_Z = MAX_Z + 1;
            
            xlim([MIN_X MAX_X]);
            ylim([MIN_Y MAX_Y]);
            zlim([0 MAX_Z]);
            
            
            % create the top and bottom grey patches for the figure
            if isPatch
                topPatch = patch([MIN_X-5 MAX_X+5 MAX_X+5 MIN_X-5],[MIN_Y-5 MIN_Y-5 MAX_Y+5 MAX_Y+5],[MAX_Z MAX_Z MAX_Z MAX_Z],'black','FaceAlpha',.03, 'EdgeAlpha',0.2);
                bottomPatch = patch([MIN_X-5 MAX_X+5 MAX_X+5 MIN_X-5],[MIN_Y-5 MIN_Y-5 MAX_Y+5 MAX_Y+5],[0 0 0 0],'black','FaceAlpha',.03, 'EdgeAlpha',0.2);
            end
            
            ax = gca; % get the current axis
            
            xStepSize = str2num_fast(xAxisSpaceBox.String);
            yStepSize = str2num_fast(yAxisSpaceBox.String);
            zStepSize = str2num_fast(zAxisSpaceBox.String);
            
            % round x min and max to multiple of 5 or 10 whichever is closest
            xRounded10 = round(MIN_X/5)*5;
            xRounded5 = round(MIN_X/10)*10;
            if abs(xRounded10-MIN_X) < abs(xRounded5-MIN_X)
                MIN_X = xRounded10;
            else
                MIN_X = xRounded5;
            end
            
            xRounded10 = round(MAX_X/5)*5;
            xRounded5 = round(MAX_X/10)*10;
            if abs(xRounded10-MAX_X) < abs(xRounded5-MAX_X)
                MAX_X = xRounded10;
            else
                MAX_X = xRounded5;
            end
            
            % build the xTick label set
            xTick = [MIN_X];
            xValue = MIN_X;
            while xValue <= MAX_X
                xValue = xValue + xStepSize;
                xTick = [xTick xValue];
            end
            
            % round y min and max to multiple of 5 or 10
            yRounded10 = round(MIN_Y/5)*5;
            yRounded5 = round(MIN_Y/10)*10;
            if abs(yRounded10-MIN_Y) < abs(yRounded5-MIN_Y)
                MIN_Y = yRounded10;
            else
                MIN_Y = yRounded5;
            end
            
            yRounded10 = round(MAX_Y/5)*5;
            yRounded5 = round(MAX_Y/10)*10;
            if abs(yRounded10-MAX_Y) < abs(yRounded5-MAX_Y)
                MAX_Y = yRounded10;
            else
                MAX_Y = yRounded5;
            end
            
            % built the y label ticks
            yTick = [MIN_Y];
            yValue = MIN_Y;
            while yValue <= MAX_Y
                yValue = yValue + yStepSize;
                yTick = [yTick yValue];
            end
            
            % round the z value max
            zRounded10 = round(MAX_Z/5)*5;
            zRounded5 = round(MAX_Z/10)*10;
            if abs(zRounded10-MAX_Z) < abs(zRounded5-MAX_Z)
                MAX_Z = zRounded10;
            else
                MAX_Z = zRounded5;
            end
            
            % built the y label ticks
            zTick = [0];
            zValue = 0;
            while zValue <= MAX_Z
                zValue = zValue + zStepSize;
                zTick = [zTick zValue];
            end
            
            % update the axis ticks and labels
            ax.XTick = xTick;
            ax.XTickLabel = xTick;
            ax.YTick = yTick;
            ax.YTickLabel = yTick;
            ax.ZTick = zTick;
            ax.ZTickLabel = zTick;

            % creates the gif object that will be updated
            inputString = [filename 'Gif' num2str(GIF_COUNT) '.gif'];
            try
                gif(inputString, 'DelayTime', 1/str2num_fast(gifTimeBox.String), 'Frame', f3);
            catch
                disp('gif overwrite canceled');
                close(f4);
                return
            end
            
            % making the object handle list and shadows
            objectList = {};
            shadowObjects = {};
            for a=1:size(trackIndex,2)
                for b=1:tailLength+1
                    objectList{b,a} = 0;
                end
                shadowObjects{a} = 0;
            end
            
            trackIteration = ones(1,size(trackIndex,2)); % iterators for each of the tracks
            
            % make a progress bar
            progressBar = waitbar(0,'Creating GIF');
            set(progressBar, 'Units', 'normalized');
            movegui(progressBar, 'north');
            
            % calculate the azimuth and elevation step size
            azStep = (str2num_fast(azimuthEndBox.String)-str2num_fast(azimuthStartBox.String))/((timeMax-timeMin)/TIME_STEP);
            az = str2num_fast(azimuthStartBox.String);
            elStep = (str2num_fast(elevationEndBox.String)-str2num_fast(elevationStartBox.String))/((timeMax-timeMin)/TIME_STEP);
            el = str2num_fast(elevationStartBox.String);
            
            for t=timeMin:TIME_STEP:timeMax
                % loop through the time steps and diplay the objects
                timeTxt.String = ['Time (s): ' num2str(t)];
                
                for j=1:size(trackIndex,2) % loop through the selected indexs
                    % if the object is not out of range of the track and is matched with time t
                    if trackIteration(j) <= size(Tracks{1,trackIndex(j)},1) && Tracks{1,trackIndex(j)}(trackIteration(j),6) < t
                        figure(f3);
                        if tracksVisibleBox.Value == 1
                            % show tails as plot instead
                            if objectList{1,j} ~= 0
                                set(objectList{1,j}, 'Visible','off'); % hide the head of the tail
                            end
                            if objectList{2,j} ~= 0
                                set(objectList{2,j}, 'Visible','off');
                            end
                            
                            if trackIteration(j) - tailLength > 0
                                objectList{2,j} = plot3(Tracks{trackIndex(j)}(trackIteration(j)-tailLength:trackIteration(j),1), Tracks{trackIndex(j)}(trackIteration(j)-tailLength:trackIteration(j),2), Tracks{trackIndex(j)}(trackIteration(j)-tailLength:trackIteration(j),3), 'Color',[0.2 0.2 0.2]);
                            else
                                objectList{2,j} = plot3(Tracks{trackIndex(j)}(1:trackIteration(j),1), Tracks{trackIndex(j)}(1:trackIteration(j),2), Tracks{trackIndex(j)}(1:trackIteration(j),3), 'Color', [0.2 0.2 0.2]);
                            end
                        else
                            % else show the tail as individual objects
                            if objectList{1,j} ~= 0
                                if size(objectList{1,j}.XData,2) > 1
                                    set(objectList{1,j}, 'Visible', 'off');
                                    objectList{1,j} = scatter3(Tracks{1,trackIndex(j)}(trackIteration(j),1),Tracks{1,trackIndex(j)}(trackIteration(j),2),Tracks{1,trackIndex(j)}(trackIteration(j),3),1,[0.2 0.2 0.2], 'filled');
                                end
                                set(objectList{1,j}, 'MarkerEdgeColor', [0.2 0.2 0.2], 'MarkerFaceColor', [0.2 0.2 0.2],'SizeData', 1);
                            end
                            if objectList{tailLength+1,j} ~= 0
                                set(objectList{tailLength+1,j}, 'Visible','off'); % hide the end of the tail
                            end
                            for b=tailLength+1:-1:2
                                objectList{b,j} = objectList{b-1,j}; % shift the objects
                            end
                        end
                        % determine the color array of the object
                        colourRGB = colourcalc(Tracks{1,trackIndex(j)}(trackIteration(j),COLUMN), COLOUR_MAX, COLOUR_CHAR);
                        % plot the current objects point
                        if surfaceCellBox.Value == 1 && size(Tracks{trackIndex(j)},2) >=11 % && Tracks{1,trackIndex(j)}(trackIteration(j),3) <= SURFACE_THRESHHOLD
                            % if the object is below SURFACE_THRESHOLD(um) and blueSurface is on then make it blue
                            %objectList{1,j} = scatter3(Tracks{1,trackIndex(j)}(trackIteration(j),1),Tracks{1,trackIndex(j)}(trackIteration(j),2),Tracks{1,trackIndex(j)}(trackIteration(j),3),15,colourRGB, 'filled');
                            objectList{1,j} = drawCell([Tracks{1,trackIndex(j)}(trackIteration(j),1), Tracks{1,trackIndex(j)}(trackIteration(j),2)],Tracks{1,trackIndex(j)}(trackIteration(j),9), Tracks{1,trackIndex(j)}(trackIteration(j),10), Tracks{1,trackIndex(j)}(trackIteration(j),11), colourRGB);
                            %set(objectList{1,j}, 'MarkerEdgeColor', [0 0 1]);
                        else
                            objectList{1,j} = scatter3(Tracks{1,trackIndex(j)}(trackIteration(j),1),Tracks{1,trackIndex(j)}(trackIteration(j),2),Tracks{1,trackIndex(j)}(trackIteration(j),3),15,colourRGB, 'filled');
                        end
                        if shadowObjects{j} ~= 0
                            set(shadowObjects{j}, 'Visible','off');
                        end
                        shadowObjects{j} = scatter3(Tracks{1,trackIndex(j)}(trackIteration(j),1),Tracks{1,trackIndex(j)}(trackIteration(j),2),0, 40*(Tracks{1,trackIndex(j)}(trackIteration(j),3)/MAX_Z), [0.8 0.8 0.8], 'filled');
                        
                        
                        trackIteration(j) = trackIteration(j) + 1; % update the iterator for this track
                        
                        if trackIteration(j) > size(Tracks{1,trackIndex(j)},1) && tracksRemoveBox.Value == 1
                            % remove the visible components
                            for b=1:tailLength+1
                                if objectList{b,j} ~= 0
                                    set(objectList{b,j}, 'Visible','off');
                                end
                            end
                            set(shadowObjects{j},'Visible','off');
                        end
                    end
                end
                % update the view rotation
                view(az,el);
                az = az + azStep;
                el = el + elStep;
                
                % new method could be making a bunch of png files using
                % export_gif then at the end make the gif using imwrite
                
                gif % needs to be called to update the next frame of the gif
                waitbar(t/timeMax, progressBar, 'Creating GIF');
            end
            
            % now hide the objects since the gif is done
            for j=1:size(trackIndex,2)
                for b=1:tailLength+1
                    if objectList{b,j} ~= 0
                        delete(objectList{b,j});
                    end
                end
                if ishandle(shadowObjects{j}) % ensure the shadowObject is a handle and exists
                    delete(shadowObjects{j})
                end
            end
            
            % reset axis limits
            xlim([0 XMAX]);
            ylim([0 YMAX]);
            zlim([0 ZMAX+0.1]);
            
            if isPatch % delete the temporary patches
                delete(topPatch);
                delete(bottomPatch);
            end
            
            delete(progressBar);
            %set(f3,'color','white');
        end
        close(f4); % close the ui window that was opened
    end

%% Final actions before exiting makeGif.m
waitfor(f4); % wait until ui control figure is closed
delete(timeTxt); % remove the time string from figure 3
figure(f3);
% reset the axis ticks
set(gca, 'XTickMode', 'auto', 'XTickLabelMode', 'auto',...
         'YTickMode', 'auto', 'YTickLabelMode', 'auto',...
         'ZTickMode', 'auto', 'ZTickLabelMode', 'auto'); 
end

