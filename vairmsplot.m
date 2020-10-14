function rmsplot=vairmsplot(csvfile,measval,starttime,finaltime,...
  timezone,tzlabel,prclimit,saveplot,savedir,addlegend,adjustplot,...
  vertlines,vertlinelabs,customtitle,customxlabel,customfigname,lineclr)
% 
% Function to plot the time series of RMS weather phenomena
% See vairmshr.m
% 
% Later edit to have plotting functionality for multiple years! 
% 
% INPUTS
% csvfile : A csv file, containing the RMS values of the weather data that
%           you wish to plot
% measval : What are we plotting the RMS of?
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
%             Input a datetime vector in local time. 
% timezone : The MATLAB time zone of the times plotted
%            Default: 'UTC'
% tzlabel : The label characterizing the time zone of the times plotted
% prclimit : The threshold, given as a percentile, for the values plotted
%            when they were generated in the csv-producing codes
%            (see vairmshr.m)
%            Default: 100
% saveplot : Do we wish to save our plot?
%            0 : No
%            1 : Yes (Default)
% savedir : Where do we save our plot? Specify the directory as a string!
%           Default: current working directory
% adjustplot : Do we want to adjust the cosmetics of our plot by hand, 
%              at the end?
%              0 : No (Default)
%              1 : Yes
% vertlines : If we want to mark important dates in the most recent year,
%             when are they? Input a vector containing the datetime objects
%             for those times, with the time zone of those datetimes 
%             matching that of the inputted data. 
%             Enter an empty vector if we do not wish to plot vertical
%             lines.
% vertlinelabs : How do we want to mark those lines in the legend?
%                Enter as a cell array containing the label(s), as strings.
%                Enter an empty cell array if we do not wish to plot 
%                vertical lines.
% customtitle : Enter a title for the plot, if desired, as a cell array.
%               Enter an empty cell array to use the default title.
% customxlabel : Enter a horizontal axis label, if desired, as a string.
%                Enter an empty string to use the default label.
% customfigname : Enter a name for the figure, if desired, as a string. 
%                 Enter an empty string to use the default name.
% lineclr : The color of the line plot, entered as a string or RGB 
%           triplet. 
%           Default: 'r'
%
% Note: starttime and finaltime should be in the same year!
%
% OUTPUT
% rmsplot : The figure handle of the RMS time series
% 
% References
% Uses defval.m, figdisp.m in csdms-contrib/slepian_alpha 
% 
% Last Modified by Yuri Tamama, 10/14/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('measval',2);
defval('timezone','UTC')
defval('tzlabel','UTC')
defval('prclimit',100)
defval('saveplot',1);
% Insert your own directory!
defval('savedir',pwd);
defval('adjustplot',0);
defval('vertlines',[]);
defval('vertlinelabs',{});
defval('lineclr','r');
defval('customtitle','')
defval('customxlabel','')
defval('customfigname','')

% Load data
rmsdata=readtable(csvfile,'Delimiter',',');
rmsvals=rmsdata.outputvec;
timevec=rmsdata.outputtimes;
% Convert the time vector, which is in strings, to datetimes
timevector=[];
for i=1:length(timevec)
  nowtime=datetime(timevec{i},...
    'InputFormat','eeee dd-MMM-uuuu HH:mm:ss');
  % The time values are in the inputted time zone!  
  nowtime.TimeZone=timezone;
  timevector=[timevector; nowtime];  
end

% Cut down our time vector to the desired interval
% Inclusive of starttime and finaltime!
indices=(timevector>=starttime & timevector<=finaltime);
timevector=timevector(indices==1);
rmsvals=rmsvals(indices==1);


% Horizontal axis labels
ticksat=[];
ticklabels={};
for i=1:length(timevector)
  ticktime=timevector(i);
  ticktime.Format='eeee dd-MMM-uuuu HH:mm:ss';
  ticktimestr=cellstr(ticktime);
  ticktimestr=strsplit(ticktimestr{1});
  tickdaystr=ticktimestr{1};
  % Tick marks on the weekend
  if strcmpi('Saturday',tickdaystr)
    if ticktime.Hour==0 
      ticklabels=vertcat(ticklabels,'S');
      ticksat=[ticksat;ticktime];
    end
  elseif strcmpi('Monday',tickdaystr)
    if ticktime.Hour==0
      ticksat=[ticksat; ticktime];   
      ticklabels=vertcat(ticklabels,'S'); 
    end
  end
end

% Plot the data!
rmsplot=figure();
legendstrs={};
plotline=plot(timevector,rmsvals);
legendstrs=vertcat(legendstrs,num2str(starttime.Year));
plotline.Color=lineclr;
ylim([0 1.2*max(abs(rmsvals))]);
xlim([timevector(1) timevector(length(timevector))])
% Plot vertical lines, if applicable
if ~isempty(vertlines)
  for i=1:length(vertlines)
    line([vertlines(i) vertlines(i)],ylim,'Color',[.55 .55 .55]);
  end
  if ~isempty(vertlinelabs)  
    legendstrs=vertcat(legendstrs,vertlinelabs{i});
  end
end
% Add grid lines
nowaxes=gca;
% Label vertical axes
prc0=round(prctile(rmsvals,0));
prc50=round(prctile(rmsvals,50));
prc100=round(max(rmsvals));
% keyboard
if isempty(nowaxes.YTick) || isempty(nowaxes.YTickLabel)
  nowaxes.YTick=unique([prc0; prc50; prc100]);
end
wthrnames={'MWD';'MWS';'AT';'RH';'AP';'RA';'HA'};
wthrunits={'deg';'mps';'deg';'%';'bars';'mm';'hits'};
ylabel(sprintf('%s (%s)',wthrnames{measval},wthrunits{measval}))

% Add horizontal axis ticks and labels
nowaxes.XTickMode='manual';
nowaxes.XTick=ticksat;
grid on
nowaxes.XTickLabelMode='manual';
nowaxes.XTickLabel=ticklabels;
monthnames={'Jan';'Feb';'Mar';'Apr';'May';'June';'July';'Aug';'Sept';...
  'Oct';'Nov';'Dec'};
startdate=timevector(1);
startwkday=getweekday(startdate);
finaldate=timevector(length(timevector));
finalwkday=getweekday(finaldate);
datestr1=sprintf('%s:%s:%s %s, %s %d',datenum2str(startdate.Hour,0),...
  datenum2str(startdate.Minute,0),datenum2str(startdate.Second,0),...
  startwkday,monthnames{startdate.Month},startdate.Day);
datestr2=sprintf('%s:59:59 %s, %s %d',datenum2str(finaldate.Hour,0),...
  finalwkday,monthnames{finaldate.Month},finaldate.Day);
if isempty(customxlabel)
  xlabel(sprintf('%s to %s %d (%s)',datestr1,datestr2,startdate.Year,...
    tzlabel)); 
else
  xlabel(customxlabel)
end

% Add title
fullnames={'Mean Wind Direction';'Mean Wind Speed';'Air Temperature';...
  'Relative Humidity';'Air Pressure';'Rain Accumulation';...
  'Hail Accumulation'};
if isempty(customtitle)
  if prclimit<100
    titlestr1=sprintf('Hourly RMS %s (Bottom %g%% per Hour)',...
      fullnames{measval},prclimit);
  else
    titlestr1=sprintf('Hourly RMS %s',fullnames{measval});
  end
  titlestr2=sprintf('Recorded at the Vaisala Weather Station in %d',...
    starttime.Year);
  titlestr3='Guyot Hall, Princeton University';
  if ~isempty(vertlines) && ~isempty(vertlinelabs)
    titlestrv='Vertical Lines Labeled Chronologically';
    title({titlestr1;titlestr2;titlestr3;titlestrv},'interpreter','tex')
  else
    title({titlestr1;titlestr2;titlestr3})
  end
else
  title(customtitle,'interpreter','tex')
end

% Add legend if requested
if addlegend==1 && ~isempty(vertlinelabs)
  legend(legendstrs,'Location','northeast','FontSize',6); 
end

% Adjust cosmetics of plot, if desired
if adjustplot==1
  keyboard
end

% Save figure
if saveplot==1
  starthr=datenum2str(starttime.Hour,0);
  endhr=datenum2str(finaltime.Hour,0);
  if isempty(customfigname)
    if prclimit<100
      figname=sprintf(...
        'RMS%sin%s.%s.%sto%s.%sto%s.%s.btm%s.eps',...
        wthrnames{measval},wthrunits{measval},...
        num2str(starttime.Year),...
        datenum2str(dat2jul(starttime.Month,starttime.Day,starttime.Year),1),...
        datenum2str(dat2jul(finaltime.Month,finaltime.Day,finaltime.Year),1),...
        starthr,endhr,upper(tzlabel),num2str(prclimit));
    else
      figname=sprintf(...
        'RMS%sin%s.%s.%sto%s.%sto%s.%s.eps',...
        wthrnames{measval},wthrunits{measval},...
        num2str(starttime.Year),...
        datenum2str(dat2jul(starttime.Month,starttime.Day,starttime.Year),1),...
        datenum2str(dat2jul(finaltime.Month,finaltime.Day,finaltime.Year),1),...
        starthr,endhr,upper(tzlabel));
    end
  else
    figname=customfigname;
  end
  figname2=figdisp(figname,[],[],1,[],'epstopdf');
  pause(0.5)
  [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
  figname=fullfile(savedir,figname);
  pause(.25)
else
  figname='notsaved';
end


