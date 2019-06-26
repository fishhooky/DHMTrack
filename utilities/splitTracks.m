function [ splitNumber ] = splitTracks( Track)
% Gives UI for selecting a point to split a track at a specified point
%   Input:
%           Track - the track that is in question for the split
%
%
splitNumber = 0;

if size(Track,1) < 2
    disp('track length too short for split');
    return
end

marker1 = scatter3(Track(1,1),Track(1,2),Track(1,3),30,'r');
marker2 = scatter3(Track(2,1),Track(2,2),Track(2,3),30,'r');
line = plot3([Track(1,1); Track(2,1)], [Track(1,2); Track(2,2)],[Track(1,3); Track(2,3)], 'r');

% create the figure of instantaneous speed
speedFig = figure('NumberTitle','off', 'Name','Instantaneous speed');
set(speedFig, 'units','normalized','Position', [0.15, 0.5, 0.2, 0.1], 'MenuBar', 'none', 'ToolBar', 'none');
hold on
x = 1:size(Track,1);
plot(x, Track(:,5));
markerSpeed1 = scatter(1,Track(1,5),'r');
markerSpeed2 = scatter(2,Track(2,5),'r');
lineSpeed = plot([1 2], [Track(1,5) Track(2,5)], 'r');
hold off

% create the ui figure
fig = figure('NumberTitle','off','Name','Split Track Options');
set(fig, 'units','normalized','Position', [0.15, 0.35, 0.2, 0.1], 'MenuBar', 'none', 'ToolBar', 'none');


sliderTxt = uicontrol('Parent',fig, 'style', 'text','string','Select split point',...
    'units','normalized', 'position',[0.65 0.075 0.35 0.25]);

splitBtn = uicontrol('Parent',fig, 'style','pushbutton', 'String','Split',...
    'units','normalized', 'position', [0.1 0.5 0.35 0.3], 'Callback', @splitCallback);

cancelBtn = uicontrol('Parent',fig, 'style','pushbutton', 'String','Cancel',...
    'units','normalized', 'position', [0.55 0.5 0.35 0.3], 'Callback', @cancelCallback);


% slider ui control
slider = uicontrol('Parent',fig,'Style','slider','units','normalized','Position',[0.1 0.1 0.55 0.25],...
    'value',1, 'min',1, 'max',size(Track,1)-1, 'Callback', @sliderCallback, 'SliderStep', [1/(size(Track,1)-2) 1]);

% continuously poll the slider
slider.addlistener('Value','PostSet',...
    @(src,data) data.AffectedObject.Callback(data.AffectedObject,struct('Source',data.AffectedObject,'EventName','Action')));


    function sliderCallback(source, event)
        % plot an marker on the selected object and the next object to indicate where the split will occur
        num = floor(source.Value);
        
        set(marker1, 'XData',Track(num,1), 'YData',Track(num,2), 'ZData',Track(num,3));
        set(marker2, 'XData',Track(num+1,1), 'YData',Track(num+1,2), 'ZData',Track(num+1,3));
        
        set(line, 'XData',[Track(num,1); Track(num+1,1)], 'YData',[Track(num,2); Track(num+1,2)], 'ZData',[Track(num,3); Track(num+1,3)]);
    
        set(markerSpeed1, 'XData', num, 'YData',Track(num,5));
        set(markerSpeed2, 'XData', num+1, 'YData', Track(num+1,5));
        
        set(lineSpeed, 'XData',[num num+1], 'YData',[Track(num,5) Track(num+1,5)]);

    end

    function splitCallback(source, event)
        splitNumber = floor(slider.Value); % set the split number and close
        close(fig);
        close(speedFig);
    end

    function cancelCallback(source, event)
        close(fig);
        close(speedFig);
    end

waitfor(fig);
delete(marker1);
delete(marker2);
delete(line);
end

