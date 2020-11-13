function [outputtbl,csvfile,wrdcsv,mdcsv]=vairmshr(measval,starttime,...
    finaltime,timezone,tzlabel,rmoutlier)
%
% Function that computes the hourly root mean squared (rms) of a weather
% phenomenon, recorded by the Vaisala WXT 530 weather station 
% (with the Septentrio PolaRx5 receiver) at Guyot Hall 
% (Princeton University) for every hour in a specified time span. 
% These values will be saved in csv files, to avoid repeating lengthy 
% processes in the future.
% 
% For inputted hours 01:00:00-23:00:00, over days 1-31 of January 2020, 
% for example, the function returns the rms of every hour over the entire 
% month. This function will be useful in finding cycles with periods 
% exceeding 24 hours. 
% 
% INPUTS
% measval : What do we wish to plot?
%           1 - Mean wind direction (degrees)
%           2 - Mean wind speed (meters/s; default)
%           3 - Air temperature (celsius)
%           4 - Relative humidity (percent)
%           5 - Air pressure (bars)
%           6 - Rain accumulation (mm)
%           7 - Hail accumulation (# hits)
%           Enter one of these values
% starttime : The time at which we begin our time series, entered as 
%             a whole numbered hour. 
%             Enter in the time zone in which we want to format our 
%             time series! 
% finaltime : The time at which we end our time series
%             Enter in the time zone in which we want to format our 
%             time series! 
% timezone : The timezone in which we want to process our data
% tzlabel : How we should label our time zone in our resulting CSV file 
%           name
% rmoutlier :  How should we define and remove our outliers?
%              0 - Use a percentage limit. For every SAC file, we remove
%                  signals that are at or above this percentile. 
%                  Enter a two number vector, with 0 as the first element
%                  and the percentile limit as the second.
%              1 - Remove outliers that are more than a certain number of
%                  median standard deviations (MAD) away from the median. 
%                  Enter a 2 number vector, with 1 as the first element 
%                  and the # of MADs as the second, like this:
%                  [1 3] - remove signals at least 3 MADs away from the
%                          median for every SAC file
% 
%              Input an empty array if we don't want to remove any signals
%              (default)
%
% savedir : Where should we save our CSV file? Enter a directory!
%           Default: current working directory
%
% NOTE: 
% The csv file outputted by our code will have the times listed in 
% local time
% 
% NOTE 2:
% starttime and finaltime should be in the same year
%
% OUTPUTS
% outputtbl : A table containing the rms values for each hour
%             The first column denotes a particular time, while the 
%             second column is the RMS data
% csvfile : The name of the CSV file, stored in the present working 
%           directory, that contains the data in outputtbl
% wrfmt : The times during which the weather data, retrieved as a CSV file,
%         might be weirdly formatted -- For example, the CSV file contains
%         a line that is not weather data (and thus might be missing data
%         for part of the hour as a result). Returns this as a list of
%         times in UTC, as a CSV file.
% missdata : The times during which the weather data are unavailable. 
%            Returns this as a list of times in UTC, as a CSV file.  
%
% References
% Uses defval.m, in csdms-contrib/slepian_alpha
% Uses figdisp.m, in csdms-contrib/slepian_alpha
% Uses char(176) to get the degree symbol, obtained from help
% forums on www.mathworks.com
% See guyotweather.m in csdms-contrib/slepian_oscar
%
% Last Modified by Yuri Tamama, 10/29/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default value
defval('measval',2)
defval('rmoutlier',[])

% Adjust the format of the inputted times and convert them to UTC
starttime.Format='eeee dd-MMM-uuuu HH:mm:ss';
starttime.TimeZone=timezone;
starttimeutc=starttime;
starttimeutc.TimeZone='UTC';
finaltime.Format='eeee dd-MMM-uuuu HH:mm:ss';
finaltime.TimeZone=timezone;
finaltimeutc=finaltime;
finaltimeutc.TimeZone='UTC';

% Total number of hours, inclusive of start and end
hrstotal=hours(finaltime-starttime)+1;

% Initialize the vectors that will contain the rms values
% If nothing is added, it will have a value of -1 as an indicator
outputvec=-1*ones(hrstotal,1);
% And the vector containing the times over which the rms values were found
outputtimes=[];
% Vectors containing times that don't correspond to "normally available'
% weather data
wrdtimes=[];
misstimes=[];

% Initialize commands to retrieve weather data and filenames to store them
urlfmt='http://geoweb.princeton.edu/people/simons/PTON/pton%s0.%d__ASC_ASCIIIn.mrk';
filefmt='pton%s0.%d__ASC_ASCIIIn.txt';
urlcmdfmt='wget "%s" -q -O %s';

% Iterate through every hour
nowhour=starttimeutc;
% Iterate through each hour
hourcount=0;
emfname='';
while finaltimeutc>=nowhour
  % Check if our file is empty  
  isemp=0;  
  % Check whether the weather file is formatted "weirdly"
  wrdfmt=0;
  % # of hours we're processing
  hourcount=hourcount+1; 
  
  % Collect the weather data!
  yrnum=nowhour.Year-2000;
  jdstr=datenum2str(dat2jul(nowhour.Month,nowhour.Day,nowhour.Year),1);
  weatherurl=sprintf(urlfmt,jdstr,yrnum);
  filename=sprintf(filefmt,jdstr,yrnum);
  if exist(filename)~=2
    urlcmd=sprintf(urlcmdfmt,weatherurl,filename);
    [status,cmdout]=system(urlcmd);
    if status~=0
      keyboard
    end
  end  
  try
    weatherdata=readtable(filename,'Format','%s%f%f%f%f%f%f%f',...
      'ReadVariableNames',false);
  catch
    try
      weatherdata=readtable(filename,'Format','%s%f%f%f%f%f%f%f');
    catch
      % If the data are unreadable, the file might be empty, or a line
      % might be weirdly formatted... Manually check the file in those
      % cases
      if isempty(emfname)  
        keyboard  
        % If the file is empty, set isemp=1
        % We want to do this because each filename has data for 1 day, 
        % not 1 hour, so we don't want to keep pausing for 1 reused file
        %
        % Set wrdfmt=1 if the file is formatted weirdly (e.g. has an
        % unnecessary line that isn't weather data)
        if wrdfmt==1
          % Note: This is just accurate for the day
          wrdtimes=[wrdtimes; nowhour];
        end
      else  
        if strcmp(emfname,filename)
          isemp=1;
        end  
      end  
      % If the CSV file is empty
      if isemp==1
        emfname=filename;  
        % Add time to outputtimes
        nowhourtz=nowhour;
        nowhourtz.TimeZone=timezone;
        outputtimes=[outputtimes; nowhourtz];
        % Add time to missing times
        misstimes=[misstimes; nowhour];
        % Note: if tomorrow is a new day, in UTC, we will use a new file. 
        % Set emfname='' if so:
        nowjd=dat2jul(nowhour.Month,nowhour.Day,nowhour.Year);
        nexthour=nowhour;
        nexthour.Hour=nowhour.Hour+1;
        nextjd=dat2jul(nexthour.Month,nexthour.Day,nexthour.Year);
        if nowjd~=nextjd
          % add break point
          emfname='';
          isemp=0;
        end
        % Move on
        nowhour.Hour=nowhour.Hour+1;
        continue
      else
        try
          weatherdata=readtable(filename,'Format','%s%f%f%f%f%f%f%f',...
           'ReadVariableNames',false);
        catch
          weatherdata=readtable(filename,'Format','%s%f%f%f%f%f%f%f'); 
        end
      end  
    end    
  end
  
  % Adjust the formatting of the times and convert them to datetime
  try
    timestrs=weatherdata.Timestamp;
  catch
    timestrs=weatherdata.Var1;
  end
  timestrs=replace(timestrs,'T',' ');
  timestrs=replace(timestrs,'Z','');
  timevals=datetime(timestrs,'InputFormat','yyyy-MM-dd HH:mm:ss');
  timevals.TimeZone='UTC';
  weatherdata.timevals=timevals;

  % Retrieve the data from one hour
  nexthour=nowhour;
  nexthour.Hour=nexthour.Hour+1;
  hrdata=weatherdata(weatherdata.timevals>=nowhour & weatherdata.timevals<nexthour,:);
  hrdata=hrdata.(measval+1);
  % Exclude outliers, if requested
  if ~isempty(rmoutlier)
    if rmoutlier(1)==0
      topprc=prctile(abs(hrdata),rmoutlier(2));
      % At or above the inputted percentile
      hrdata(abs(hrdata)>=topprc)=NaN;
    else
	  hrmad=mad(hrdata,1);
      % More than # MADs from the median 
      lowlim=median(hrdata)-hrmad*rmoutlier(2);
      highlim=median(hrdata)+hrmad*rmoutlier(2);
      hrdata(hrdata<lowlim)=NaN;
      hrdata(hrdata>highlim)=NaN;
    end
  end
  % Compute the RMS!
  rmsdata=sqrt(mean(hrdata(~isnan(hrdata)).^2));
  outputvec(hourcount)=rmsdata;
  % Add the hour, in local time, to the times array
  % Note: the hour 00:00:00, for example, has the RMS corresponding
  % to 00:00:00-00:59:59
  nowhourtz=nowhour;
  nowhourtz.TimeZone=timezone;
  outputtimes=[outputtimes; nowhourtz];
    
  % Move on to the next hour
  % First check if the JD changes, because emfname should be set to empty
  % if so:
  nowjd=dat2jul(nowhour.Month,nowhour.Day,nowhour.Year);
  nextjd=dat2jul(nexthour.Month,nexthour.Day,nexthour.Year);
  if nowjd~=nextjd
    emfname='';  
    
    % Remove the weather data file, to clear up space, if the next hour 
    % corresponds to the next day
    % Note: 'rmm' is aliased to 'rm', as 'rm' is aliased to ask for user
    % confirmation
    rmcmd=sprintf('rmm %s',filename);
    [status,cmdout]=system(rmcmd);
    if status~=0
      keyboard
    end
  end  
  nowhour.Hour=nowhour.Hour+1;
end

% Write the RMS values and their times to a table
outputtbl=table(outputtimes,outputvec);
% The date we make the CSV file, in local time
todaytime=datetime('now');
todaytime.TimeZone='America/New_York';
todayymd=sprintf('%d%s%s',todaytime.Year,datenum2str(...
  todaytime.Month,0),datenum2str(todaytime.Day,0));
% Construct the file name, in local time
yearstr=num2str(starttime.Year);
startjd=dat2jul(starttime.Month,starttime.Day,starttime.Year);
startjdstr=datenum2str(startjd,1);
finaljd=dat2jul(finaltime.Month,finaltime.Day,finaltime.Year);
finaljdstr=datenum2str(finaljd,1);
weathernames={'MWD';'MWS';'AT';'RH';'AP';'RA';'HA'};
weatherunits={'deg';'mps';'deg';'%';'bars';'mm';'hits'};
if ~isempty(rmoutlier)
  if rmoutlier(1)==0
    csvfile=sprintf(...
      'RMS%sin%s_HRLYAVG%sJD%sto%s_%s_%s.btm%s.csv',...
      weathernames{measval},weatherunits{measval},yearstr,startjdstr,...
      finaljdstr,todayymd,tzlabel,num2str(rmoutlier(2)));
  else
    csvfile=sprintf(...
      'RMS%sin%s_HRLYAVG%sJD%sto%s_%s_%s.rmMAD%s.csv',...
      weathernames{measval},weatherunits{measval},yearstr,startjdstr,...
      finaljdstr,todayymd,tzlabel,num2str(rmoutlier(2)));
  end
else
  csvfile=sprintf(...
    'RMS%sin%s_HRLYAVG%sJD%sto%s_%s_%s.csv',...
    weathernames{measval},weatherunits{measval},yearstr,startjdstr,...
    finaljdstr,todayymd,tzlabel);
end
% Write to text file
writetable(outputtbl,csvfile);  

% Write the weirdly formatted and missing data times as files
if ~isempty(wrdtimes)
  wrdcsv=sprintf('RMS%sin%s_WRDFMTHRS_%sJD%sto%s_%s.csv',...
    weathernames{measval},weatherunits{measval},yearstr,startjdstr,...
    finaljdstr,todayymd);
  wrdtbl=table(wrdtimes);
  writetable(wrdtbl,wrdcsv);
else
  wrdcsv='';
end

if ~isempty(misstimes)
  mdcsv=sprintf('RMS%sin%s_MissingDataHRS_%sJD%sto%s_%s.csv',...
    weathernames{measval},weatherunits{measval},yearstr,startjdstr,...
    finaljdstr,todayymd);
  misstbl=table(misstimes);
  writetable(misstbl,mdcsv);
else
  mdcsv='';
end


