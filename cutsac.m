function [newdata,header]=cutsac(filenames,arrtime,intstart,intend,rowdata,evtheader)
% 
% Function that takes a number of SAC files of the same component 
% and of consecutive hours and trims them down to one SAC file whose 
% length spans a given time interval surrounding
% the arrival time of the event recorded in the SAC file
% The header is also edited to include information about the event, 
% if requested
% 
% INPUTS
% filenames : Cell array containing the names the SAC files to cut
%             The SAC files should be of consecutive hours, ordered from 
%             earliest to latest, and of the same directional component
%             ('X', 'Y', or 'Z')
% arrtime : The arrival time of the event recorded
% intstart : The number of seconds before the arrival time at which 
%            the time interval begins (default: 60)
% intend : The number of seconds after the arrival time at which the
%          time interval ends (default: 360)
% rowdata : One row of IRIS catalog data, created by mcms2evt, 
%           corresponding to the event
%           Columns (left to right): eventID, date of event (as a string),
%           event latitude, event longitude, depth, event magnitude,
%           geoid distance from station to event (degrees), spherical 
%           distance from station to event (degrees), and travel time
%           of the first arrival to Guyot Hall (in seconds)
% evtheader : Do we want to add information about the event recorded in 
%             the header? 
%             0 for no (default)
%             1 for yes
% 
% OUTPUTS
% The data (newdata) and header of the trimmed SAC file(s), spanning 
% the chosen interval length
% 
% See mcevt2sac.m and mcevtfiles2sac.m
% 
% References:
% Code to convert from a .miniseed file to a .SAC file and
% apply instrument response correction from
% mcms2mat.m, in csdms-contrib/slepian_oscar
% 
% Uses readsac.m, writesac.m, plotsac.m to read in, create, and plot
% the data from SAC files, in csdms-contrib/slepian_oscar
% 
% Consulted the SAC manual, from http://ds.iris.edu/files/sac-manual/
% 
% Last Modified by Yuri Tamama, 06/26/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default values
defval('intstart',60);
defval('intend',360);
defval('evtheader',0);

% Check total length of interval
inttotal=intstart+intend;
if inttotal>3600
  warning('Intervals longer than 1 hour are discouraged.')
end 

% Find times corresponding to interval start and end
pretime=arrtime;
pretime.Second=arrtime.Second-intstart;
posttime=arrtime;
posttime.Second=arrtime.Second+intend;

% How many files do we have? 
% 1 file -- 1 hour
if length(filenames)==1
  % Load the file 
  [seisdata,header,~,~,~]=readsac(filenames{1},0);
  
  % Figure out at what indices we trim the file
  arrivaltime=(arrtime.Minute*60)+arrtime.Second;
  arrivalind=arrivaltime*100+1;
  startind=arrivalind-(intstart*100);
  endind=arrivalind+(intend*100); 
    
% Multiple files -- multiple hours
else
  % Iterate through all the files, for each hour between interval
  % start and end
  mcdate=pretime;
  for i=1:length(filenames)
    % Read in the SAC files and concatenate their data
    if i==1
      [seisdata,header]=readsac(filenames{1},0);
    else
      [tempdata,~]=readsac(filenames{i},0);
      seisdata=vertcat(seisdata,tempdata);
    end
    % Move onto the next hour
    mcdate.Hour=mcdate.Hour+1;
  end
  
  % Figure out at what indices we trim the files
  arrivaltime=(arrtime.Minute*60)+arrtime.Second;
  % The arrival time may not be captured in the earliest SAC file
  arrivaltime=arrivaltime+3600*(arrtime.Hour-header.NZHOUR);
  arrivalind=arrivaltime*100+1;
  startind=arrivalind-(intstart*100);
  endind=arrivalind+(intend*100);
 
end    

% Trim the SAC file and edit the header!
allind=1:length(seisdata);
newdata=seisdata((allind>=startind) & (allind<=endind));
header.B=(pretime.Minute*60)+pretime.Second;
header.E=(posttime.Minute*60)+posttime.Second;
header.NPTS=length(newdata);
header.NZMIN=pretime.Minute;
header.NZSEC=floor(pretime.Second/1);
if mod(pretime.Second,1) > 0
  header.NZMSEC=round(mod(pretime.Second,1)*1000);  
end

% Add information about the event to the header if requested
if evtheader==1
  header.EVLA=double(rowdata.Var3);
  header.EVLO=double(rowdata.Var4);
  header.EVDP=double(rowdata.Var5);
  header.MAG=double(rowdata.Var6);
  header.GCARC=double(rowdata.Var7);
  header.DIST=grcdist([header.EVLO header.EVLA]);
  % SAC won't let me change the EVENT ID header, so I'll add the 
  % EVENT ID to the event name header
  header.KEVNM=evtstr; 
end



