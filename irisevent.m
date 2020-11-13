function evttbl=irisevent(eqinfo)
% 
% Function to return a table of event parameters for selected earthquakes,
% within a certain year and magnitude range, using IRIS's fdsnws-event web 
% service
% 
% INPUTS
% eqinfo : Search criteria we want to enter for our earthquakes, entered
%          as a cell array in this order:
%          {magrange; sttime; fintime; stalalo};
%          magrange : Magnitude range of earthquakes, entered as a vector
%                     with a lower and upper value (inclusive on both 
%                     ends!)
%          sttime : The time from which we begin our search interval for
%                   earthquakes, entered as a datetime object in UTC
%                   Default: January 1, 2018 at midnight UTC
%          fintime : The time at which we end our search interval for 
%                    earthquakes, entered as a datetime object in UTC 
%                    Default: now, in UTC
%          stalalo : Latitude and longitude of the station
%                    Default value: Location of Guyot Hall, Princeton 
%                                   University at 
%                                   [lat lon]=[40.34585 -74.65475]
%       
%          Enter an empty string or array for any of these if we don't 
%          want to use those criteria
%
% OUTPUT
% evttbl : Table of parameters describing the selected events. In order
%          from left column to right, those are:
%          IRIS ID, origin times, event latitude, event longitude, depth,
%          event magnitude, geoid distance from station to event (degrees),
%          Great Circle distance from station to event (degrees), and the
%          predicted arrival time of the earliest seismic phase to Guyot
%          Hall (UTC)
% 
% References
% Based off of mcms2evt in csdms-contrib/slepian_oscar
% Location of Guyot Hall from guyotphysics.m in csdms-contrib/slepian_zero
% Uses IRIS's fdsnws-event, traveltime, and distance-azimuth web services
% (see iristtimes.m, irisazimuth.m)
% Learned how to use awk from the IRIS Seismology Skill Building Workshop 
% in Summer 2020, of the IRIS Education and Public Outreach Program, as 
% well as from mcms2evt in csdms-contrib/slepian_oscar
% 
% Last Modified by Yuri Tamama, 10/18/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Retrieve the input parameters we need
magrange=eqinfo{1};
sttime=eqinfo{2};
fintime=eqinfo{3};
stalalo=eqinfo{4};

% Construct the web service query
queryst='https://service.iris.edu/fdsnws/event/1/query?';
queryend='orderby=time&format=text&nodata=404';
if isempty(sttime)
  sttime=datetime(2018,1,1,0,0,0);
  sttime.TimeZone='UTC';
end
if isempty(fintime)
  fintime=datetime('now');
  fintime.TimeZone='UTC';
end

% Start time
sttstr='starttime=%d-%s-%sT%s:%s:%s&';
styr=sttime.Year;
stmon=datenum2str(sttime.Month,0);
stday=datenum2str(sttime.Day,0);
sthr=datenum2str(sttime.Hour,0);
stmin=datenum2str(sttime.Minute,0);
stsec=datenum2str(floor(sttime.Second),0);
sttstr=sprintf(sttstr,styr,stmon,stday,sthr,stmin,stsec);
% End time 
fintstr='endtime=%d-%s-%sT%s:%s:%s&';
finyr=fintime.Year;
finmon=datenum2str(fintime.Month,0);
finday=datenum2str(fintime.Day,0);
finhr=datenum2str(fintime.Hour,0);
finmin=datenum2str(fintime.Minute,0);
finsec=datenum2str(floor(fintime.Second),0);
fintstr=sprintf(fintstr,finyr,finmon,finday,finhr,finmin,finsec);


% Magnitude Range
if ~isempty(magrange)
  magrange=sort(magrange,'ascend');
  magstr=sprintf('minmag=%g&maxmag=%g&',magrange(1),magrange(2));
else
  magstr='';
end

% Station latitude and longitude
if isempty(stalalo)
  stalalo=[40.34585 -74.65475];
end

irisquery=strcat(queryst,sttstr,fintstr,magstr,queryend);

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
arrivals=[];
latitudes=zeros(numevts,1);
longitudes=zeros(numevts,1);
depths=zeros(numevts,1);
magnitudes=zeros(numevts,1);
distdegsaz=zeros(numevts,1);
distdegstt=zeros(numevts,1);
for i=1:numevts
  irisids(i)=cast(str2double(irisidstrs{i}),'uint64');
  latitudes(i)=str2double(latstrs{i});
  longitudes(i)=str2double(longstrs{i});
  depths(i)=str2double(depstrs{i});
  magnitudes(i)=str2double(magstrs{i});
  
  timestr=replace(originstrs{i},'T',' ');
  origintime=datetime(timestr,'InputFormat','yyyy-MM-dd HH:mm:ss');
  origins=[origins; origintime];
  
  % Get arrival time and distance using IRIS traveltime, if possible
  if depths(i)>=0
    evlalo=[latitudes(i) longitudes(i)];
    ttimetbl=iristtimes(evlalo,depths(i),'',stalalo);
    ttimes=ttimetbl.ttimes;
    attime=ttimes(1);
    arrtime=origintime;
    arrtime.Second=arrtime.Second+attime;
    ttdistances=ttimetbl.distdegs;
    distdegstt(i)=ttdistances(1);
  else
    % If the depth is invalid, make the origin time the arrival time
    arrtime=origintime;
    % Put in -1 for the travel time generated distance
    distdegstt(i)=-1;
  end
  arrivals=[arrivals; arrtime];
  
  % Compute the distance, in degrees, from event to station using
  % IRIS's distaz service!
  [~,~,distdegaz,~]=irisazimuth(evlalo,stalalo);
  distdegsaz(i)=distdegaz;
end

origins.TimeZone='UTC';
arrivals.TimeZone='UTC';

% Create the table!
evttbl=table(irisids,origins,latitudes,longitudes,depths,magnitudes,...
  distdegsaz,distdegstt,arrivals);  
evttbl.Properties.VariableNames={'IRISID';'OriginTime';'Latitude';...
  'Longitude';'Depth';'Magnitude';'DistanceAZ';'DistanceTT';'ArrivalTime'};

