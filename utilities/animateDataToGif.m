%% Plotting bacteria raw data as an animation in gif form
% Andrew Woodward
% Sept 2018
%
% Used in conjunction with the DHMTracking.m script to obtain the raw
% holographic data and uses Chad Greene's gif.m script. Will create a gif
% of the input DHM data overlayed onto the detected tracks. Also rotates
% the figure to give 3d perspective.

%% Creating the figure and preparing the gif file
figure
gif('myGif.gif', 'DelayTime', 0.15)

%% Looping through the data and updating the figure
for i=1:2:size(data,2)
    for j=1:size(Tracks,2)
        plot3(Tracks{1,j}(:,1),Tracks{1,j}(:,2),Tracks{1,j}(:,3))
        xlim([0 200])
        ylim([0 200])
        zlim([0 110])
        hold on
    end
    scatter3(data{1,i}(:,2),data{1,i}(:,1),data{1,i}(:,3),data{1,i}(:,4)*100)
    xlim([0 200])
    ylim([0 200])
    zlim([0 110])
    view(i,25) % comment out to turn off rotation
    gif % needs to be called to update the next frame of the gif
    hold off
end

web('myGif.gif') %used to view the gif