function ttimetbl=iristtimes(evlalodist,evdep,evdistunit,stalalo)
% 
% Function that constructs and outputs the results of an IRIS 
% traveltime query. 
% 
% INPUTS
% evlalodist : A vector containing the latitude and longitude, in that 
%              order, of an event, OR the distance from the event to 
%              station in degrees or kilometers. If using the former,
%              enter a vector of length 2. If using the latter option, 
%              enter a vector of length 1.
%              Example) [30 -90]
%              Example) [10]
% evdep : The depth of the event, in km. Enter -1 if unknown or occurs 
%         above ground.
% evdistunit : Enter the units of the distance entered in evlalodist, 
%              if using that option.
% 
%              Example) Empty string, for latitude and longitude
%              Example) 'degrees', 'deg' for degrees
%              Example) 'kilometers', 'kilo', 'km' for kilometers
% stalalo : A vector containing the latitude and longitude, in that 
%           order, of the station, if computing the travel time using 
%           the latitude, longitude coordinates of station and event
%           Default value: Location of Guyot Hall, Princeton University at 
%                          (latitude, longitude)=(40.34585, -74.65475)
% 
% OUTPUTS
% ttimetbl : A table, showing the outputs of the IRIS traveltime query
%            From left column to right: phase name, distance from event
%            to station (degrees), travel time (seconds)
% 
% References:
% Uses IRIS's traveltime web service
% Location of Guyot Hall from guyotphysics.m in csdms-contrib/slepian_zero
% defval.m from csdms-contrib/slepian_alpha
% Uses IRIS's fdsnws-event web service
% Learned how to use awk from the IRIS Seismology Skill Building Workshop 
% in Summer 2020, of the IRIS Education and Public Outreach Program, as 
% well as from mcms2evt in csdms-contrib/slepian_oscar
% 
% Last Modified by Yuri Tamama, 12/27/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
defval('stalalo',[40.34585 -74.65475]);

% Construct the query with the locations/distance
irisquery='https://service.iris.edu/irisws/traveltime/1/query?';
evdepstr=sprintf('evdepth=%g',evdep);
if length(evlalodist)==2
  evlocstr=sprintf('evloc=[%g,%g]',evlalodist(1),evlalodist(2));
  stalocstr=sprintf('staloc=[%g,%g]',stalalo(1),stalalo(2));
  irisquery=strcat(irisquery,stalocstr,'&',evlocstr,'&',evdepstr);
else
  if strcmpi(evdistunit(1),'d')==1
    evlocstr=sprintf('distdeg=%g',evlalodist(1));
  else
    evlocstr=sprintf('distkm=%g',evlalodist(1));
  end
  irisquery=strcat(irisquery,evlocstr,'&',evdepstr);
end
% No header, and only 1 traveltime per phase
irisquery=strcat(irisquery,'&mintimeonly=true&noheader=true');

% Query to submit via the command line
querycmd=sprintf('wget "%s" -O- -q | awk ''{print $1,$2,$3,$4}''',...
  irisquery);
[status,cmdout]=system(querycmd);
outputs=strsplit(cmdout);
% phases: 3, 7, 11, 15...
% distances: Index 5
% times: 4, 8, 12, 16...
distdeg=str2double(outputs{5});
phases={};
ttimes=[];
for i=1:length(outputs)
  if i==3
    phases=vertcat(phases,outputs{i});
    nextind=i+4;
  end 
  if mod(i,4)==0
    ttimes=[ttimes;str2double(outputs{i})];
  end
  if i>3
    if i==nextind
      phases=vertcat(phases,outputs{i});
      nextind=i+4;
    end
  end  
end
distdegs=ones(length(phases),1)*distdeg;


% Create the table
% Column order: phase name, distance, travel time
ttimetbl=table(phases,distdegs,ttimes);
ttimetbl=sortrows(ttimetbl,3,'ascend');


