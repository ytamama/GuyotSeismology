function [lgdstr,titlestr,wthrname]=addvairms(csvfile,measval,starttime,...
    finaltime,tzone)
% 
% Function to superimpose a root mean squared (RMS) averaged plot of a 
% weather phenomenon, recorded by the Vaisala WXT530 weather station
% (and used in conjunction with a Septentrio PolaRx5 receiver) on 
% Guyot Hall, Princeton University, on a subplot of RMS averaged ground
% motion, also recorded at Guyot Hall, over the same time period. 
% 
% This function is compatible with the results of guyotrmsseishr.m 
% 
% INPUTS
% csvfile : CSV file containing the RMS values of a particular
%           weather phenomenon, averaged over the same time period as our
%           ground motion values
% measval : What are we plotting?
%           1 - Mean wind direction (degrees)
%           2 - Mean wind speed (meters/s; default)
%           3 - Air temperature (celsius)
%           4 - Relative humidity (percent)
%           5 - Air pressure (bars)
%           6 - Rain accumulation (mm)
%           7 - Hail accumulation (# hits)
%           Enter one of these values
% starttime : From what time do we start our time series? 
%             Input a datetime vector in local time. 
% finaltime : At what time do we end our time series?
%             If plotting 'day' or 'hr' (rmstype=0 or 1), input a 
%             datetime vector in local time. 
% saveplot : Do we want to save our plot?
%            0 - No (default)
%            1 - Yes 
% savedir : Where do we save our plot? Specify the directory as a string!
%           By default, figure will be saved in your current working
%           directory
%
% OUTPUT
% lgdstr : The string to add to our plot legend, to indicate the weather
%          data plotted, if necessary
% titlestr : The string to add to our plot title, to indicate the weather
%            data plotted, if necessary
% wthrname : A short abbreviation of what weather phenomenon we plotted
%
% References
% Uses defval.m, figdisp.m in csdms-contrib/slepian_alpha 
% Referred to guyotweather.m, in csdms-contrib/slepian_oscar
% 
% See guyotrmsseishr.m, guyotrmsplot.m, vairmshr.m
%
% Last Modified by Yuri Tamama, 12/27/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load the weather data
rmsdata=readtable(csvfile,'Delimiter',',');
rmsvals=rmsdata.outputvec;
timevec=rmsdata.outputtimes;
% Convert the time vector, which is in strings, to datetimes if needed
timevector=[];
try
  for i=1:length(timevec)
    nowtime=datetime(timevec{i},'InputFormat','eeee dd-MMM-uuuu HH:mm:ss');
    % The time values are in the inputted time zone!  
    nowtime.TimeZone=tzone;
    timevector=[timevector; nowtime];  
  end
catch
  timevector=timevec;
  timevector.TimeZone=tzone;
end
% What are we plotting?
fullnames={'Mean Wind Direction';'Mean Wind Speed';'Air Temperature';...
  'Relative Humidity';'Air Pressure';'Rain Accumulation';...
  'Hail Accumulation'};
fullname=fullnames{measval};
wthrnames={'MWD';'MWS';'AT';'RH';'AP';'RA';'HA'};
wthrname=wthrnames{measval};
wthrunits={'deg';'mps';'deg';'%';'bars';'mm';'hits'};
wthrunit=wthrunits{measval};

% Cut down our time vector to the desired interval
% Inclusive of starttime and finaltime!
indices=(timevector>=starttime & timevector<=finaltime);
timevector=timevector(indices==1);
rmsvals=rmsvals(indices==1);
% Replace values equal to -1 with NaN
rmsvals(rmsvals==-1)=NaN;

% Add the weather data to the subplot!  
yyaxis right
wthrline=plot(timevector,rmsvals);
wthrline.Color=[0.3 0.3 0.3];
wthrline.LineWidth=.4;
prc0=round(prctile(rmsvals,0));  
prc100=round(max(rmsvals));
if prc0<10
  prc0=round(prc0,2);
elseif prc0<100
  prc0=round(prc0,1);
else
  prc0=round(prc0);
end
if prc100<10
  prc100=round(prc100,2);
elseif prc100<100
  prc100=round(prc100,1);
else
  prc100=round(prc100); 
end
axes=gca;
axes.YTick=unique([prc0; prc100]);
axes.YTickLabel={num2str(prc0);num2str(prc100)};
axes.YLim=[0 round(1.2*prc100)];
axes.YColor=[.25 .25 .25];

% Legend and title
lgdstr=fullname;
titlestr=sprintf('RMS %s (%s)',fullname,wthrunit);



