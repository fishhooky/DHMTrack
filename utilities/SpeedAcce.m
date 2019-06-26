function [y,z]=SpeedAcce(Tracks,varargin)
% Input tracks to calculate speed and acceleration, varargin = max accleration to sift based upon accleration
% Assumes (X,Y,Z,V,S,t) track layout
% Speed output in column 5
% Accleration output in column 8
% z is output of all acclerations
maxA = 0;
if size(varargin,1)>0
    maxA=varargin{1};
end
for A = 1:size(Tracks,1)
    for B = 1:size(Tracks,2)
        Track=Tracks{A,B};
        if size(Track,1)>2 && isnumeric(Track)==1
            clear log
            Track(1,5)=0;
            for a=2:size(Track,1)
                Track(a,5)=((Track(a,1)-Track(a-1,1))^2+(Track(a,2)-Track(a-1,2))^2+(Track(a,3)-Track(a-1,3))^2)^0.5/(Track(a,6)-Track(a-1,6));
                if a>2
                    Track(a,8)=(Track(a,5)-Track(a-1,5))/(Track(a,6)-Track(a-1,6));
                end
                if maxA > 0 && abs(Track(a,8))>maxA
                    
                    Track(a,:)=Track(a-1,:);
                    if exist('log','var')==0
                        log(1,1)=a;
                    else
                        log(end+1,1)=a;
                    end
                    
                end
            end
            if exist('log','var')==1
                for a=1:size(log,1)
                    if log(a,1)==size(Track,1)
                        Track(end,:)=[];
                    else
                        Track(log(a,1):end-1,:)= Track(log(a,1)+1:end,:);
                        Track(end,:)=[];
                        log=log-1;
                    end
                end
            end
            if exist('z','var') == 0 %Output list of all acclerations
                z=Track(3:end,8);
            else
                z(end+1:end+size(Track,1)-2)=Track(3:end,8);
            end
            Tracks{A,B}=Track;
        elseif size(Track,1)>0
            Tracks{A,B}=Track;
        end
    end
end
y=Tracks;