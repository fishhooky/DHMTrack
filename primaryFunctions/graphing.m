function graphing(TIME_STEP, filenameList)
% Gives the user options for generating figures from the tracks produced in inspection.m
%
%   filenameList - the filenames of all the track files created in inspection step
%   TIME_STEP    - the ms aquisition time of the data originally captured
%
%   Andrew Woodward - Fall 2018

% open the first file in filenameList to get the Tracks
import = open(filenameList{1});
Tracks = import.Tracks;

TRACKS_LENGTH = size(Tracks,2); % the number of tracks in Tracks
GIF_COUNT = 1; % the number of gifs created
colorCharacter = 'c'; % default colour of tracks is cyan
fontFace = 'Helvetica';
fontSize = 10;

exportCount = 1; % used to add onto the filename for exporting multiple figures

%% Determine maximum limits of figures and graph coloring
MAX_X = 0; % x axis plot maximum
MAX_Y = 0; % y axis plot maximum
MAX_Z = 0; % z axis plot maximum

MIN_X = max(Tracks{1}(:,1)); % x axis plot minimum
MIN_Y = max(Tracks{1}(:,2)); % y axis plot minimum
MIN_Z = max(Tracks{1}(:,3)); % z axis plot minimum

MAX_COLOR_TIME = 0;
MAX_COLOR_SPEED = 0;
MAX_COLOR_ACCEL = 0;
MIN_COLOR_ACCEL = 0;

trackColorTimeArray = zeros(TRACKS_LENGTH);  % array to store the track mean time
trackColorSpeedArray = zeros(TRACKS_LENGTH); % array to store the track mean speed
trackColorAccelArray = zeros(TRACKS_LENGTH); % array to store the track mean acceleration

for i=1:TRACKS_LENGTH
    tmpMaxX = max(Tracks{1,i}(:,1));
    tmpMaxY = max(Tracks{1,i}(:,2));
    tmpMaxZ = max(Tracks{1,i}(:,3));
    
    tmpMinX = min(Tracks{1,i}(:,1));
    tmpMinY = min(Tracks{1,i}(:,2));
    tmpMinZ = min(Tracks{1,i}(:,3));
    
    tmpMaxTimeColor = max(Tracks{1,i}(:,6));
    trackColorTimeArray(i) = mean(Tracks{1,i}(:,6));
    tmpMaxSpeedColor = max(Tracks{1,i}(:,5));
    trackColorSpeedArray(i) = mean(Tracks{1,i}(:,5));
    
    if tmpMaxX > MAX_X
        MAX_X = tmpMaxX;
    end
    if tmpMaxY > MAX_Y
        MAX_Y = tmpMaxY;
    end
    if tmpMaxZ > MAX_Z
        MAX_Z = tmpMaxZ;
    end
    
    if tmpMinX < MIN_X
        MIN_X = tmpMinX;
    end
    if tmpMinY < MIN_Y
        MIN_Y = tmpMinY;
    end
    if tmpMinZ < MIN_Z
        MIN_Z = tmpMinZ;
    end
    
    if tmpMaxTimeColor > MAX_COLOR_TIME
        MAX_COLOR_TIME = tmpMaxTimeColor; 
    end
    if tmpMaxSpeedColor > MAX_COLOR_SPEED
        MAX_COLOR_SPEED = tmpMaxSpeedColor;
    end
    
    trackColorAccelArray(i) = mean(Tracks{1,i}(:,8));
    for j=1:size(Tracks{1,i},1)
        tmpAccelColor = Tracks{1,i}(j,8);
        if tmpAccelColor > MAX_COLOR_ACCEL && tmpAccelColor < 1250
            MAX_COLOR_ACCEL = tmpAccelColor;
        end
        if tmpAccelColor < MIN_COLOR_ACCEL && tmpAccelColor > -1250
            MIN_COLOR_ACCEL = tmpAccelColor;
        end
    end
end
MAX_X = MAX_X; % extend the limits a bit
MAX_Y = MAX_Y;
MAX_Z = MAX_Z+0.1;

%% Create the figure to be manipulated
f1 = figure('NumberTitle','off','Name','Figure for saving');
set(f1, 'units','normalized','Position', [0.2, 0.1, 0.75, 0.7]);
set(f1, 'Color', 'white');
ax1 = axes('Position',[0.075 0.1 0.75 0.8]);

str = version; % get the version number
if str2num_fast(str(1:3)) >= 9.5
    addToolbarExplorationButtons(f1); % this is for matlab r2018b might break on older versions
    disableDefaultInteractivity(ax1); % another change in matlab r2018b might break on older versions
end

objectList = []; % stores the object handles of each track
plotList = {}; % stores the handles for the plots
startObjectList = []; % stores the start object handles

figure(f1);
hold on
xlim([MIN_X MAX_X]);
ylim([MIN_Y MAX_Y]);
zlim([MIN_Z MAX_Z]);
view(45,25);
grid on;

% create the top and bottom grey patches for the figure
topPatch = patch([MIN_X MAX_X MAX_X MIN_X],[MIN_Y MIN_Y MAX_Y MAX_Y],[MAX_Z MAX_Z MAX_Z MAX_Z],'black','FaceAlpha',.05, 'EdgeAlpha',0.2);
bottomPatch = patch([MIN_X MAX_X MAX_X MIN_X],[MIN_Y MIN_Y MAX_Y MAX_Y],[MIN_Z MIN_Z MIN_Z MIN_Z],'black','FaceAlpha',.05, 'EdgeAlpha',0.2);


progressBar = waitbar(0,'Creating object handles');
set(progressBar, 'Units', 'normalized');
movegui(progressBar, 'north');
for i=1:TRACKS_LENGTH % loop through all the export tracks
    % plot the starting point of the track
    startObjectList(i) = scatter3(Tracks{1,i}(1,1), Tracks{1,i}(1,2), Tracks{1,i}(1,3), 20, [0 0 0], 'filled');
    % initialize this array to an empty array of zeros
    objectList(1,i) = 0;
    
    % plot the entire track as a line
    for j=2:size(Tracks{1,i},1)
        plotList{j-1,i} = plot3(Tracks{1,i}(j-1:j,1),Tracks{1,i}(j-1:j,2),Tracks{1,i}(j-1:j,3));
    end
    
    waitbar(i/TRACKS_LENGTH, progressBar, 'Creating object handles');
end
delete(progressBar);

% Create the colorbar
myColors = [1 0 0; 0 1 0; 0 0 1; 0 0 0; 1 1 1];
colormap(myColors);
ax2 = axes('Position',[0.9 0 0.1 1], 'Box', 'off','Visible','off');
cBar = colorbar('Position', [0.92 0.25 0.01 0.5], 'Ticks', [0,0.25, 0.5,0.75,1],...
                'TickLabels', {'1','2','3','4','5'},'AxisLocation','in', 'YAxisLocation','right');
axes(ax1);
ax = gca;
set(ax,'LabelFontSizeMultiplier',1);
set(ax,'FontSize',fontSize); % change all text font size
set(ax,'FontName',fontFace); % change all the text font face
cBar.FontName = fontFace;
cBar.FontSize = fontSize;
                
% contains the rgb triplets used for the colorbar each coloum represents a different colour set
RGBArray = load('RGBArray.mat');
RGBArray = RGBArray.rgbArray;

%% Create the gui
f2 = figure('NumberTitle','off','Name','Controls'); % second figure for gui controls so that f1 can be saved independently
set(f2, 'units','normalized','Position', [0.05, 0.2, 0.14, 0.6], 'MenuBar', 'none', 'ToolBar', 'none');

% Create drop down menu that allows for filtering the track types
dropColorType = uicontrol('Parent',f2,'Style', 'popup',...
                          'String', {'Time','Speed','Acceleration', 'Depth'},...
                          'units','normalized','Position', [0.15 0.245 0.7 0.05], 'Value', 2);%'Callback', @dropColorCallback);

% text for the drop down menu for track color filtering
dropColorTxt = uicontrol('Parent',f2, 'Style', 'text',...
                         'String', 'Change colour category *',...
                         'units','normalized','Position', [0.03 0.295 0.9 0.025]);
                   
% check box to make the objects visible
showObjectsBox = uicontrol('Parent', f2, 'Style', 'checkbox','Value',0,...
                           'units','normalized','Position',[0.15 0.06 0.9 0.05],...
                           'String', 'Show objects *');%, 'Callback', @showObjectsCallback);

                            
% check box to make the track lines visible
showTracksBox = uicontrol('Parent', f2, 'Style', 'checkbox','Value', 1,...
                          'units','normalized','Position',[0.15 0.1 0.9 0.05],...
                          'String', 'Show tracks', 'Callback', @showTracksCallback);

% choose the colour scheme from the available in colourScheme.mat
colorSchemeSelect = uicontrol('Parent', f2, 'Style', 'popup',...
                              'String', {'Red','Green','Blue', 'Yellow', 'Magenta', 'Cyan', 'White', 'Rainbow', 'RedToBlueWithGreen',...
                              'RedToBlue','BrownToGold','BlueToPink','BCGOR','WhiteToPurple','PurpleToOrange','BlackGreyRed','BlackToWhite','BlueToRed'},...
                              'units','normalized','Position', [0.15 0.32 0.7 0.05], 'Value', 6);%'Callback', @colorSelectionCallback);

colorSchemeTxt = uicontrol('Parent', f2, 'Style', 'text',...
                           'String', 'Change colour scheme *',...
                           'units','normalized','Position', [0.03 0.37 0.9 0.025]);

% input box for the azimuth of the figure
azimuthBox = uicontrol('Parent',f2,'style','edit',...
                       'units','normalized','position',[0.2 0.41 0.2 0.025],...
                       'string','25','Callback',@viewCallback); 

% input box for the elevation of the figure
elevationBox = uicontrol('Parent',f2,'style','edit',...
                         'units','normalized','position',[0.5 0.41 0.2 0.025],...
                         'string','45','Callback',@viewCallback); 

viewTxt = uicontrol('Parent', f2,'style','text','String', 'Azimuth   Elevation',...
                    'units','normalized','Position', [0.05 0.435 0.8 0.025]);
                
% input box for the xAxis label
xAxisLabelBox = uicontrol('Parent',f2,'style','edit',...
                          'units','normalized','position',[0.15 0.54 0.2 0.025],...
                          'string',['X (' char(181) 'm)'],'Callback',@axisLabelCallback);
                        
% input box for the yAxis label
yAxisLabelBox = uicontrol('Parent',f2,'style','edit',...
                          'units','normalized','position',[0.395 0.54 0.2 0.025],...
                          'string',['Y (' char(181) 'm)'],'Callback',@axisLabelCallback);
    
% input box for the zAxis label                         
zAxisLabelBox = uicontrol('Parent',f2,'style','edit',...
                          'units','normalized','position',[0.625 0.54 0.2 0.025],...
                          'string',['Z (' char(181) 'm)'],'Callback',@axisLabelCallback);
                         
axisLabelTxt = uicontrol('Parent',f2,'style','text','String','Axis label:  x    y    z',...
                         'units','normalized','Position', [0 0.565 0.9 0.025]);
                     
                     
% x axis tick spacing box
xAxisTicksBox = uicontrol('Parent',f2,'style','edit',...
                          'units','normalized','position',[0.15 0.48 0.2 0.025],...
                          'string','20','Callback',@axisTicksCallback);
                        
% y axis tick spacing box
yAxisTicksBox = uicontrol('Parent',f2,'style','edit',...
                          'units','normalized','position',[0.395 0.48 0.2 0.025],...
                          'string','20','Callback',@axisTicksCallback);
    
% z axis tick spacing box                         
zAxisTicksBox = uicontrol('Parent',f2,'style','edit',...
                          'units','normalized','position',[0.625 0.48 0.2 0.025],...
                          'string','20','Callback',@axisTicksCallback);
                         
axisTicksTxt = uicontrol('Parent',f2,'style','text','String','Axis tick spacing: x  y  z',...
                         'units','normalized','Position', [0 0.505 0.9 0.025]);
           
% font selection button
fontBtn = uicontrol('Parent', f2, 'Style', 'pushbutton', 'String', 'Change font',...
                    'units','normalized','Position', [0.15 0.6 0.7 0.04], 'Callback', @fontCallback);
                      
% update the figure objects                      
updateFigureBtn = uicontrol('Parent',f2,'style','pushbutton',...
                            'units', 'normalized', 'position', [0.15 0.65 0.7 0.04],...
                            'string', 'Update * properties', 'Callback', @updateFigureCallback);

% checkbox for disabling the figure gridlines
disableGridlines = uicontrol('Parent', f2, 'Style', 'checkbox','Value', 0,...
                             'units','normalized','Position',[0.15 0.21 0.8 0.025],...
                             'String', 'Disable gridlines', 'Callback', @disableGridlinesCallback);
                         
% checkbox for disabling the top/bottom patches
disablePatches = uicontrol('Parent', f2, 'Style', 'checkbox','Value', 0,...
                             'units','normalized','Position',[0.15 0.165 0.8 0.025],...
                             'String', 'Disable patches', 'Callback', @disablePatchesCallback);
                         
patchEditBtn = uicontrol('Parent',f2, 'Style','pushbutton', 'String','Edit patches',...
                         'units','normalized', 'position',[0.6 0.165 0.3 0.025],'Callback',@patchEditCallback);

% export figure button which saves the figure as a png in the filename folder
exportFigBtn = uicontrol('Parent',f2,'Style', 'pushbutton', 'String', 'Export Fig',...
                         'units','normalized','Position', [0.1 0.8 0.8 0.05], 'Callback', @exportFigCallback); 
                        
% the make gif button for opening the gif maker interface
makeGifBtn = uicontrol('Parent',f2,'Style', 'pushbutton', 'String', 'Make GIF',...
                       'units','normalized','Position', [0.1 0.87 0.8 0.05], 'Callback', @makeGifCallback);
                        
% object size input box
objectSizeBox = uicontrol('Parent', f2, 'Style', 'edit','units','normalized',...
                          'position',[0.15 0.03 0.15 0.03], 'string','10');%, 'Callback', @objectSizeCallback);
                         
objectSizeTxt = uicontrol('Parent', f2, 'Style', 'text', 'units', 'normalized',...
                          'position', [0.3 0.03 0.6 0.03], 'String', 'Set object size *');
                        
% exit button for exiting the graphing.m function
exitBtn = uicontrol('Parent', f2, 'Style', 'pushbutton', 'String', 'EXIT',...
                    'units','normalized','Position', [0.1 0.94 0.8 0.05], 'Callback', @exitCallback);

% choose file text string
trackFileTxt = uicontrol('Parent', f2, 'Style', 'text',...
                         'String', 'File select',...
                         'units','normalized','Position', [0.1 0.725 0.8 0.05]);
                
% choose the file for display
trackFileSelect = uicontrol('Parent', f2, 'Style', 'popup',...
                            'String', filenameList,...
                            'units','normalized','Position', [0.15 0.7 0.7 0.05], 'Value', 1, 'Callback', @trackFileCallback);
                
% initialize the figure with the default color and labels
dropColorCallback(dropColorType);
axisLabelCallback(xAxisLabelBox);
dropColorCallback(dropColorType); % dont know why but need to call twice for color bar to properly be colour on startup

%% Callback functions for UI elements
% update the figure callback
    function updateFigureCallback(source, event)
        % updates the figure with the settings changed
        colorSelectionCallback(colorSchemeSelect);
        % update the plots with the new colour selection
        dropColorCallback(dropColorType);
        % update the objects
        showObjectsCallback(showObjectsBox);
    end

%% Drop down color filter menu                    
    function dropColorCallback(source,event)
        % changes the colours of the plot objects
        switch source.Value
            case 1
                % 'Time'
                tmpColorMax = MAX_COLOR_TIME;
                tmpColorArray = trackColorTimeArray;
                column = 6;
            case 2
                % 'Speed'
                tmpColorMax = MAX_COLOR_SPEED;
                tmpColorArray = trackColorSpeedArray;
                column = 5;
            case 3
                % 'Acceleration'
                tmpColorMax = MAX_COLOR_ACCEL;
                tmpColorArray = trackColorAccelArray;
                column = 8;
            case 4
                % 'Depth'
                tmpColorMax = MAX_Z;
                tmpColorArray = zeros(1,TRACKS_LENGTH);
                column = 3;
        end
        
        progressBar = waitbar(0,'Updating tracks');
        set(progressBar, 'Units', 'normalized');
        movegui(progressBar, 'north');
        
        for a=1:TRACKS_LENGTH
            for b=1:size(Tracks{1,a},1)-1
                if column == 8 && Tracks{1,a}(b,column) > MAX_COLOR_ACCEL
                    inputColour = MAX_COLOR_ACCEL;
                elseif column == 8 && Tracks{1,a}(b,column) < MIN_COLOR_ACCEL
                    inputColour = MIN_COLOR_ACCEL;
                else
                    inputColour = Tracks{1,a}(b,column);
                end
                colorRGB = colourcalc(inputColour, tmpColorMax, colorCharacter); % returns a colour rgb array 
                if isnan(colorRGB)
                    colorRGB = [0 0 0];
                end
                set(plotList{b,a}, 'Color', colorRGB);
            end
            waitbar(a/TRACKS_LENGTH, progressBar, 'Updating tracks');
        end
        delete(progressBar);
        % update the colormap legend
        figure(f1);
        myColors = [RGBArray{1,colorSchemeSelect.Value}];
        for a=2:100
            myColors = [myColors; RGBArray{a,colorSchemeSelect.Value}];
        end
        colormap(myColors);
        switch dropColorType.Value
            case 1
                % 'Time'
                cBar.TickLabels = {num2str(0),num2str(round(0.25*MAX_COLOR_TIME,3,'significant')),num2str(round(0.5*MAX_COLOR_TIME,3,'significant')),num2str(round(0.75*MAX_COLOR_TIME,3,'significant')),num2str(round(MAX_COLOR_TIME,3,'significant'))};
                ylabel(cBar, 'Time (s)');
            case 2
                % 'Speed'
                cBar.TickLabels = {num2str(0),num2str(round(0.25*MAX_COLOR_SPEED,3,'significant')),num2str(round(0.5*MAX_COLOR_SPEED,3,'significant')),num2str(round(0.75*MAX_COLOR_SPEED,3,'significant')),num2str(round(MAX_COLOR_SPEED,3,'significant'))};
                ylabel(cBar,['Speed (' char(181) 'm/s)']);
            case 3
                % 'Acceleration'
                diff = MAX_COLOR_ACCEL - MIN_COLOR_ACCEL;
                cBar.TickLabels = {num2str(MIN_COLOR_ACCEL),num2str(round((0.25*diff)+MIN_COLOR_ACCEL,3,'significant')),num2str(round((0.5*diff)+MIN_COLOR_ACCEL,3,'significant')),num2str(round((0.75*diff)+MIN_COLOR_ACCEL,3,'significant')),num2str(round(MAX_COLOR_ACCEL,3,'significant'))};
                ylabel(cBar,['Accel (' char(181) 'm/s^2)']);
            case 4
                % 'Depth'
                cBar.TickLabels = {num2str(0),num2str(round(0.25*MAX_Z,3,'significant')),num2str(round(0.5*MAX_Z,3,'significant')),num2str(round(0.75*MAX_Z,3,'significant')),num2str(round(MAX_Z,3,'significant'))};
                ylabel(cBar,['Depth (' char(181) 'm)']);
        end 
    end

%% color selection drop down menu callback
    function colorSelectionCallback(source, event)
        switch source.Value
            case 1
                % 'Red'
                colorCharacter = 'r';
            case 2
                % 'Green'
                colorCharacter = 'g';
            case 3
                % 'Blue'
                colorCharacter = 'b';
            case 4
                % 'Yellow'
                colorCharacter = 'y';
            case 5
                % 'Magenta'
                colorCharacter = 'm';
            case 6
                % 'Cyan'
                colorCharacter = 'c';
            case 7
                % 'White'
                colorCharacter = 'k';
            case 8
                colorCharacter = 'rainbow';
            case 9
                colorCharacter = 'RedToBlueWithGreen';
            case 10
                colorCharacter = 'RedToBlue';
            case 11
                colorCharacter = 'BrownToGold';
            case 12
                colorCharacter = 'BlueToPink';
            case 13
                colorCharacter = 'BCGOR';
            case 14
                colorCharacter = 'WhiteToPurple';
            case 15
                colorCharacter = 'PurpleToOrange';
            case 16
                colorCharacter = 'BlackGreyRed';
            case 17
                colorCharacter = 'BlackToWhite';
            case 18
                colorCharacter = 'BlueToRed';
        end        
    end

%% Show objects box
    function showObjectsCallback(source, event)
        if source.Value == 1
            % the objects should be turned on
            progressBar = waitbar(0,'Updating objects');
            set(progressBar, 'Units', 'normalized');
            movegui(progressBar, 'north');
            
            switch dropColorType.Value
                case 1
                    % 'Time'
                    tmpColorMax = MAX_COLOR_TIME;
                    column = 6;
                case 2
                    % 'Speed'
                    tmpColorMax = MAX_COLOR_SPEED;
                    column = 5;
                case 3
                    % 'Acceleration'
                    tmpColorMax = MAX_COLOR_ACCEL;
                    column = 8;
                case 4
                    % 'Depth'
                    tmpColorMax = MAX_Z;
                    column = 3;
            end
            objectSize = str2num_fast(objectSizeBox.String);
            colorArray = {};
            for a=1:TRACKS_LENGTH % loop through all the tracks
                for b=1:size(Tracks{1,a},1) % update each object tracks
                    figure(f1);
                    rgb = colourcalc(Tracks{1,a}(b,column), tmpColorMax, colorCharacter);
                    colorArray{a}(b,1) = rgb(1);
                    colorArray{a}(b,2) = rgb(2);
                    colorArray{a}(b,3) = rgb(3);
                end
                if objectList(1,a) ~=0
                    delete(objectList(1,a));
                end
                objectList(1,a) = scatter3(Tracks{1,a}(:,1),Tracks{1,a}(:,2), Tracks{1,a}(:,3), objectSize, colorArray{a}, 'filled');
                waitbar(a/TRACKS_LENGTH, progressBar, 'Updating objects');
            end
            delete(progressBar);
        else
            % hide the objects
            for a=1:TRACKS_LENGTH
                if objectList(1,a) ~= 0
                    delete(objectList(1,a));
                    objectList(1,a) = 0;
                end
            end
        end
    end

%% Show tracks check box
    function showTracksCallback(source, event)
        if source.Value == 1
            % show the track plots
            for a=1:TRACKS_LENGTH
                for b=1:size(Tracks{1,a},1)-1
                    set(plotList{b,a}, 'Visible', 'on');
                end
                set(startObjectList(a), 'Visible', 'on');
            end
        else
            % hide the track plots
            for a=1:TRACKS_LENGTH
                for b=1:size(Tracks{1,a},1)-1
                    set(plotList{b,a}, 'Visible', 'off');
                end
                set(startObjectList(a), 'Visible', 'off');
            end
        end
    end

%% View orientation input fields callback    
    function viewCallback(source, event)
        figure(f1)
        view(str2num_fast(azimuthBox.String), str2num_fast(elevationBox.String));
    end

%% Axis label callback
    function axisLabelCallback(source, event)
        figure(f1)
        xlabel(xAxisLabelBox.String);
        ylabel(yAxisLabelBox.String);
        zlabel(zAxisLabelBox.String);
    end


%% Axis spacing ticks callback
    function axisTicksCallback(source,event)
        figure(f1);
        ax = gca; % get the current axis
        
        xStepSize = str2num_fast(xAxisTicksBox.String);
        yStepSize = str2num_fast(yAxisTicksBox.String);
        zStepSize = str2num_fast(zAxisTicksBox.String);
        
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
        while zValue <= MAX_Z+1
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

%% Disable the grid lines callback
    function disableGridlinesCallback(source, event)
        figure(f1)
        if source.Value==1
            grid off
        else
            grid on
        end
    end

%% disable top and bottom patch callback
    function disablePatchesCallback(source,event)
        if source.Value==1
            topPatch.Visible = 'off';
            bottomPatch.Visible = 'off';
        else
            topPatch.Visible = 'on';
            bottomPatch.Visible = 'on';
        end
    end

%% edit the patches callback
    function patchEditCallback(source, event)
        % give user dialog box to enter the locations of the patch top and
        % bottom z height (maybe also x and y?)
        f4 = figure('NumberTitle','off','Name','Controls'); % second figure for gui controls so that f1 can be saved independently
        set(f4, 'units','normalized','Position', [0.075, 0.3, 0.1, 0.1], 'MenuBar', 'none', 'ToolBar', 'none');

        zMaxControl = uicontrol('Parent',f4,'style','edit',...
                                'units','normalized','position',[0.05 0.6 0.5 0.3],...
                                'string',num2str(MAX_Z));
                            
        zMaxTxt = uicontrol('Parent', f4, 'Style', 'text', 'units', 'normalized',...
                            'position', [0.55 0.55 0.4 0.3], 'String', 'Max Z');
                            
        zMinControl = uicontrol('Parent',f4,'style','edit',...
                                'units','normalized','position',[0.05 0.1 0.5 0.3],...
                                'string',num2str(MIN_Z));
                            
        zMinTxt = uicontrol('Parent', f4, 'Style', 'text', 'units', 'normalized',...
                            'position', [0.55 0.075 0.4 0.3], 'String', 'Min Z');
                        
        while ishandle(f4) % wait until this dialog box is closed
            zMax = str2num_fast(zMaxControl.String);
            zMin = str2num_fast(zMinControl.String);
            pause(0.1);
        end
        
        delete(topPatch);
        delete(bottomPatch);
        
        figure(f1);
        % create the top and bottom grey patches for the figure
        topPatch = patch([MIN_X MAX_X MAX_X MIN_X],[MIN_Y MIN_Y MAX_Y MAX_Y],[zMax zMax zMax zMax],'black','FaceAlpha',.05, 'EdgeAlpha',0.2);
        bottomPatch = patch([MIN_X MAX_X MAX_X MIN_X],[MIN_Y MIN_Y MAX_Y MAX_Y],[zMin zMin zMin zMin],'black','FaceAlpha',.05, 'EdgeAlpha',0.2);
    end

%% Change font type and size callback
    function fontCallback(source, event)
        myfont = uisetfont; % font ui chooser
        if isstruct(myfont) % ensure cancel wasn't selected
            ax = findobj('Type','axes'); % get all axes
            fontFace = myfont.FontName;
            fontSize = myfont.FontSize;
            set(ax,'FontSize',fontSize); % change all text font size
            set(ax,'FontName',fontFace); % change all the text font face
            
            cBar.FontName = fontFace;
            cBar.FontSize = fontSize;
        end 
    end

%% Export the figure callback
    function exportFigCallback(source, event)
        % export the figure
        %set(f1,'color','none');
        %saveas(f1,[filename num2str(exportCount) '.png']);
        %set(f1,'color','white');
        figure(f1);
        string = [filenameList{trackFileSelect.Value}(1:end-4) 'Fig' num2str(exportCount) '.png'];
        export_fig(string, '-transparent');
        exportCount = exportCount + 1;
    end

%% change track file callback
    function trackFileCallback(source, event)
        clf(f1); % clear the figure
        
        % open the first file in filenameList to get the Tracks
        import = open(filenameList{source.Value});
        Tracks = import.Tracks;
        
        TRACKS_LENGTH = size(Tracks,2); % the number of tracks in Tracks
        GIF_COUNT = 1; % the number of gifs created
        colorCharacter = 'c'; % default colour of tracks is cyan
        fontFace = 'Helvetica';
        fontSize = 10;
        
        exportCount = 1; % used to add onto the filename for exporting multiple figures
        
        % Determine maximum limits of figures and graph coloring
        MAX_X = 0; % x axis plot maximum
        MAX_Y = 0; % y axis plot maximum
        MAX_Z = 0; % z axis plot maximum
        
        MIN_X = max(Tracks{1}(:,1)); % x axis plot minimum
        MIN_Y = max(Tracks{1}(:,2)); % y axis plot minimum
        MIN_Z = max(Tracks{1}(:,3)); % z axis plot minimum
        
        MAX_COLOR_TIME = 0;
        MAX_COLOR_SPEED = 0;
        MAX_COLOR_ACCEL = 0;
        MIN_COLOR_ACCEL = 0;
        
        trackColorTimeArray = zeros(TRACKS_LENGTH);  % array to store the track mean time
        trackColorSpeedArray = zeros(TRACKS_LENGTH); % array to store the track mean speed
        trackColorAccelArray = zeros(TRACKS_LENGTH); % array to store the track mean acceleration
        
        for a=1:TRACKS_LENGTH
            tmpMaxX = max(Tracks{1,a}(:,1));
            tmpMaxY = max(Tracks{1,a}(:,2));
            tmpMaxZ = max(Tracks{1,a}(:,3));
            
            tmpMinX = min(Tracks{1,a}(:,1));
            tmpMinY = min(Tracks{1,a}(:,2));
            tmpMinZ = min(Tracks{1,a}(:,3));
            
            tmpMaxTimeColor = max(Tracks{1,a}(:,6));
            trackColorTimeArray(a) = mean(Tracks{1,a}(:,6));
            tmpMaxSpeedColor = max(Tracks{1,a}(:,5));
            trackColorSpeedArray(a) = mean(Tracks{1,a}(:,5));
            
            if tmpMaxX > MAX_X
                MAX_X = tmpMaxX;
            end
            if tmpMaxY > MAX_Y
                MAX_Y = tmpMaxY;
            end
            if tmpMaxZ > MAX_Z
                MAX_Z = tmpMaxZ;
            end
            
            if tmpMinX < MIN_X
                MIN_X = tmpMinX;
            end
            if tmpMinY < MIN_Y
                MIN_Y = tmpMinY;
            end
            if tmpMinZ < MIN_Z
                MIN_Z = tmpMinZ;
            end
            
            if tmpMaxTimeColor > MAX_COLOR_TIME
                MAX_COLOR_TIME = tmpMaxTimeColor;
            end
            if tmpMaxSpeedColor > MAX_COLOR_SPEED
                MAX_COLOR_SPEED = tmpMaxSpeedColor;
            end
            
            trackColorAccelArray(a) = mean(Tracks{1,a}(:,8));
            for b=1:size(Tracks{1,a},1)
                tmpAccelColor = Tracks{1,a}(b,8);
                if tmpAccelColor > MAX_COLOR_ACCEL && tmpAccelColor < 1250
                    MAX_COLOR_ACCEL = tmpAccelColor;
                end
                if tmpAccelColor < MIN_COLOR_ACCEL && tmpAccelColor > -1250
                    MIN_COLOR_ACCEL = tmpAccelColor;
                end
            end
        end
        MAX_X = MAX_X; % extend the limits a bit
        MAX_Y = MAX_Y;
        MAX_Z = MAX_Z+0.1;
        
        % Create the figure to be manipulated
        %f1 = figure('NumberTitle','off','Name','Figure for saving');
        %set(f1, 'units','normalized','Position', [0.2, 0.1, 0.75, 0.7]);
        %set(f1, 'Color', 'white');
        
        objectList = []; % stores the object handles of each track
        plotList = {}; % stores the handles for the plots
        startObjectList = []; % stores the start object handles
        
        figure(f1);
        ax1 = axes('Position',[0.075 0.1 0.75 0.8]);
        hold on
        xlim([MIN_X MAX_X]);
        ylim([MIN_Y MAX_Y]);
        zlim([MIN_Z MAX_Z]);
        view(45,25);
        grid on;
        
        
        % create the top and bottom grey patches for the figure
        delete(topPatch);
        delete(bottomPatch);
        topPatch = patch([MIN_X MAX_X MAX_X MIN_X],[MIN_Y MIN_Y MAX_Y MAX_Y],[MAX_Z MAX_Z MAX_Z MAX_Z],'black','FaceAlpha',.05, 'EdgeAlpha',0.2);
        bottomPatch = patch([MIN_X MAX_X MAX_X MIN_X],[MIN_Y MIN_Y MAX_Y MAX_Y],[MIN_Z MIN_Z MIN_Z MIN_Z],'black','FaceAlpha',.05, 'EdgeAlpha',0.2);

        
        %progressBar = waitbar(0,'Creating object handles');
        %set(progressBar, 'Units', 'normalized');
        %set(progressBar, 'Position', [0.35 0.87 0.3 0.08]);
        for a=1:TRACKS_LENGTH % loop through all the export tracks
            % plot the starting point of the track
            startObjectList(a) = scatter3(Tracks{1,a}(1,1), Tracks{1,a}(1,2), Tracks{1,a}(1,3), 20, [0 0 0], 'filled');
            % initialize this array to an empty array of zeros
            objectList(1,a) = 0;
            
            % plot the entire track as a line
            for b=2:size(Tracks{1,a},1)
                plotList{b-1,a} = plot3(Tracks{1,a}(b-1:b,1),Tracks{1,a}(b-1:b,2),Tracks{1,a}(b-1:b,3));
            end
            
            %plotList(i) = plot3(Tracks{1,i}(:,1), Tracks{1,i}(:,2), Tracks{1,i}(:,3)); %plot the tracks
            %waitbar(i/TRACKS_LENGTH, progressBar, 'Creating object handles');
        end
        %delete(progressBar);
        
        % Create the colorbar
        myColors = [1 0 0; 0 1 0; 0 0 1; 0 0 0; 1 1 1];
        colormap(myColors);
        ax2 = axes('Position',[0.9 0 0.1 1], 'Box', 'off','Visible','off');
        cBar = colorbar('Position', [0.92 0.25 0.01 0.5], 'Ticks', [0,0.25, 0.5,0.75,1],...
                'TickLabels', {'1','2','3','4','5'},'AxisLocation','in', 'YAxisLocation','right');
        axes(ax1);
        % initialize the figure with the default color and labels
        dropColorCallback(dropColorType);
        axisLabelCallback(xAxisLabelBox);
    end

%% Opens the gif creation UI
    function makeGifCallback(source, event)
        % hide the objects of the tracks
        showObjectsBox.Value = 0;
        showTracksBox.Value = 0;
        if disablePatches.Value == 1
            isPatch = 0;
        else
            isPatch = 1;
        end
        disablePatches.Value = 1;
        disablePatchesCallback(disablePatches);
        showObjectsCallback(showObjectsBox);
        showTracksCallback(showTracksBox);
        
        % determine the colour scheme drop color type
        switch dropColorType.Value
            case 1
                % 'Time'
                tmpColorMax = MAX_COLOR_TIME;
                column = 6;
            case 2
                % 'Speed'
                tmpColorMax = MAX_COLOR_SPEED;
                column = 5;
            case 3
                % 'Acceleration'
                tmpColorMax = MAX_COLOR_ACCEL;
                column = 8;
            case 4
                % 'Depth'
                tmpColorMax = MAX_Z;
                column = 3;
        end
        
        % makeGif will give more UI controls and generate the gif
        makeGif(Tracks,filenameList{trackFileSelect.Value}(1:end-4), f1, colorCharacter,column, tmpColorMax, MAX_COLOR_TIME, TIME_STEP/1000, GIF_COUNT, MAX_X, MAX_Y, MAX_Z, fontFace, fontSize, isPatch);
        GIF_COUNT = GIF_COUNT + 1; % update the count of the number of GIFS created
        
        % reset the axis limits
        figure(f1);
        xlim([MIN_X MAX_X]);
        ylim([MIN_Y MAX_Y]);
        zlim([MIN_Z MAX_Z]);
        
        % create the top and bottom grey patches for the figure
        delete(topPatch);
        delete(bottomPatch);
        topPatch = patch([MIN_X MAX_X MAX_X MIN_X],[MIN_Y MIN_Y MAX_Y MAX_Y],[MAX_Z MAX_Z MAX_Z MAX_Z],'black','FaceAlpha',.05, 'EdgeAlpha',0.2);
        bottomPatch = patch([MIN_X MAX_X MAX_X MIN_X],[MIN_Y MIN_Y MAX_Y MAX_Y],[MIN_Z MIN_Z MIN_Z MIN_Z],'black','FaceAlpha',.05, 'EdgeAlpha',0.2);
       
        % reset the figure
        updateFigureCallback();
        showTracksBox.Value = 1;
        showTracksCallback(showTracksBox);
        
        if isPatch==1
            disablePatches.Value = 0;
            disablePatchesCallback(disablePatches);
        end
    end

%% Exit button callback
    function exitCallback(source, event)
        % close the figure windows which will result in graphing.m to be exited
        close(f2);
        close(f1);
    end

waitfor(f1); % waits for the f1 to be closed from the exitbutton callback
end

