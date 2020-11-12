function [backazimuth,azimuth,distdeg,distmtr]=irisazimuth(evlalo,stalalo)
% 
% Function to compute the backazimuth and azimuth, both in degrees, 
% from event to station, using IRIS's distance-azimuth web service
% 
% INPUTS
% evlalo : A vector containing the latitude and longitude, in that 
%              order, of an event
%              Example) [30 -90]
% stalalo : A vector containing the latitude and longitude, in that 
%           order, of the station, if computing the travel time using 
%           the latitude, longitude coordinates of station and event
%           Default value: Location of Guyot Hall, Princeton University at 
%                          (latitude, longitude)=(40.34585, -74.65475)
%
% OUTPUTS
% backazimuth : The back azimuth, in degrees
% azimuth : The azimuth, in degrees
% distdeg : The Great Circle Arc distance, computed in degrees, between
%           the event and station
% distmtr : The Great Circle Arc distance, computed in meters, between 
%           the event and station
% 
% References:
% Location of Guyot Hall from guyotphysics.m in csdms-contrib/slepian_zero
% Uses defval.m from csdms-contrib/slepian_alpha
% Uses IRIS's distance-azimuth web service
% Learned how to use grep, sed, and awk from the IRIS Seismology 
% Skill Building Workshop in Summer 2020, of the IRIS Education and 
% Public Outreach Program, as well as from mcms2evt in 
% csdms-contrib/slepian_oscar
% 
% Last Modified by Yuri Tamama, 11/08/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('stalalo',[40.34585 -74.65475]);

% Construct the query with the locations
irisquery='https://service.iris.edu/irisws/distaz/1/query?';
evlocstr=sprintf('evtlat=%g&evtlon=%g',evlalo(1),evlalo(2));
stalocstr=sprintf('stalat=%g&stalon=%g&',stalalo(1),stalalo(2));
irisquery=strcat(irisquery,stalocstr,evlocstr);

% Process query
querycmd=sprintf('wget "%s" -O- -q | ',...
  irisquery);
sedcmd='sed ''s/</ /'' | sed ''s/</ /'' | sed ''s/>/ /'' | sed ''s/>/ /'' | ';
grepcmd='grep ''tolon\|azimuth\|backAzimuth\|distance\|distanceMeters '' | ';
awkcmd='awk ''{print $2}''';
wholecmd=strcat(querycmd,sedcmd,grepcmd,awkcmd);
[status,cmdout]=system(wholecmd);
azmvals=strsplit(cmdout);
% Retrieve distance, back azimuth, azimuth
azimuth=str2double(azmvals{2});
backazimuth=str2double(azmvals{3});
distdeg=str2double(azmvals{4});
distmtr=str2double(azmvals{5});

