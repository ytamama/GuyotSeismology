function newfile=cutsac(filenames,starttime,fintime,newname,...
    rowdata,evtheader)
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
% starttime : The time at which we would like to begin the interval
% fintime : The time at which we would like to end the interval
% newname : The name of the new file we will write 
% rowdata : One row of IRIS catalog data, created by mcms2evt, 
%           corresponding to the event
%           Columns (left to right): eventID, date of event (as a string),
%           event latitude, event longitude, depth, event magnitude,
%           geoid distance from station to event (degrees), Great Circle
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
% Accessing SAC commands from MATLAB from
% mcms2mat.m, in csdms-contrib/slepian_oscar
% 
% Uses readsac.m, writesac.m, plotsac.m to read in, create, and plot
% the data from SAC files, in csdms-contrib/slepian_oscar
% 
% Uses defval.m, from csdms-contrib/slepian_alpha
% 
% Consulted the SAC manual, from http://ds.iris.edu/files/sac-manual/
% 
% Last Modified by Yuri Tamama, 07/10/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('evtheader',0);

% Check total length of interval
inttotal=seconds(fintime-starttime);
if inttotal>3600
  warning('Intervals longer than 1 hour are discouraged.')
end 

% How many files do we have? 
% 1 file -- 1 hour
if length(filenames)==1
  sacfile=filenames{1};
  % Figure out at where we trim the file
  startpt=round((starttime.Minute*60)+starttime.Second,1);
  finpt=round((fintime.Minute*60)+fintime.Second,1);
  newend=finpt-startpt;
  % Cut file
  cutcmd=sprintf(...
    'echo "r %s ; cut %g %g ; read ; chnhdr B 0 E %g ; w %s ; q" | /usr/local/sac/bin/sac',...
    sacfile,startpt,finpt,newend,newname);
  [status,cmdout]=system(cutcmd);   
  
% Multiple files -- multiple hours
else
  mcdate=pretime;
  readcmd='r %s';
  for i=1:length(filenames)
    % Construct a SAC command to read through all files
    readcmd=sprintf(readcmd,sacname);  
    if i<(length(filenames))
      readcmd=strcat(readcmd,' %s');   
    end 
    % Move onto the next hour
    mcdate.Hour=mcdate.Hour+1;
  end
  
  % Figure out at what indices we trim the files
  startpt=round((starttime.Minute*60)+starttime.Second,1);
  finpt=round(startpt+seconds(fintime-starttime),1);
  newend=finpt-startpt;
  
  % Merge and cut the SAC file
  mergecmd=sprintf(...
    'echo "%s ; merge ; w %s ; q" | /usr/local/sac/bin/sac',...
    readcmd,newname);
  [status,cmdout]=system(mergecmd);
  cutcmd=sprintf(...
    'echo "r %s ; cut %g %g ; read ; chnhdr B 0 E %g ; w %s ; q" | /usr/local/sac/bin/sac',...
    newname,startpt,finpt,newend,newname);
  [status,cmdout]=system(cutcmd);
end    

% Edit the header to have the new start time!
newjd=dat2jul(starttime.Month,starttime.Day,starttime.Year);
newhr=starttime.Hour;
newmin=starttime.Minute;
newsec=floor(starttime.Second/1);
if mod(pretime.Second,1) > 0
  newmsec=round(mod(starttime.Second,1)*1000);  
end
timecmd=sprintf(...
  'echo "r %s ; chnhdr NZJDAY %d NZHOUR %d NZMIN %d NZSEC %d NZMSEC %d ; w %s ; q" | /usr/local/sac/bin/sac',...
  newname,newjd,newhr,newmin,newsec,newmsec,newname);
[status,cmdout]=system(timecmd);

% Add information about the event to the header if requested
if evtheader==1
  hdrevla=round(rowdata.Var3,1);
  hdrevlo=round(rowdata.Var4,1);
  hdrevdp=round(rowdata.Var5,1);
  hdrmag=round(rowdata.Var6,1);
  hdrchange=sprintf('chnhdr EVLA %g EVLO %g EVDP %g MAG %g LCALDA TRUE',...
    hdrevla,hdrevlo,hdrevdp,hdrmag);
  hdrcmd=sprintf(...
    'echo "r %s ; %s ; w %s ; q" | /usr/local/sac/bin/sac',...
    newname,hdrchange,newname);
  [status,cmdout]=system(hdrcmd);
end



