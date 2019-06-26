function [ output ] = categorizeTrack( track, categories, minDisplace )
%Categorizes the given track into one of the categories
%   track is a Nx8 array
% Fall 2018 - Andrew Woodward

finalDisplacement = sqrt( (track(1,1) - track(size(track,1),1))^2 + ...
                          (track(1,2) - track(size(track,1),2))^2 + ...
                          (track(1,3) - track(size(track,1),3))^2 );

midDisplacement = sqrt( (track(1,1) - track(round(size(track,1)/2),1))^2 + ...
                        (track(1,2) - track(round(size(track,1)/2),2))^2 + ...
                        (track(1,3) - track(round(size(track,1)/2),3))^2 );
                    
if finalDisplacement < minDisplace && midDisplacement < minDisplace/2
    output = 'stationary'; 
else
    output = 'swimming';
end
       
end

