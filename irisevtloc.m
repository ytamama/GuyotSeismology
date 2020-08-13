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
% evlalo : The latitude and longitude of the event, formatted as a 
%          vector with the latitude first, then longitude
% 
% References
% Uses IRIS's event web service
% 
% Last Modified by Yuri Tamama, 08/13/2020
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
% Retrieve location name
locstrs=strsplit(cmdout);
locationstr='';
for j=2:length(locstrs)-1
  tempstr=locstrs{j};
  tempstr2='';
  if length(tempstr)>1
    for i=1:length(tempstr)
      if i==1
        tempchar=upper(tempstr(i));
      elseif (i>1) && strcmp(tempstr(i-1),'-')
        tempchar=upper(tempstr(i));
      elseif (i<length(tempstr))
        if strcmp(tempstr(i+1),'.') 
          tempchar=upper(tempstr(i));
          if ~strcmp(tempstr(i-1),upper(tempstr(i-1)))
            tempchar=lower(tempstr(i));
          end
        else
          tempchar=lower(tempstr(i));
        end
      else
        tempchar=lower(tempstr(i));
      end
      tempstr2=strcat(tempstr2,tempchar);
    end
  end
  if j>2
    tempstr2=sprintf(' %s ',tempstr2);
  end
  locationstr=strcat(locationstr,tempstr2);
end

