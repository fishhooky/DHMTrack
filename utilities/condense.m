function y=condense(Tracks)
% Function to remove blank arrays within cell array
% Will also remove 0'd rows within a track
% Requires input of cell array

%% Remove blank tracks
for b=1:size(Tracks,1)
    A = 0;
    for a=1:size(Tracks,2)
        if size(Tracks{b,a},1)>0
            A=A+1;
            y{b,A}=Tracks{b,a};
        end
    end
end

%% Remove 0'd rows
for a=1:size(y,1)
    for b=1:size(y,2)
        C1=0;
        for c=1:size(y{a,b},1)
            if sum(y{a,b}(c,:)==0) < size(y{a,b},2)
                C1=C1+1;
                y1{a,b}(C1,:)=y{a,b}(c,:);
            end
        end
    end
end

y = y1;