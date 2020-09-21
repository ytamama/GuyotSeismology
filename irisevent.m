function evttbl=irisevent(year,magrange,stalalo)
% 
% Function to return a table of event parameters for selected earthquakes,
% within a certain year and magnitude range, using IRIS's event web 
% service
% 
% INPUTS
% year : The year in which the earthquakes take place
% magrange : Magnitude range, entered as a vector with a lower and 
%            upper value (inclusive on both ends!)
% stalalo : Latitude and longitude of the station
%           Default value: Location of Guyot Hall, Princeton University at 
%                          (latitude, longitude)=(40.34585, -74.65475)
%
% OUTPUT
% evttbl : Table of parameters describing the selected events. In order
%          from left column to right, those are:
%          IRIS ID, origin times, latitude, longitude, depth (km),
%          magnitude, distance (degrees)
% 
% References
% Location of Guyot Hall from csdms-contrib/slepian_zero
% defval.m from csdms-contrib/slepian_alpha
% Uses IRIS's event and distaz web services
% Modeled after mcms2evt in csdms-contrib/slepian_oscar
% 
% Last Modified by Yuri Tamama, 09/11/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('stalalo',[40.34585 -74.65475]);

% Construct the web service query
queryst='https://service.iris.edu/fdsnws/event/1/query?';
queryend='orderby=time&format=text&nodata=404';
starttimestr=sprintf('starttime=%d-01-01T00:00:00&',year);
if year==2020
  finaltime=datetime('now');
  finalmon=datenum2str(finaltime.Month,0);
  finalday=datenum2str(finaltime.Day,0);
  finalhr=datenum2str(finaltime.Hour,0);
  finalmin=datenum2str(finaltime.Minute,0);
  finalsec=datenum2str(finaltime.Second,0);
  finaltimestr=sprintf('endtime=%d-%s-%sT%s:%s:%s&',year,finalmon,...
    finalday,finalhr,finalmin,finalsec);
else
  finaltimestr=sprintf('endtime=%d-12-31T23:59:59&',year);
end
magrange=sort(magrange,'ascend');
magstr=sprintf('minmag=%g&maxmag=%g&',magrange(1),magrange(2));
%
irisquery=strcat(queryst,starttimestr,finaltimestr,magstr,queryend);

% Submit the query and collect the data we need
querycmd=sprintf('wget "%s" -O- -q | ',irisquery);
awkcmd='awk -F ''|'' ''{print $1,$2,$3,$4,$5,$11}''';
wholecmd=strcat(querycmd,awkcmd);
[status,cmdout]=system(wholecmd);
evtvals=strsplit(cmdout);
% IRISID: Index 7, 13, 19
% Origin: Index 8, 14, 20
% Latitude: Index 9, 15, 21
% and so on... 
irisidstrs=evtvals(7:6:length(evtvals)-1);
originstrs=evtvals(8:6:length(evtvals)-1);
latstrs=evtvals(9:6:length(evtvals)-1);
longstrs=evtvals(10:6:length(evtvals)-1);
depstrs=evtvals(11:6:length(evtvals)-1);
magstrs=evtvals(12:6:length(evtvals)-1);
numevts=length(irisidstrs);

% Convert those cell arrays to arrays!
irisids=zeros(numevts,1);
origins=[];
latitudes=zeros(numevts,1);
longitudes=zeros(numevts,1);
depths=zeros(numevts,1);
magnitudes=zeros(numevts,1);
distdegs=zeros(numevts,1);
for i=1:numevts
  irisids(i)=str2double(irisidstrs{i});
  latitudes(i)=str2double(latstrs{i});
  longitudes(i)=str2double(longstrs{i});
  depths(i)=str2double(depstrs{i});
  magnitudes(i)=str2double(magstrs{i});
  
  timestr=replace(originstrs{i},'T',' ');
  origintime=datetime(timestr,'InputFormat','yyyy-MM-dd HH:mm:ss');
  origintime.TimeZone='UTC';
  origins=[origins; origintime];
  
  % Compute the distance, in degrees, from event to station using
  % IRIS's distaz service!
  evlalo=[latitudes(i) longitudes(i)];
  [~,~,distdeg,~]=irisazimuth(evlalo,stalalo);
  distdegs(i)=distdeg;
end

% Create the table!
evttbl=table(irisids,origins,latitudes,longitudes,depths,magnitudes,...
  distdegs);
evttbl.Properties.VariableNames={'IRISID';'OriginTime';'Latitude';...
  'Longitude';'Depth';'Magnitude';'Distance'};

