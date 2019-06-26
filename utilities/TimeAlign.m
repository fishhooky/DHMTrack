
function y=TimeAlign(T1,T2,TimeColumn,varargin)
% Aligns datasets based upon order of column defined as TimeColumn
% requires dataset T1 and T2
% Outputs single aligned dataset
% If there is overlap, preference is given to track that happened later
% Change varargin to 1 if wish to preference first track
TC = TimeColumn;
%% Identify which track happened first
if T1(1,TC)>T2(1,TC) %Switch T1 and T2 if T1 after T2
    T3=T1; %T3 is temporary track
    T1=T2;
    T2=T3;
end

%% Loop to find position of tracks within each other
% What to do if T1 and T2 do not overlap
q2 = 0;
q4=0; %Set to 1 to preference first track
if size(varargin,1)>0
    q4=1;
end
while q2 == 0 % Loop for multiple overlaps, switch to 1 defines end
    if T2(1,TC)>T1(end,TC) %Check to see if there is  no overlap
        T1(end+1:end+size(T2,1),:)=T2;
        q2 = 1;
    else %What to do if T1 and T2 do overlap
        q1=1; %Counter to screen through T1 values
        q3 = 0; %Switch to end search once overlap found
        while q1<size(T1,1) && q3 == 0 && T1(q1,TC)<=T2(1,TC)
            q5=0; %Secondary switch for determining track preference
            
            if T2(1,TC)<=T1(q1+1,TC) && q4 == 0
                q5=1;
            elseif T2(1,TC)<T1(q1+1,TC)
                q5=1;
            end
            
            if T2(1,TC)>T1(q1,TC)&&q5==1 %Determine point of overlap
                q3=1;
                if T2(1,TC)==T1(q1+1,TC)
                    T3 = T1(q1+2:end,:);
                else
                    T3 = T1(q1+1:end,:);
                end
                T1(q1+1:end,:)=[];
                T1(end+1:end+size(T2,1),:)=T2;
                clear T2
                T2 = T3;
                if q4 == 0
                    q4=1;
                else
                    q4=0;
                end
            else
                q1=q1+1; %If overlap not found keep searching
            end
        end
        if q3 == 0 %delete first time point of T2 if no overlap found
            T2(1:end-1,:)=T2(2:end,:);
            T2(end,:)=[];
        end
    end
    if size(T2,1)==0 %end track combine if final point shared
        q2=1;
    end
end
y=T1;
