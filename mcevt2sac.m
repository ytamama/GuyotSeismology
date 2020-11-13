function corrpieces=mcevt2sac(rowdata,measval,frequency,timeinfo,savedir,...
    makeplot,saveplot,plotdir,coord,addphases,rmoutlier)
%
% Function that takes in a row of IRIS catalog data, generated by 
% irisevent.m using IRIS's fdsnws-event web service, and finds the 
% .miniseed files that may contain this event, recorded by a 
% Nanometrics Meridian PH-120 seismometer, and finds the .miniseed files 
% that may contain the event.
% Then, the function converts that .miniseed file into a SAC file and 
% trims the SAC file into an interval ranging from the approximate 
% origin time to a specified end.
% 
% INPUTS
% rowdata : One row of IRIS catalog data
%           Columns (left to right): eventID, origin time of event (string),
%           event latitude, event longitude, depth, event magnitude,
%           geoid distance from station to event (degrees), Great Circle
%           distance from station to event (degrees), and the predicted 
%           travel time of one seismic phase to Guyot Hall (seconds)
% measval : What do we want for the signal?
%           0 for displacement in nm (default if left empty)
%           1 for velocity in nm/s 
%           2 for acceleration in nm/(s^2)
% frequency : The frequencies to which the data will be filtered during
%             instrument correction
%             Default: [0.01 0.02 10.00 20.00] Hz
% timeinfo : How are we defining our plotting interval? Enter these
%            parameters as a cell array, with the following format:
%            {timeorsw; intend; plotsw} where:
% 
%            timeorsw : Whether we are defining our plotting time interval
%                       by a time span or surface wave velocities
%                       0 - Plot everything in the SAC files inputted
%                       1 - Define a time span (s)
%                       2 - Define surface wave velocities (km/s)
%            intend : The time at which to cut our time interval, in
%                     seconds, if we set timeorsw=1. 
%                    
%                     OR: A two-element vector with the upper and lower 
%                     thresholds, in that order, of the surface wave
%                     velocities if we set timeorsw=2
%            plotsw : If plotting, do we want to label the surface wave
%                     speeds?
%                     0 - No
%                     1 - Yes
% 
%            Enter a 3 element cell array, but leave any of these empty
%            (or set the first element equal to 0) if we don't want to
%            define a time span
% savedir : Where do we want to save our SAC files? Enter a directory!
% makeplot : Make a plot of the selected interval?
%            0 for no (default if left empty)
%            1 for yes
% saveplot : Do we want to save our plot?
%            0 - No (default)
%            1 - Yes 
% plotdir : Where do we want to save our plot? Enter a directory!
% coord : Do we want our SAC files in the XYZ or RTZ coordinate system, or
%         both?
%         0 - XYZ (default)
%         1 - RTZ
%         2 - Both, return in the order: Z, Y, X, T, R
% addphases : Do we want to add seismic phases and their predicted
%             travel times to our plot?
%             0 - No (default)
%             1 - Yes 
% rmoutlier :  If plotting our values, how should we define and remove our
%              outliers?
%
%              0 - Use a percentage limit. For every SAC file, we remove
%                  signals that are at or above this percentile. 
%                  Enter a two number vector, with 0 as the first element
%                  and the percentile limit as the second.
%              1 - Remove outliers that are more than a certain number of
%                  median standard deviations (MAD) away from the median. 
%                  Enter a 2 number vector, with 1 as the first element 
%                  and the # of MADs as the second, like this:
%                  [1 3] - remove signals at least 3 MADs away from the
%                          median for every SAC file
% 
%              Input an empty array if we don't want to remove any signals
%              (default)
%
% OUTPUT(S)
% corrpieces : The instrument corrected SAC pieces, containing data 
%              for the chosen interval surrounding the event's approximate 
%              arrival time. Returns a cell array containing empty strings
%              if data are missing from the requested interval.
%              To be consistent with other programs using output from 
%              this program, the SAC files will be returned in the order:
%              {'Z';'Y';'X'} or {'Z';'T';'R'} or {'Z';'Y';'X';'T';'R'}
%              where R is radial and T is transverse
%
% Also returns a plot of those SAC pieces, if requested
%
% References:
% Uses the fdsnws-event, distance-azimuth web services of IRIS
% (see irisevent.m, irisazimuth.m)
% Learned how to access SAC commands from MATLAB from mcms2mat.m,
% in csdms-contrib/slepian_oscar
% Uses dat2jul.m, in csdms-contrib/slepian_oscar
% Uses defval.m in csdms-contrib/slepian_alpha 
% Consulted the SAC manual, from http://ds.iris.edu/files/sac-manual/
% Guyot Hall latitude and longitude from guyotphysics.m in 
% csdms-contrib/slepian_zero
%
% For more on SAC, see Helffrich et al., (2013), The Seismic Analysis 
% Code: a Primer and User's Guide
% 
% Last Modified by Yuri Tamama, 10/27/2020
% 
% See mstime2sac.m, makesac.m, plotsacdata.m, irisevent.m, irisazimuth.m, 
% rotsac.m 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values and variables
defval('measval',0);
defval('frequency',[0.01 0.02 10.00 20.00]); 
defval('makeplot',0);
defval('saveplot',0);
defval('coord',0);
defval('addphases',0);
defval('rmoutlier',[]);
timeorsw=timeinfo{1};
if timeorsw>0
  intend=timeinfo{2};
  if length(intend)>1
    plotsw=timeinfo{3};
  end
end

% What will our SAC files measure?
valtypes={'disp';'vel';'acc'};
valtype=valtypes{measval+1};

% Strings needed for naming files
% Frequencies
freqstr1=num2str(frequency(1));
freqstr2=num2str(frequency(2));
freqstr3=num2str(frequency(3));
freqstr4=num2str(frequency(4));
% Event ID
evtstr=num2str(rowdata.IRISID); 

% Compute the end time of our chosen interval
% Also add a buffer on either side of the interval. This buffer will 
% be affected by the taper during instrument correction, and can be 
% removed so the taper does not affect the data
% 
% Event origin time
origtime=rowdata.OriginTime;
origtime.TimeZone='UTC';
origyear=origtime.Year;
origmon=origtime.Month;
origday=origtime.Day;
orighr=origtime.Hour;
origmin=origtime.Minute;
origsec=origtime.Second;
origjd=dat2jul(origmon,origday,origyear);
% Convert origin times to strings, for naming files
oyrstr=num2str(origyear);
ohrstr=datenum2str(orighr,0);   
ominstr=datenum2str(origmin,0);     
osecstr=datenum2str(floor(origsec),0);   
ojdstr=datenum2str(origjd,1);
% Figure out how long the time series should last
if timeorsw==2
  evlalo=[rowdata.Latitude rowdata.Longitude];
  [~,~,~,distmtr]=irisazimuth(evlalo);
  distkm=distmtr/1000;
  totaltime=round(distkm/intend(2),3);
elseif timeorsw==1
  totaltime=intend;
end
% Interval end time
posttime=origtime;
posttime.Second=posttime.Second+totaltime;

% Generate SAC files, from event origin time to our specified end time,
% using mstime2sac.m
[corrpieces,~]=mstime2sac(measval,origtime,posttime,...
  frequency,100,'',0,0,'');

% Check whether the SAC files exist
if isempty(corrpieces)
  fprintf('No SAC files were returned\n')
  return
end

% For each corrected SAC file, add information about the earthquake and
% station to the header, and rename the SAC file
components={'Z';'Y';'X'};
corrpiecesnew={};
for c=1:length(corrpieces)
  component=components{c};
  oldfile=corrpieces{c};
  corrpiece=sprintf(...
    'PP.S0001.%s.%s.%ds.HH%s.%s.%s.%s%s%s.%s%s%s%s.cr.SAC',...
    evtstr,upper(valtype(1)),round(totaltime),component,oyrstr,ojdstr,...
    ohrstr,ominstr,osecstr,freqstr1,freqstr2,freqstr3,freqstr4);
  % Note: The latitudes and longitudes become "off" in between 
  % inputting them from SAC and reading them again in MATLAB, so try to 
  % supply these variables whenever possible. 
  hdrevla=rowdata.Latitude;
  hdrevlo=rowdata.Longitude;
  hdrevdp=rowdata.Depth;
  hdrmag=round(rowdata.Magnitude,1);
  % Station latitude and longitude, from guyotphysics.m
  hdrstla=40.34585; 
  hdrstlo=-74.65475;
  hdrchange=sprintf(...
    'chnhdr EVLA %g EVLO %g STLA %g STLO %g EVDP %g MAG %g LCALDA TRUE',...
    hdrevla,hdrevlo,hdrstla,hdrstlo,hdrevdp,hdrmag);
  hdrcmd=sprintf(...
    'echo "r %s ; %s ; wh ; q" | /usr/local/sac/bin/sac',...
    oldfile,hdrchange);
  [status,cmdout]=system(hdrcmd);
  % Change the file name
  nmcmd=sprintf('mv %s %s',oldfile,corrpiece);
  [status,cmdout]=system(nmcmd);
  corrpiecesnew=vertcat(corrpiecesnew,corrpiece);
end
corrpieces=corrpiecesnew;


% Rotate SAC files, if requested
if coord>=1
  xfile=corrpieces{3};
  yfile=corrpieces{2};
  enfiles={xfile;yfile};
  rtfiles=rotsac(enfiles,[]);
  
  % Move the X and Y component SAC files if not using!
  if coord==1
    corrpieces{2}=rtfiles{2};
    corrpieces{3}=rtfiles{1};
    [status,cmdout]=system(sprintf('mv %s %s',xfile,savedir));
    [status,cmdout]=system(sprintf('mv %s %s',yfile,savedir));
  else
    corrpiecesnew={corrpieces{1};yfile;xfile;rtfiles{2};rtfiles{1}};
    corrpieces=corrpiecesnew;
  end
end

% Move the final, corrected SAC files to the requested directory
for c=1:length(corrpieces)
  corrpiece=corrpieces{c};  
  [status,cmdout]=system(sprintf('mv %s %s',corrpiece,savedir));
  corrpiece=fullfile(savedir,corrpiece);
  corrpieces{c}=corrpiece;
end

% If we're making a plot
if makeplot==1
  if coord==0
    corder=components;
    spinfo={3;[1 2 3];{'r';'g';'b'}};
  elseif coord==1
    corder={'Z';'T';'R'};
    spinfo={3;[1 2 3];{'r';[0 .75 .55];[0 .6 .75]}};
  else
    corder={'Z';'Y';'X';'T';'R'}; 
    spinfo={5;[1 2 3 4 5];{'r';'g';'b';[0 .75 .55];[0 .6 .75]}};
  end
  stainfo={[];[];[];[]};
  evtinfo={1;rowdata;addphases};
  freqinfo={frequency};
  %
  if ~isempty(corrpieces)
    plotsacdata(1,corrpieces,measval,freqinfo,corder,spinfo,...
      stainfo,rmoutlier,0,saveplot,plotdir,evtinfo,timeinfo)
  else
    fprintf('We do not have any SAC files to plot!\n')
  end
end

