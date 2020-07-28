function ttimetbl=iristtimes(evlalodist,evdep,evdistunit,stalalo)
% 
% Function that constructs and outputs the results of an IRIS 
% traveltime query. 
% IRIS's traveltime web service generates the predicted travel times 
% of various phases for an event at a specified latitude, longitude, 
% and depth to reach a specified station latitude and longitude.
% 
% INPUTS
% evlalodist : A vector containing the latitude and longitude, in that 
%              order, of an event, OR the distance from the event to 
%              station in degrees or kilometers. If using the former,
%              enter a vector of length 2. If using the latter option, 
%              enter a vector of length 1.
%              Example) [30 -90]
%              Example) [10]
% evdep : The depth of the event, in km. Enter -1 if unknown or is an 
%         "airquake".
% evdistunit : Enter the units of the distance entered in evlalodist, 
%              if using that option. Alternatively, enter an empty string
%              if entering latitude and longitude in evlalodist.
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
% 
% References:
% Location of Guyot Hall from csdms-contrib/slepian_zero
% defval.m from csdms-contrib/slepian_alpha
%
% Uses IRIS's traveltime web service
% 
% Last Modified by Yuri Tamama, 07/28/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
defval('stalalo',[40.34585 -74.65475]);

% Construct the query with the locations/distance
irisquery='https://service.iris.edu/irisws/traveltime/1/query?';
evdepstr=sprintf('evdepth=%.3f',evdep);
if length(evlalodist)==2
  evlocstr=sprintf('evloc=[%.3f,%.3f]',evlalodist(1),evlalodist(2));
  stalocstr=sprintf('staloc=[%.3f,%.3f]',stalalo(1),stalalo(2));
  irisquery=strcat(irisquery,stalocstr,'&',evlocstr,'&',evdepstr);
else
  if strcmpi(evdistunit(1),'d')==1
    evlocstr=sprintf('distdeg=%.3f',evlalodist(1));
  else
    evlocstr=sprintf('distkm=%.3f',evlalodist(1));
  end
  irisquery=strcat(irisquery,evlocstr,'&',evdepstr);
end
% No header, and only 1 traveltime per phase
irisquery=strcat(irisquery,'&mintimeonly=true&noheader=true');

% Query to submit via the command line
querycmd=sprintf('wget "%s" -O- -q | awk ''{print $2,$3,$4}''',...
  irisquery);
[status,cmdout]=system(querycmd);
outputs=strsplit(cmdout);
% phases: indices 2, 5, 8, 11...
% times: indices 3, 6, 9,...
phases={};
ttimes=[];
for i=1:length(outputs)
  if i==2
    phases=vertcat(phases,outputs{i});
    outputcount=1;
  end 
  if mod(i,3)==0
    ttimes=[ttimes;str2num(outputs{i})];
  end
  if i>2
    if outputcount==3
      phases=vertcat(phases,outputs{i});
      outputcount=1;
    else
      outputcount=outputcount+1;
    end
  end
end

% Create the table
% Column order: phase name, then travel time
ttimetbl=table(phases,ttimes);

