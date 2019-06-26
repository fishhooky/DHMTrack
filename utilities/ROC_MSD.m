function [MSD,ROC,MSDGraph,ROCGraph]=ROC_MSD(Track,dimensions)
% function to calculate mean squared displacement and radius of curvature
% Input track
% Dimensions is whether track is 2D or 3D
% MSD Output is is MSD(1), MSD(2) is meaningless
% ROC(1) = ROC at tau = 1
% ROC(2) = Standard deviation of ROC(1)
% ROC(3) = maximum tau or tau = 10x interval
% ROC(4) = ROC at tau = ROC(2)
% ROC(5) = Standard deviation of ROC(4)
% ROC(6) = tau at which local max/min occurs
% ROC(7) = ROC at local max/min

%% Setup
clear ROC MSD
X=Track(:,1);
Y=Track(:,2);

if dimensions == 3
    Z= Track(:,3);
    t= Track(:,6);
else
    Z(size(Track,1),1)=0;
    t= Track(:,6); % fixed bug here cause time column is still 6th for 2d
end

dT = t(2)-t(1);
for a=3:size(t,1)
    dTtest = t(a)-t(a-1);
    if dTtest<dT
        minDt=dTtest;
    end
end
dT=round(dT*1000);
a1=t(end)*1000/dT;
warning('off','all')
%% Calculate MSD
for a =1:a1-1 %Change tau
    for b=1:size(Track,1) %Change t
        for c=1:size(Track,1)-b
            if round((t(b+c)-t(b))*1000)==dT*a
                SDis(b)=((X(b)-X(b+c))^2+(Y(b)-Y(b+c))^2+(Z(b)-Z(b+c))^2);
            end
        end
    end
    if exist('SDis','var')==1
        SDis(SDis==0)=[];
        XY(a,1)=log(a*dT);
        XY(a,2)=log(mean(SDis));
        clear SDis
    end
end
if exist('XY', 'var')
    MSDGraph=XY;
    mdl = fitlm(XY(:,1),XY(:,2));
    MSD(1,1)=mdl.Coefficients{2,1};
    MSD(1,2)=mdl.Rsquared.Ordinary(1,1);
end

%% Calculate ROC
% not using the ROC in the inspection step kept commented out though for potential future use 
ROC = 0;
ROCGraph = [];
% clear r
% C2=1;
% for a =1:floor((a1-1)/2) %vary tau
%     C1=0;
%     for b=1:size(Track,1) %Vary t
%         %% find relevant timepoints
%         b1=find(round(t*1000)==t(b)*1000+a*dT);
%         b2=find(round(t*1000)==t(b)*1000+2*a*dT);
%         if size(b2,1)==1 && size(b1,1)==1
%             C1=C1+1;
%             %% Find 3-point coordinates
%             x(1)=X(b);
%             x(2)=X(b1);
%             x(3)=X(b2);
%             y(1)=Y(b);
%             y(2)=Y(b1);
%             y(3)=Y(b2);
%             z(1)=Z(b);
%             z(2)=Z(b1);
%             z(3)=Z(b2);
%             
%             %% Find plane 1 details
%             %Find midpoint between points 1 and 2
%             x(4)=mean(x(1:2));
%             y(4)=mean(y(1:2));
%             z(4)=mean(z(1:2));
%             
%             %Find normal vector of plane
%             V(1,1)=x(2)-x(1);
%             V(1,2)=y(2)-y(1);
%             V(1,3)=z(2)-z(1);
%             
%             %plane coeffient
%             V(1,4)=x(4)*V(1,1)+y(4)*V(1,2)+z(4)*V(1,3);
%             
%             %% Find plane 2 details
%             %Find midpoint between points 2 and 3
%             x(4)=mean(x(2:3));
%             y(4)=mean(y(2:3));
%             z(4)=mean(z(2:3));
%             
%             %Find normal vector of plane
%             V(2,1)=x(3)-x(2);
%             V(2,2)=y(3)-y(2);
%             V(2,3)=z(3)-z(2);
%             
%             %plane coeffient
%             V(2,4)=x(4)*V(2,1)+y(4)*V(2,2)+z(4)*V(2,3);
%             
%             %% Find plane 3 details
%             %Find midpoint between points 1 and 3
%             x(4)=(x(3)+x(1))/2;
%             y(4)=(y(3)+y(1))/2;
%             z(4)=(z(3)+z(1))/2;
%             
%             %Find normal vector of plane
%             V(3,1)=x(3)-x(1);
%             V(3,2)=y(3)-y(1);
%             V(3,3)=z(3)-z(1);
%             
%             %plane coeffient
%             V(3,4)=x(4)*V(3,1)+y(4)*V(3,2)+z(4)*V(3,3);
%             
%             %% modifying matrix
%             V(1,:)=V(1,:)/V(1,1);
%             V(2,:)=V(2,:)/V(2,1);
%             V(3,:)=V(3,:)/V(3,1);
%             V(3,:)=V(3,:)-V(1,:);
%             V(2,:)=V(2,:)-V(1,:);
%             V(2,:)=V(2,:)/V(2,2);
%             V(3,:)=V(3,:)/V(3,2);
%             V(3,:)=V(3,:)-V(2,:);
%             %% Find intersection point
%             if dimensions == 2
%                 V(3,5)=0;
%             else                
%                 V(3,5)=-V(3,4)/V(3,3);
%             end
%             V(2,5)=V(2,4)-V(2,3)*V(3,5);
%             V(1,5)=V(1,4)-V(1,3)*V(3,5)-V(1,2)*V(2,5);
%             %% find radius of sphere
%             d(1:3)=(x(1:3)-V(1,5)).^2+(y(1:3)-V(2,5)).^2+(z(1:3)-V(3,5)).^2;
%             r(b,C2)=sqrt(d(1));
%             if r(b,C2) == Inf
%                 r(b,C2)=NaN;
%             end
%         end
%     end
%     if C1>0
%         if size(r,1)-sum(isnan(r(:,C2)))-sum(r(:,C2)==0)>0
%             r(size(Track,1)-1,C2)=(a)*dT/1000;
%             C2=C2+1;
%         else
%             r(:,C2)=[];
%         end
%     end
%     
% end
% if exist('r','var')==1
%     r(r==0)=NaN;
% end
% if exist('r','var')==1 && size(r,2)>0
%     if  isnan(r(size(Track,1)-1,1))==1
%         r(size(Track,1)-1,1)=0;
%     end
%     r(end+1,:)=nanmean(r(1:size(Track,1)-2,:));
%     r(end+1,:)=nanstd(r(1:size(Track,1)-2,:));
%     ROCGraph = r(end-2:end,:);
%     QUAD=polyfit(r(end-2,:),r(end-1,:),2);
%     ROC(1)=r(end-1,1);ROC(2)=r(end,1);
%     if size(r,2)>9
%         ROC(3)=r(end-2,10);ROC(4)=r(end-1,10);
%         ROC(5)=r(end,10);
%     else
%         ROC(3)=r(end-2,end);ROC(4)=r(end-1,end);
%         ROC(5)=r(end,end);
%     end
%     ROC(6)=-QUAD(2)/2/QUAD(1);
%     ROC(7)=QUAD(1)*ROC(6)^2+QUAD(2)*ROC(6)+QUAD(3);
% else
%     ROC=[];
%     ROCGraph=[];
%     MSD=[];
%     MSDGraph=[];
% end

%warning('on','all')
end