function [toggleArray, minMaxArray] = filterUI(inputToggle, inputMinMax, Tracks, MSDArray)
% Creates the ui for the filtering options and returns the values the user enters
% 
%   Input:
%           inputToggle - input array signifying which options are chosen
%           inputMinMax - input array signifying what the min and max of each toggle
%           Tracks      - the tracks used for making the histograms
%           MSDArray    - the msd of all the tracks used for the histograms
%
%   Output:
%           toggleArray - the array signifying which options are chosen
%           minMaxArray - the array signifying what the min and max of each toggle
%
% Andrew Woodward - Fall 2018
%

% create the ui figure
fig = figure('NumberTitle','off','Name','Advanced Filtering');
set(fig, 'units','normalized','Position', [0.15, 0.2, 0.2, 0.45], 'MenuBar', 'none', 'ToolBar', 'none');

% create the time histogram
timeFig = figure('NumberTitle','off','Name','Time Histogram'); 
set(timeFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
tmp = [];
iter = 1;
for i=1:size(Tracks,2)
    tmp(iter) = mean(Tracks{1,i}(:,6));
    iter = iter+1;
end
hist(tmp);
set(timeFig, 'Visible', 'off');

% create the speed histogram
speedFig = figure('NumberTitle','off','Name','Speed Histogram'); 
set(speedFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
tmp = [];
iter = 1;
for i=1:size(Tracks,2)
    tmp(iter) = mean(Tracks{1,i}(:,5));
    iter = iter+1;
end
hist(tmp);
set(speedFig, 'Visible', 'off');

% create the acceleration histogram
accelFig = figure('NumberTitle','off','Name','Accel Histogram'); 
set(accelFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
tmp = [];
iter = 1;
for i=1:size(Tracks,2)
    for j=1:size(Tracks{1,i},1)
        tmp(iter) = Tracks{1,i}(j,8);
        iter = iter+1;
    end
end
hist(tmp);
set(accelFig, 'Visible', 'off');

% create the x axis histogram
xFig = figure('NumberTitle','off','Name','X axis Histogram');
set(xFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
tmp = [];
iter = 1;
for i=1:size(Tracks,2)
    for j=1:size(Tracks{1,i},1)
        tmp(iter) = Tracks{1,i}(j,1);
        iter = iter+1;
    end
end
hist(tmp);
set(xFig, 'Visible', 'off');

% create the y axis histogram
yFig = figure('NumberTitle','off','Name','Y axis Histogram');
set(yFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
tmp = [];
iter = 1;
for i=1:size(Tracks,2)
    for j=1:size(Tracks{1,i},1)
        tmp(iter) = Tracks{1,i}(j,2);
        iter = iter+1;
    end
end
hist(tmp);
set(yFig, 'Visible', 'off');

% create the z axis histogram
zFig = figure('NumberTitle','off','Name','Z axis Histogram');
set(zFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
tmp = [];
iter = 1;
for i=1:size(Tracks,2)
    for j=1:size(Tracks{1,i},1)
        tmp(iter) = Tracks{1,i}(j,3);
        iter = iter+1;
    end
end
hist(tmp);
set(zFig, 'Visible', 'off');

% create the volume histogram
volFig = figure('NumberTitle','off','Name','Volume Histogram');
set(volFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
tmp = [];
iter = 1;
for i=1:size(Tracks,2)
    tmp(iter) = mean(Tracks{1,i}(:,4));
    iter = iter+1;
end
hist(tmp);
set(volFig, 'Visible', 'off');

% create the MSD histogram
MSDFig = figure('NumberTitle','off','Name','MSD Histogram');
set(MSDFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
hist(MSDArray);
set(MSDFig, 'Visible', 'off');

% create the width histogram
if size(Tracks{1,1},2) > 8
    widthFig = figure('NumberTitle','off','Name','Width Histogram');
    set(widthFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
    tmp = [];
    iter = 1;
    for i=1:size(Tracks,2)
        tmp(iter) = mean(Tracks{1,i}(:,10));
        iter = iter+1;
    end
    hist(tmp);
    set(widthFig, 'Visible', 'off');
end

% create the length histogram
if size(Tracks{1,1},2) > 8
    lengthFig = figure('NumberTitle','off','Name','Length Histogram');
    set(lengthFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
    tmp = [];
    iter = 1;
    for i=1:size(Tracks,2)
        tmp(iter) = mean(Tracks{1,i}(:,9));
        iter = iter+1;
    end
    hist(tmp);
    set(lengthFig, 'Visible', 'off');
end

% create the track duration histogram
durationFig = figure('NumberTitle','off','Name','Duration Histogram');
set(durationFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
tmp = [];
iter = 1;
for i=1:size(Tracks,2)
    tmp(iter) = size(Tracks{i},1);
    iter = iter+1;
end
hist(tmp);
set(durationFig, 'Visible', 'off');


% create the confinement ratio histogram
confinementFig = figure('NumberTitle','off','Name','Confinement Ratio Histogram');
set(confinementFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
totalDist = [];
netDist = [];
for i=1:size(Tracks,2)
    if size(Tracks{i},1) > 0
        netDist(i) = sqrt((Tracks{i}(size(Tracks{i},1),1)-Tracks{i}(1,1))^2 + (Tracks{i}(size(Tracks{i},1),2)-Tracks{i}(1,2))^2 + (Tracks{i}(size(Tracks{i},1),2)-Tracks{i}(1,2))^2);
        dist = 0;
        for j=2:size(Tracks{i},1)
            dist = dist + sqrt((Tracks{i}(j,1)-Tracks{i}(j-1,1))^2 + (Tracks{i}(j,2)-Tracks{i}(j-1,2))^2 + (Tracks{i}(j,2)-Tracks{i}(j-1,2))^2);
        end
        totalDist(i) = dist;
    end
end
confinementRatio = netDist ./ totalDist;
hist(confinementRatio);
set(confinementFig, 'Visible', 'off');


isSpeed = 0;
isAccel = 0;
isX = 0;
isY = 0;
isZ = 0;
isVol = 0;
isMSD = 0;
isWidth = 0;
isLength = 0;
isTime = 0;
isDuration = 0;
isConfinement = 0;

toggleArray = [];
minMaxArray = [];

exitBtn = uicontrol('Parent', fig, 'Style', 'pushbutton', 'String', 'Apply',...
                    'units', 'normalized', 'Position', [0.05 0.9 0.425 0.07], 'Callback', @exitBtnCallback);
                
resetBtn = uicontrol('Parent',fig, 'Style', 'pushbutton', 'String', 'Reset filters',...
                    'units', 'normalized', 'Position', [0.525 0.9 0.425 0.07], 'Callback', @resetBtnCallback);

toggleTxt = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Toggle Filters',...
                        'units', 'normalized', 'Position', [0 0.85 0.3 0.05]);

minTxt = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Min',...
                        'units', 'normalized', 'Position', [0.375 0.85 0.2 0.05]);
                    
maxTxt = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Max',...
                   'units', 'normalized', 'Position', [0.575 0.85 0.2 0.05]);
               
histTxt = uicontrol('Parent', fig, 'Style', 'text', 'String', 'Histogram',...
                   'units', 'normalized', 'Position', [0.8 0.85 0.2 0.05]);

% time controls
timeToggle = uicontrol('Parent', fig, 'Style', 'checkbox', 'String', 'time',...
                        'units','normalized', 'Position', [0.05 0.8 0.3 0.05], 'Value', inputToggle(10));

timeMin = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(10,1)),...
                     'units', 'normalized', 'Position', [0.4 0.8 0.15 0.05]);
                 
timeMax = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(10,2)),...
                     'units', 'normalized', 'Position', [0.6 0.8 0.15 0.05]);
                 
timeHist = uicontrol('Parent',fig, 'Style','pushbutton', 'String', 'Open',...
                      'units', 'normalized', 'Position', [0.8 0.8 0.2 0.05], 'Callback', @timeHistCallback);

                          
% speed controls
speedToggle = uicontrol('Parent', fig, 'Style', 'checkbox', 'String', 'speed',...
                        'units','normalized', 'Position', [0.05 0.73 0.3 0.05], 'Value', inputToggle(1));

speedMin = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(1,1)),...
                     'units', 'normalized', 'Position', [0.4 0.73 0.15 0.05]);
                 
speedMax = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(1,2)),...
                     'units', 'normalized', 'Position', [0.6 0.73 0.15 0.05]);
                 
speedHist = uicontrol('Parent',fig, 'Style','pushbutton', 'String', 'Open',...
                      'units', 'normalized', 'Position', [0.8 0.73 0.2 0.05], 'Callback', @speedHistCallback);

% accel controls
accelToggle = uicontrol('Parent', fig, 'Style', 'checkbox', 'String', 'acceleration',...
                        'units','normalized', 'Position', [0.05 0.66 0.3 0.05], 'Value', inputToggle(2));

accelMin = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(2,1)),...
                     'units', 'normalized', 'Position', [0.4 0.66 0.15 0.05]);
                 
accelMax = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(2,2)),...
                     'units', 'normalized', 'Position', [0.6 0.66 0.15 0.05]);
                 
accelHist = uicontrol('Parent',fig, 'Style','pushbutton', 'String', 'Open',...
                      'units', 'normalized', 'Position', [0.8 0.66 0.2 0.05], 'Callback', @accelHistCallback);

% x controls
xToggle = uicontrol('Parent', fig, 'Style', 'checkbox', 'String', 'x axis',...
                        'units','normalized', 'Position', [0.05 0.59 0.3 0.05], 'Value', inputToggle(3));

xMin = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(3,1)),...
                     'units', 'normalized', 'Position', [0.4 0.59 0.15 0.05]);
                 
xMax = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(3,2)),...
                     'units', 'normalized', 'Position', [0.6 0.59 0.15 0.05]);
                 
xHist = uicontrol('Parent',fig, 'Style','pushbutton', 'String', 'Open',...
                      'units', 'normalized', 'Position', [0.8 0.59 0.2 0.05], 'Callback', @xHistCallback);

% y controls
yToggle = uicontrol('Parent', fig, 'Style', 'checkbox', 'String', 'y axis',...
                        'units','normalized', 'Position', [0.05 0.52 0.3 0.05], 'Value', inputToggle(4));

yMin = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(4,1)),...
                     'units', 'normalized', 'Position', [0.4 0.52 0.15 0.05]);
                 
yMax = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(4,2)),...
                     'units', 'normalized', 'Position', [0.6 0.52 0.15 0.05]);
                 
yHist = uicontrol('Parent',fig, 'Style','pushbutton', 'String', 'Open',...
                      'units', 'normalized', 'Position', [0.8 0.52 0.2 0.05], 'Callback', @yHistCallback);

% z controls
zToggle = uicontrol('Parent', fig, 'Style', 'checkbox', 'String', 'z axis',...
                        'units','normalized', 'Position', [0.05 0.45 0.3 0.05], 'Value', inputToggle(5));

zMin = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(5,1)),...
                     'units', 'normalized', 'Position', [0.4 0.45 0.15 0.05]);
                 
zMax = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(5,2)),...
                     'units', 'normalized', 'Position', [0.6 0.45 0.15 0.05]);
                 
zHist = uicontrol('Parent',fig, 'Style','pushbutton', 'String', 'Open',...
                      'units', 'normalized', 'Position', [0.8 0.45 0.2 0.05], 'Callback', @zHistCallback);

% volume controls
volumeToggle = uicontrol('Parent', fig, 'Style', 'checkbox', 'String', 'volume',...
                        'units','normalized', 'Position', [0.05 0.38 0.3 0.05], 'Value', inputToggle(6));

volumeMin = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(6,1)),...
                     'units', 'normalized', 'Position', [0.4 0.38 0.15 0.05]);
                 
volumeMax = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(6,2)),...
                     'units', 'normalized', 'Position', [0.6 0.38 0.15 0.05]);
                 
volumeHist = uicontrol('Parent',fig, 'Style','pushbutton', 'String', 'Open',...
                      'units', 'normalized', 'Position', [0.8 0.38 0.2 0.05], 'Callback', @volumeHistCallback);

% MSD controls
MSDToggle = uicontrol('Parent', fig, 'Style', 'checkbox', 'String', 'MSD',...
                        'units','normalized', 'Position', [0.05 0.31 0.3 0.05], 'Value', inputToggle(7));

MSDMin = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(7,1)),...
                     'units', 'normalized', 'Position', [0.4 0.31 0.15 0.05]);
                 
MSDMax = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(7,2)),...
                     'units', 'normalized', 'Position', [0.6 0.31 0.15 0.05]);
                 
MSDHist = uicontrol('Parent',fig, 'Style','pushbutton', 'String', 'Open',...
                      'units', 'normalized', 'Position', [0.8 0.31 0.2 0.05], 'Callback', @MSDHistCallback);
 
% width controls
widthToggle = uicontrol('Parent', fig, 'Style', 'checkbox', 'String', 'cell width',...
                        'units','normalized', 'Position', [0.05 0.24 0.3 0.05], 'Value', inputToggle(8));

widthMin = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(8,1)),...
                     'units', 'normalized', 'Position', [0.4 0.24 0.15 0.05]);
                 
widthMax = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(8,2)),...
                     'units', 'normalized', 'Position', [0.6 0.24 0.15 0.05]);
                 
widthHist = uicontrol('Parent',fig, 'Style','pushbutton', 'String', 'Open',...
                      'units', 'normalized', 'Position', [0.8 0.24 0.2 0.05], 'Callback', @widthHistCallback);
                 
% length controls
lengthToggle = uicontrol('Parent', fig, 'Style', 'checkbox', 'String', 'cell length',...
                        'units','normalized', 'Position', [0.05 0.17 0.3 0.05], 'Value', inputToggle(9));

lengthMin = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(9,1)),...
                     'units', 'normalized', 'Position', [0.4 0.17 0.15 0.05]);
                 
lengthMax = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(9,2)),...
                     'units', 'normalized', 'Position', [0.6 0.17 0.15 0.05]);
                 
lengthHist = uicontrol('Parent',fig, 'Style','pushbutton', 'String', 'Open',...
                      'units', 'normalized', 'Position', [0.8 0.17 0.2 0.05], 'Callback', @lengthHistCallback);

                  
% duration controls
durationToggle = uicontrol('Parent', fig, 'Style', 'checkbox', 'String', 'duration',...
                        'units','normalized', 'Position', [0.05 0.1 0.3 0.05], 'Value', inputToggle(11));

durationMin = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(11,1)),...
                     'units', 'normalized', 'Position', [0.4 0.1 0.15 0.05]);
                 
durationMax = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(11,2)),...
                     'units', 'normalized', 'Position', [0.6 0.1 0.15 0.05]);
                 
durationHist = uicontrol('Parent',fig, 'Style','pushbutton', 'String', 'Open',...
                      'units', 'normalized', 'Position', [0.8 0.1 0.2 0.05], 'Callback', @durationHistCallback);
                  
% confinement ratio controls
confinementToggle = uicontrol('Parent', fig, 'Style', 'checkbox', 'String', 'confinement ratio',...
                        'units','normalized', 'Position', [0.05 0.03 0.3 0.05], 'Value', inputToggle(12));

confinementMin = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(12,1)),...
                     'units', 'normalized', 'Position', [0.4 0.03 0.15 0.05]);
                 
confinementMax = uicontrol('Parent', fig, 'Style', 'edit', 'String', num2str(inputMinMax(12,2)),...
                     'units', 'normalized', 'Position', [0.6 0.03 0.15 0.05]);
                 
confinementHist = uicontrol('Parent',fig, 'Style','pushbutton', 'String', 'Open',...
                      'units', 'normalized', 'Position', [0.8 0.03 0.2 0.05], 'Callback', @confinementHistCallback);
                  
                  
%% Callback functions    
    function resetBtnCallback(source, event)
        % reset to the default input values
        speedToggle.Value = 0;
        accelToggle.Value = 0;
        xToggle.Value = 0;
        yToggle.Value = 0;
        zToggle.Value = 0;
        volumeToggle.Value = 0;
        MSDToggle.Value = 0;
        widthToggle.Value = 0;
        lengthToggle.Value = 0;
        durationToggle.Value = 0;
        confinementToggle.Value = 0;
        
        speedMin.String = inputMinMax(1,1);
        speedMax.String = inputMinMax(1,2);
        accelMin.String = inputMinMax(2,1);
        accelMax.String = inputMinMax(2,2);
        xMin.String = inputMinMax(3,1);
        xMax.String = inputMinMax(3,2);
        yMin.String = inputMinMax(4,1);
        yMax.String = inputMinMax(4,2);
        zMin.String = inputMinMax(5,1);
        zMax.String = inputMinMax(5,2);
        volumeMin.String = inputMinMax(6,1);
        volumeMax.String = inputMinMax(6,2);
        MSDMin.String = inputMinMax(7,1);
        MSDMax.String = inputMinMax(7,2);
        widthMin.String = inputMinMax(8,1);
        widthMax.String = inputMinMax(8,2);
        lengthMin.String = inputMinMax(9,1);
        lengthMax.String = inputMinMax(9,2);
        timeMin.String = inputMinMax(10,1);
        timeMax.String = inputMinMax(10,2);
        durationMin.String = inputMinMax(11,1);
        durationMax.String = inputMinMax(11,2);
        confinementMin.String = inputMinMax(12,1);
        confinementMax.String = inputMinMax(12,2);
    end
                 
%% exit button callback               
    function exitBtnCallback(source, event)
        toggleArray(1) = speedToggle.Value;
        toggleArray(2) = accelToggle.Value;
        toggleArray(3) = xToggle.Value;
        toggleArray(4) = yToggle.Value;
        toggleArray(5) = zToggle.Value;
        toggleArray(6) = volumeToggle.Value;
        toggleArray(7) = MSDToggle.Value;
        toggleArray(8) = widthToggle.Value;
        toggleArray(9) = lengthToggle.Value;
        toggleArray(10) = timeToggle.Value;
        toggleArray(11) = durationToggle.Value;
        toggleArray(12) = confinementToggle.Value;
        
        minMaxArray(1,1) = str2num_fast(speedMin.String);
        minMaxArray(1,2) = str2num_fast(speedMax.String);
        minMaxArray(2,1) = str2num_fast(accelMin.String);
        minMaxArray(2,2) = str2num_fast(accelMax.String);
        minMaxArray(3,1) = str2num_fast(xMin.String);
        minMaxArray(3,2) = str2num_fast(xMax.String);
        minMaxArray(4,1) = str2num_fast(yMin.String);
        minMaxArray(4,2) = str2num_fast(yMax.String);
        minMaxArray(5,1) = str2num_fast(zMin.String);
        minMaxArray(5,2) = str2num_fast(zMax.String);
        minMaxArray(6,1) = str2num_fast(volumeMin.String);
        minMaxArray(6,2) = str2num_fast(volumeMax.String);
        minMaxArray(7,1) = str2num_fast(MSDMin.String);
        minMaxArray(7,2) = str2num_fast(MSDMax.String);
        minMaxArray(8,1) = str2num_fast(widthMin.String);
        minMaxArray(8,2) = str2num_fast(widthMax.String);
        minMaxArray(9,1) = str2num_fast(lengthMin.String);
        minMaxArray(9,2) = str2num_fast(lengthMax.String);
        minMaxArray(10,1) = str2num_fast(timeMin.String);
        minMaxArray(10,2) = str2num_fast(timeMax.String);
        minMaxArray(11,1) = str2num_fast(durationMin.String);
        minMaxArray(11,2) = str2num_fast(durationMax.String);
        minMaxArray(12,1) = str2num_fast(confinementMin.String);
        minMaxArray(12,2) = str2num_fast(confinementMax.String);
   
        close(fig);
    end

%% speed callback
    function speedHistCallback(source, event)
        if ishandle(speedFig)
            if isSpeed == 0
                set(speedFig, 'Visible', 'on');
                source.String = 'Close';
                isSpeed = 1;
            else
                set(speedFig, 'Visible', 'off');
                source.String = 'Open';
                isSpeed = 0;
            end
        else
            speedFig = figure('NumberTitle','off','Name','Speed Histogram');
            set(speedFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
            tmp = [];
            iter = 1;
            for k=1:size(Tracks,2)
                tmp(iter) = mean(Tracks{1,k}(:,5));
                iter = iter+1;
            end
            hist(tmp);
            if isSpeed == 1
                isSpeed = 0;
                set(speedFig,'Visible','off');
                source.String = 'Open';
            else
                isSpeed = 1;
                source.String = 'Close';
            end
        end
    end

%% time callback
    function timeHistCallback(source, event)
        if ishandle(timeFig)
            if isTime == 0
                set(timeFig, 'Visible', 'on');
                source.String = 'Close';
                isTime = 1;
            else
                set(timeFig, 'Visible', 'off');
                source.String = 'Open';
                isTime = 0;
            end
        else
            timeFig = figure('NumberTitle','off','Name','Time Histogram');
            set(timeFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
            tmp = [];
            iter = 1;
            for k=1:size(Tracks,2)
                tmp(iter) = mean(Tracks{1,k}(:,6));
                iter = iter+1;
            end
            hist(tmp);
            if isTime == 1
                isTime = 0;
                set(timeFig,'Visible','off');
                source.String = 'Open';
            else
                isTime = 1;
                source.String = 'Close';
            end
        end
    end


%% confinement ratio callback
    function confinementHistCallback(source, event)
        if ishandle(confinementFig)
            if isConfinement == 0
                set(confinementFig, 'Visible', 'on');
                source.String = 'Close';
                isConfinement = 1;
            else
                set(confinementFig, 'Visible', 'off');
                source.String = 'Open';
                isConfinement = 0;
            end
        else
            confinementFig = figure('NumberTitle','off','Name','Confinement Ratio Histogram');
            set(confinementFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
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
            hist(confinementRatio);
            if isConfinement == 1
                isConfinement = 0;
                set(confinementFig,'Visible','off');
                source.String = 'Open';
            else
                isConfinement = 1;
                source.String = 'Close';
            end
        end
    end

%% duration callback
    function durationHistCallback(source, event)
        if ishandle(durationFig)
            if isDuration == 0
                set(durationFig, 'Visible', 'on');
                source.String = 'Close';
                isDuration = 1;
            else
                set(durationFig, 'Visible', 'off');
                source.String = 'Open';
                isDuration = 0;
            end
        else
            durationFig = figure('NumberTitle','off','Name','Duration Histogram');
            set(durationFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
            tmp = [];
            iter = 1;
            for k=1:size(Tracks,2)
                tmp(iter) = size(Tracks{k},1);
                iter = iter+1;
            end
            hist(tmp);
            if isDuration == 1
                isDuration = 0;
                set(durationFig,'Visible','off');
                source.String = 'Open';
            else
                isDuration = 1;
                source.String = 'Close';
            end
        end
    end

%% accel callback
    function accelHistCallback(source, event)
        if ishandle(accelFig)
            if isAccel == 0
                set(accelFig, 'Visible', 'on');
                source.String = 'Close';
                isAccel = 1;
            else
                set(accelFig, 'Visible', 'off');
                source.String = 'Open';
                isAccel = 0;
            end
        else
            % create the acceleration figure
            accelFig = figure('NumberTitle','off','Name','Accel Histogram');
            set(accelFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
            tmp = [];
            iter = 1;
            for a=1:size(Tracks,2)
                for b=1:size(Tracks{1,a},1)
                    tmp(iter) = Tracks{1,a}(b,8);
                    iter = iter+1;
                end
            end
            hist(tmp);
            if isAccel == 1
                isAccel = 0;
                set(accelFig,'Visible','off');
                source.String = 'Open';
            else
                isAccel = 1;
                source.String = 'Close';
            end
        end
    end

%% x callback
    function xHistCallback(source, event)
        if ishandle(xFig)
            if isX == 0
                set(xFig, 'Visible', 'on');
                source.String = 'Close';
                isX = 1;
            else
                set(xFig, 'Visible', 'off');
                source.String = 'Open';
                isX = 0;
            end
        else
            % create the x axis histogram figure
            xFig = figure('NumberTitle','off','Name','X axis Histogram');
            set(xFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
            tmp = [];
            iter = 1;
            for a=1:size(Tracks,2)
                for b=1:size(Tracks{1,a},1)
                    tmp(iter) = Tracks{1,a}(b,1);
                    iter = iter+1;
                end
            end
            hist(tmp);
            if isX == 1
                isX = 0;
                set(xFig,'Visible','off');
                source.String = 'Open';
            else
                isX = 1;
                source.String = 'Close';
            end
        end
    end

%% y callback
    function yHistCallback(source, event)
        if ishandle(yFig)
            if isY == 0
                set(yFig, 'Visible', 'on');
                source.String = 'Close';
                isY = 1;
            else
                set(yFig, 'Visible', 'off');
                source.String = 'Open';
                isY = 0;
            end
        else
            % create the y axis histogram figure
            yFig = figure('NumberTitle','off','Name','Y axis Histogram');
            set(yFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
            tmp = [];
            iter = 1;
            for a=1:size(Tracks,2)
                for b=1:size(Tracks{1,a},1)
                    tmp(iter) = Tracks{1,a}(b,2);
                    iter = iter+1;
                end
            end
            hist(tmp);
            if isY == 1
                isY = 0;
                set(yFig,'Visible','off');
                source.String = 'Open';
            else
                isY = 1;
                source.String = 'Close';
            end
        end
    end

%% z callback
    function zHistCallback(source, event)
        if ishandle(zFig)
        if isZ == 0
            set(zFig, 'Visible', 'on');
            source.String = 'Close';
            isZ = 1;
        else
            set(zFig, 'Visible', 'off');
            source.String = 'Open';
            isZ = 0;
        end
        else
            % create the z axis histogram figure
            zFig = figure('NumberTitle','off','Name','Z axis Histogram');
            set(zFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
            tmp = [];
            iter = 1;
            for a=1:size(Tracks,2)
                for b=1:size(Tracks{1,a},1)
                    tmp(iter) = Tracks{1,a}(b,3);
                    iter = iter+1;
                end
            end
            hist(tmp);
            if isZ == 1
                isZ = 0;
                set(zFig,'Visible','off');
                source.String = 'Open';
            else
                isZ = 1;
                source.String = 'Close';
            end
        end
    end

%% volume callback
    function volumeHistCallback(source, event)
        if ishandle(volFig)
            if isVol == 0
                set(volFig, 'Visible', 'on');
                source.String = 'Close';
                isVol = 1;
            else
                set(volFig, 'Visible', 'off');
                source.String = 'Open';
                isVol = 0;
            end
        else
            % create the volume histogram figure
            volFig = figure('NumberTitle','off','Name','Volume Histogram');
            set(volFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
            tmp = [];
            iter = 1;
            for a=1:size(Tracks,2)
                tmp(iter) = mean(Tracks{1,a}(:,4));
                iter = iter+1;
            end
            hist(tmp);
            if isVol == 1
                isVol = 0;
                set(volFig,'Visible','off');
                source.String = 'Open';
            else
                isVol = 1;
                source.String = 'Close';
            end
        end
    end

%% msd callback
    function MSDHistCallback(source, event)
        if ishandle(MSDFig)
        if isMSD == 0
            set(MSDFig, 'Visible', 'on');
            source.String = 'Close';
            isMSD = 1;
        else
            set(MSDFig, 'Visible', 'off');
            source.String = 'Open';
            isMSD = 0;
        end
        else
            % create the MSD histogram figure
            MSDFig = figure('NumberTitle','off','Name','MSD Histogram');
            set(MSDFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
            hist(MSDArray);
            if isMSD == 1
                isMSD = 0;
                set(MSDFig,'Visible','off');
                source.String = 'Open';
            else
                isMSD = 1;
                source.String = 'Close';
            end
        end
    end

%% width callback
    function widthHistCallback(source, event)
        if size(Tracks{1,1},2) > 8
            if ishandle(widthFig)
            if isWidth == 0
                set(widthFig, 'Visible', 'on');
                source.String = 'Close';
                isWidth = 1;
            else
                set(widthFig, 'Visible', 'off');
                source.String = 'Open';
                isWidth = 0;
            end
            else
                widthFig = figure('NumberTitle','off','Name','Width Histogram');
                set(widthFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
                tmp = [];
                iter = 1;
                for a=1:size(Tracks,2)
                    tmp(iter) = mean(Tracks{1,a}(:,10));
                    iter = iter+1;
                end
                hist(tmp);
                if isWidth == 1
                    isWidth = 0;
                    set(widthFig,'Visible','off');
                    source.String = 'Open';
                else
                    isWidth = 1;
                    source.String = 'Close';
                end
            end
        end
    end

%% length callback
    function lengthHistCallback(source, event)
        if size(Tracks{1,1},2) > 8
            if ishandle(lengthFig)
            if isLength == 0
                set(lengthFig, 'Visible', 'on');
                source.String = 'Close';
                isLength = 1;
            else
                set(lengthFig, 'Visible', 'off');
                source.String = 'Open';
                isLength = 0;
            end
            else
                lengthFig = figure('NumberTitle','off','Name','Length Histogram');
                set(lengthFig, 'units','normalized','Position', [0.15, 0.65, 0.2, 0.3], 'Toolbar', 'none');
                tmp = [];
                iter = 1;
                for a=1:size(Tracks,2)
                    tmp(iter) = mean(Tracks{1,a}(:,9));
                    iter = iter+1;
                end
                hist(tmp);
                if isLength == 1
                    isLength = 0;
                    set(lengthFig,'Visible','off');
                    source.String = 'Open';
                else
                    isLength = 1;
                    source.String = 'Close';
                end
            end
        end
    end

waitfor(fig) % wait for the ui to close
end 

