function [backazimuth,azimuth,distdeg,distmtr]=irisazimuth(evlalo,stalalo)
% 
% Function to compute the backazimuth and azimuth, both in degrees, 
% from event to station, using IRIS's distaz web service
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
% distdeg : The Great Circle Arc distance, computed in degrees, between
%           the event and station
% distmtr : The Great Circle Arc distance, computed in meters, between 
%           the event and station
%
% OUTPUTS
% ttimetbl : A table, showing the outputs of the IRIS traveltime query
% ttimefile : The name of the text file, in the current working directory,
%             containing the contents of ttimetbl.
% 
% References:
% Location of Guyot Hall from csdms-contrib/slepian_zero
% defval.m from csdms-contrib/slepian_alpha
%
% Uses IRIS's distaz web service
% 
% Last Modified by Yuri Tamama, 07/15/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
