function [newtimevec,outputz,outputy,outputx,outputh]=cutrmsdata(...
    oldtimevec,inputz,inputy,inputx,inputh,starttime,endtime,timezone,rmstype)
% 
% Function to crop the inputted data, with each point corresponding to
% a particular time, to a specified time interval.
% 
% INPUTS
% oldtimevec : The vector of datetimes, with each datetime corresponding
%              to an input data point
% inputz : A matrix listing the RMS displacement/velocity/acceleration 
%          in the Z (vertical) component.
% inputy : A matrix listing the RMS displacement/velocity/acceleration 
%          in the Y (North-South) component.
% inputx : A matrix listing the RMS displacement/velocity/acceleration 
%          in the X (East-West) component.
% inputh : A matrix listing the RMS displacement/velocity/acceleration 
%          in the H (horizontal) component. Leave empty if we only want 
%          X and Y.
% starttime : From what time do we start our time series? Input a 
%             number from 0-23 signifying an hour if plotting 'qrt' 
%             data (rmstype=2). Otherwise enter a datetime vector, with
%             the year corresponding to the most recent year entered.
%             Input with the time zone! 
% endtime : At what time do we end our time series? Input a number from
%           0-23 signifying an hour if plotting 'qrt' data (rmstype=2). 
%           Otherwise enter a datetime vector, with the year corresponding
%           to the most recent year entered.
%           Input with the time zone! 
% timezone : The time zone we are considering
%            Default: 'UTC'
% rmstype : How were the RMS values averaged?
%           0 : 'daily' : guyotrmsseisday.m, 
%           1 : 'hourly' : guyotrmsseishr.m, 
%           2 : 'qrt' : guyotrmsseisqrt.m, 
%
% OUTPUTS
% newtimevec : The cropped datetime vector, from starttime to endtime
% outputz : A matrix listing the RMS disp/vel/acc in the Z component, 
%           cropped so that each point corresponds to newtimevec.
% outputy : A matrix listing the RMS disp/vel/acc in the Y component, 
%           cropped so that each point corresponds to newtimevec.
% outputx : A matrix listing the RMS disp/vel/acc in the X component, 
%           cropped so that each point corresponds to newtimevec.
% outputh : A matrix listing the RMS disp/vel/acc in the H component, 
%           cropped so that each point corresponds to newtimevec. An empty
%           vector will be displayed if inputh is not entered.
%
% NOTE: This function cuts the time vector according to start and end time
%
% Reference
% Uses defval.m, in csdms-contrib/slepian_alpha 
%
% Last Modified by Yuri Tamama, 10/10/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
defval('timezone','UTC')

% Iterate through all values of the time vector and make new matrices
rmsx17=[];
rmsy17=[];
rmsz17=[];
rmsh17=[];
rmsx18=[];
rmsy18=[];
rmsz18=[];
rmsh18=[];
rmsx19=[];
rmsy19=[];
rmsz19=[];
rmsh19=[];
rmsx20=[];
rmsy20=[];
rmsz20=[];
rmsh20=[];
newtimevec=[];
for i=1:length(oldtimevec)
  temptime=oldtimevec(i);
  temptime.TimeZone=timezone;
  % Variable to check whether a particular time is within the range of
  % times that we want
  timeadded=0;
  if rmstype==2
    if (temptime.Hour>=starttime) && (temptime.Hour<=endtime)
      newtimevec=[newtimevec; temptime];
      timeadded=1;
    end
  else
    if (temptime>=starttime) && (temptime<=endtime)
      newtimevec=[newtimevec; temptime];
      timeadded=1; 
    end
  end
  if timeadded==1
    rmsx17=[rmsx17; inputx(i,1)];
    rmsy17=[rmsy17; inputy(i,1)];
    rmsz17=[rmsz17; inputz(i,1)];
    rmsx18=[rmsx18; inputx(i,2)];
    rmsy18=[rmsy18; inputy(i,2)];
    rmsz18=[rmsz18; inputz(i,2)];
    rmsx19=[rmsx19; inputx(i,3)];
    rmsy19=[rmsy19; inputy(i,3)];
    rmsz19=[rmsz19; inputz(i,3)];
    rmsx20=[rmsx20; inputx(i,4)];
    rmsy20=[rmsy20; inputy(i,4)];
    rmsz20=[rmsz20; inputz(i,4)];
    if ~isempty(inputh)
      rmsh17=[rmsh17; inputh(i,1)];
      rmsh18=[rmsh18; inputh(i,2)];
      rmsh19=[rmsh19; inputh(i,3)];
      rmsh20=[rmsh20; inputh(i,4)];
    end  
  end
end
outputx=zeros(length(newtimevec),4);
outputx(:,1)=rmsx17;
outputx(:,2)=rmsx18;
outputx(:,3)=rmsx19;
outputx(:,4)=rmsx20;
%
outputy=zeros(length(newtimevec),4);
outputy(:,1)=rmsy17;
outputy(:,2)=rmsy18;
outputy(:,3)=rmsy19;
outputy(:,4)=rmsy20;
%
outputz=zeros(length(newtimevec),4);
outputz(:,1)=rmsz17;
outputz(:,2)=rmsz18;
outputz(:,3)=rmsz19;
outputz(:,4)=rmsz20;
%
if ~isempty(inputh)
  outputh=zeros(length(newtimevec),4);
  outputh(:,1)=rmsh17;
  outputh(:,2)=rmsh18;
  outputh(:,3)=rmsh19;
  outputh(:,4)=rmsh20;
else
  outputh=[];
end  



