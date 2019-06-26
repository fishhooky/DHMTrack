function data = datasift(frames,percentile,varargin)
% Requires input of DHM data containing frames of objects, varargin is maximum objects
% Sift based upon volume
% Counts number of objects identified per frame
% Sets limit as the percentile of the number of objects across all frames
% Reduces objects of each frame to limit
% Limit determined by percentile, lower value will reduce the number
% Varargin will over-ride found limit if used
% Outputs limited number of objects based upon volume

% Modified Fall 2018 Andrew Woodward

%% IDENTIFY LIMIT OF OBJECTS
X(1:size(frames,2))=0;
for a = 1:size(frames,2)
    uniqueObjects = unique(frames{a}(:,4)); % remove the repeating volumes that are small
    X(a)=size(uniqueObjects,1); %Containing dataset of #objects in each frame
end
X(X==0)=nan;
objectLimit = ceil(prctile(X,percentile,2)); %Select #objects lower 20 percentile as limit
if size(varargin,1)>0 && objectLimit>varargin{1} 
    objectLimit=varargin{1};
end
        
%% APPLY LIMIT
for a = 1:size(frames,2)
    if size(frames{a},1) > objectLimit 
        vol = sort(frames{a}(:,4)); % sort object volumes
        volLimit = vol(end-objectLimit+1,1);
        C1 = 0; % Counter
        for b=1:size(vol,1)
            if frames{a}(b,4) >= volLimit 
                C1 = C1 + 1;
                data{a}(C1,1:4)=frames{a}(b,1:4);
            end
        end
    else
        data{a}=frames{a}; %Copies frames already below limit Vol1
    end
end