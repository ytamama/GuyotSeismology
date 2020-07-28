function locationstr=irisevtloc(evtid)
% 
% Function that outputs the name of the region where an IRIS-recorded 
% seismic event takes place. The function submits a query to the event 
% web service from IRIS.
% 
% INPUT
% evtid : The IRIS ID of the seismic event
% 
% OUTPUT
% locationstr : The name of the region where the seismic event took place
% 
% References
% Uses IRIS's event web service
% 
% Last Modified by Yuri Tamama, 07/22/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Build query URL
queryurl=sprintf(...
  'https://service.iris.edu/fdsnws/event/1/query?format=text&eventid=%d&nodata=404',...
  evtid);
fullquery=strcat('wget "',queryurl,'" -O- -q | ');
awkcmd=' awk -F "|" ''NR>1{print $12,$13}''';
fullcmd=strcat(fullquery,awkcmd);
[status,cmdout]=system(fullcmd);
% Retrieve Location!
locstrs=strsplit(cmdout);
locationstr='';
for i=2:length(locstrs)-1
  tempstr=locstrs{i};
  tempstr=strcat(tempstr(1),lower(tempstr(2:length(tempstr))));
  if i>2
    tempstr=sprintf(' %s ',tempstr);
  end
  locationstr=strcat(locationstr,tempstr);
end



