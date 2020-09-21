function [rmsplot,axeshdl,figname]=guyotrmsplot(csvfiles,...
  measval,rmstype,yrsplotted,starttime,finaltime,jds,timezone,tzlabel,prclimit,...
  saveplot,savedir,addlegend,frequency,xyh,adjustplot,vertlines,...
  vertlinelabs,customtitle,customxlabel,customfigname,lineclrs,...
  linewdh,linestyls)
%
% Function to plot the RMS displacement, velocity, or acceleration 
% computed by the guyotrms*.m programs in a time series, comparing the
% results from 2017, 2018, 2019, and/or 2020. 
% 
% INPUTS
% csvfiles : A cell array containing the CSV files produced by 
%            the guyotrms*.m codes. The cell array should be 4 elements
%            long, with each element containing the RMS disp/vel/acc
%            computed in a particular year, in order from 2017-2020. 
%            If we do not wish to plot the RMS data of a particular year, 
%            leave enter an empty string in its place.
% measval : What are we plotting the RMS of?
%           0 : Ground displacement (nm)
%           1 : Ground velocity (nm/s)
%           2 : Ground acceleration (nm/s^2)
% rmstype : How were the RMS values averaged?
%           0 : 'daily' : guyotrmsseisday.m, 
%           1 : 'hourly' : guyotrmsseishr.m, 
%           2 : 'qrt' : guyotrmsseisqrt.m, 
% yrsplotted : The years of data that will be plotted and compared to 
%              one another, entered as a vector or a scalar, if inputting
%              1 year
% starttime : From what time do we start our time series? 
%             If plotting 'day' or 'hr' (rmstype=0 or 1), input a 
%             datetime vector in local time. 
%             If plotting 'qrt' (rmstype=2), input a number from 0-23 
%             signifying an hour 
% finaltime : At what time do we end our time series?
%             If plotting 'day' or 'hr' (rmstype=0 or 1), input a 
%             datetime vector in local time. 
%             If plotting 'qrt' (rmstype=2), input a number from 0-23 
%             signifying an hour 
% jds : What is the range of Julian Days being plotted?
%       Example: 1:10
% timezone : The MATLAB time zone of the times plotted
%            Default: 'UTC'
% tzlabel : The label characterizing the time zone of the times plotted
% prclimit : The threshold, given as a percentile, for the values plotted
%            when they were generated in the csv-producing codes
%            (see guyotrmsseisday.m, guyotrmsseishr.m, guyotrmssseisqrt.m 
%            Enter the same threshold number here as was used in those 
%            programs)
%            Default: 100
% saveplot : Do we wish to save our plot?
%            0 : No
%            1 : Yes (Default)
% savedir : Where do we save our plot? Specify the directory as a string!
%           Enter as an empty string if not saving or using the default.
% addlegend : Add a legend in the plot? Yes or no?
%             0 : No 
%             1 : Yes (Default)
% frequency : If plotting seismic data, enter the frequencies at which 
%             the data were filtered to generate the RMS values.
%             Enter an empty vector if not plotting seismic RMS values
% xyh : If plotting seismic data, do we want to combine the X (East) 
%       and Y (North) RMS values into one horizontal value?
%       0 : No (Default)
%       1 : Yes 
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
% lineclrs : A cell array containing the colors for the line plots, in 
%            order of ascending year. The array should be of length 4, 
%            one index per year. If we are omitting data for one year,
%            then the corresponding value in lineclrs should be an 
%            empty string. However, even if a value is entered, the 
%            code will still work. The colors can be entered as strings
%            representing the MATLAB code for the color, or as a 
%            vector containing the RGB triplet.
%            Default: {[0 0.7 0.9];[0 0.85 0];[1 .65 0];[1 0 0.25]}
%
% linewdh : A vector containing the widths of the line plots, in order
%           of ascending year. The vector should be of length 4, one 
%           index per year. If we are omitting data for one year,
%           then the corresponding value in linewdh should be 0.
%           Default: [1 1 1 1.25]
% 
% linestyls : A cell array containing the styles for the line plots, in 
%            order of ascending year. The array should be of length 4, 
%            one index per year. If we are omitting data for one year,
%            then the corresponding value in linestyls should be an 
%            empty string. However, even if a value is entered, the 
%            code will still work. 
%            Default: {'-';'-';'-';'-'}
% 
% 
% NOTE: The length of the data in csv2017, csv2018, csv2019, and csv2020
%       must be the same, and all CSV files must be made from the same
%       guyotrms*.m program!
%
% NOTE 2: starttime and finaltime should be in the same year as the most
%         recent year of data entered
% 
% OUTPUT
% rmsplot : The plot comparing the RMS disp/vel/acc in each of the years
%           that will be considered
% axeshdl : The axis handles for each of the plotted subplots. The first
%           one contains the plot title, and the last one contains the 
%           x axis label
% figname : The name of the figure saved
% 
% References
% Uses defval.m, figdisp.m in csdms-contrib/slepian_alpha 
% 
% Last Modified by Yuri Tamama, 09/18/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Important directories - insert your own!
mcdir=getenv('');

% Set Default Values
defval('timezone','UTC')
defval('saveplot',1);
% Insert your own directory!
defval('savedir','');
defval('addlegend',1);
defval('xyr',0);
defval('adjustplot',0);
defval('vertlines',[]);
defval('vertlinelabs',{});
defval('lineclrs',{[0 0.7 0.9];[0 0.85 0];[1 .65 0];[1 0 0.25]});
defval('linewdh',[1 1 1 1.25]);
defval('linestyls',{'-';'-';'-';'-'})
defval('customtitle','')
defval('customxlabel','')
defval('customfigname','')
defval('prclimit',100)

% Check Inputs for Compatibility
if (rmstype==2) && (~isempty(vertlines))
  fprintf('These settings are not compatible. Exiting function.\n')
  return
end
if (measval>2) && (~isempty(frequency) || xyh>0)
  fprintf('These settings are not compatible. Exiting function.\n')
  return
end   

% Display plotting settings to the user
if xyh==0
  fprintf('We will plot the horizontal components separately.\n')
else
  fprintf('We will combine the horizontal components.\n')
end
fprintf('The following settings will be used to plot the lines.\n')
lineclrstrs={};
for i=1:4
  colorcode=lineclrs{i};
  if length(colorcode)>1
    lineclrstrs=vertcat(lineclrstrs,...
      sprintf('[%g %g %g]',colorcode(1),colorcode(2),colorcode(3)));
  else
    lineclrstrs=vertcat(lineclrstrs,colorcode);
  end
end
fprintf('Line colors: %s (2017); %s (2018); %s (2019); %s (2020)\n',...
  lineclrstrs{1},lineclrstrs{2},lineclrstrs{3},lineclrstrs{4});
fprintf('Unless we are only plotting 1 year.\n')
fprintf('Then, Z will be red, Y will be green, and X will be blue.\n')
fprintf('Or Z will be red and the horizontal will be blue.\n')
fprintf('Line widths: %g (2017); %g (2018); %g (2019); %g (2020)\n',...
  linewdh(1),linewdh(2),linewdh(3),linewdh(4));
fprintf('Line styles: %s (2017); %s (2018); %s (2019); %s (2020)\n',...
  linestyls{1},linestyls{2},linestyls{3},linestyls{4});
fprintf('Any vertical lines will be colored in grayscale.\n');


% Speaking of plotting settings, figure out specific color scheme
% of vertical lines, if any
vertstyls={};
allstyls={'--';':';'-.'};
if ~isempty(vertlines)
  for i=1:length(vertlines)
    stylind=mod(i,3);
    if stylind==0
      stylind=3;
    end
    vertstyls=vertcat(vertstyls,allstyls{stylind});
  end
end

% Figure out units
valunits={'nm';'nm/s';'nm/s^2'};
vallabels={'Displacement';'Velocity';'Acceleration'};
valunit=valunits{measval+1};
vallabel=vallabels{measval+1};
% Insert your own directory!
if strcmp(savedir,fullfile(mcdir,''''))
  if measval==0
    savedir=fullfile('');
  else
    savedir=fullfile('');
  end
end
% Figure out intervals
if rmstype==0
  rmsstr='Daily';
  rmsstr2='D';
elseif rmstype==1
  rmsstr='Hourly';
  rmsstr2='H';
else
  rmsstr='Every 15 Min';
  rmsstr2='Q';
end
% Frequencies
freqstr1=sprintf('%.2f',frequency(1));
freqstr2=sprintf('%.2f',frequency(2));
freqstr3=sprintf('%.2f',frequency(3));
freqstr4=sprintf('%.2f',frequency(4)); 
% Periods
pdstr1=sprintf('%.2f',1/frequency(1));
pdstr2=sprintf('%.2f',1/frequency(2));
pdstr3=sprintf('%.2f',1/frequency(3));
pdstr4=sprintf('%.2f',1/frequency(4));
    

% Load data. We're loading these as cells first, since the
% length of the data for each year within each component might be
% different!
rmstcell=cell(4,1);
rmszcell=cell(4,1);
rmsycell=cell(4,1);
rmsxcell=cell(4,1);
for i=1:4
  if ~isempty(csvfiles{i})
    data=readtable(csvfiles{i},'Delimiter',',');
    % Cell array with datetime entries as strings
    timevec=data.outputtimes;
    % Set up RMS cells to store data and times, as the data might be 
    % different lengths
    timevec=datetime(timevec,'InputFormat','eeee dd-MMM-uuuu HH:mm:ss');
    if rmstype<2
      timevec.TimeZone=timezone;
    else
      timevec.TimeZone='UTC';
    end
    % Enter the times as datetimes! 
    rmstcell{i}=timevec;
    zvec=data.rmsz;
    zvec(zvec==-1)=NaN;
    rmszcell{i}=zvec;
    xvec=data.rmsx;
    xvec(xvec==-1)=NaN;
    rmsxcell{i}=xvec;
    yvec=data.rmsy;
    yvec(yvec==-1)=NaN;
    rmsycell{i}=yvec;
  end
end   
numtimes=length(timevec);


% Now that we have the times and data, align the times so that
% the weekdays match up. 
% Do this in local time, for guyotrmsseisday.m and guyotrmsseishr.m files
% For guyotrmsseisqrt.m files, it is best to, when creating the CSV files 
% themselves, set it up such that the weekdays/weekends are aligned 
% in the first place. 
if rmstype<2 && length(yrsplotted)>1
  [timevector,rmszmat,rmsymat,rmsxmat]=alignrmstimes(...
    rmstcell,yrsplotted,rmszcell,rmsycell,rmsxcell);

% If we don't need to align our times, convert our data to matrix form
else
  rmszmat=zeros(numtimes,4);
  rmsymat=zeros(numtimes,4);
  rmsxmat=zeros(numtimes,4);
  for i=1:4
    if ~isempty(csvfiles{i})  
      % Store data in matrices! We only have one year anyways
      data=readtable(csvfiles{i},'Delimiter',',');
      zvec=data.rmsz;
      zvec(zvec==-1)=NaN;
      rmszmat(:,i)=zvec;
      xvec=data.rmsx;
      xvec(xvec==-1)=NaN;
      rmsxmat(:,i)=xvec;
      yvec=data.rmsy;
      yvec(yvec==-1)=NaN;
      rmsymat(:,i)=yvec;
    end    
  end
  timevector=timevec;
end    

% Narrow down the RMS data to the desired time-period
% Inclusive of start and end time
if rmstype<2
  timevector.TimeZone=timezone;
  [timevector,rmszmat2,rmsymat2,rmsxmat2]=cutrmsdata(timevector,...
    rmszmat,rmsymat,rmsxmat,starttime,finaltime,timezone,rmstype);
else
  timevector.TimeZone='UTC';
  [timevector,rmszmat2,rmsymat2,rmsxmat2]=cutrmsdata(timevector,...
    rmszmat,rmsymat,rmsxmat,starttime,finaltime,'UTC',rmstype);
end
numtimes2=length(timevector);

% Combine the horizontal components, if requested
rmshmat2=zeros(numtimes2,4);
for i=1:4
  if ~isempty(csvfiles{i})
    xvec=rmsxmat2(:,i);
    yvec=rmsymat2(:,i);
    rmshmat2(:,i)=sqrt(xvec.^2+yvec.^2);
  end
end

% Now: convert timevector to local time
timevector.TimeZone=timezone;

% Horizontal axis labels 
% Place ticks on Sundays, for daily and hourly
% For axes with datetime values, the tick values are also datetimes
if rmstype<2
  ticksat=[];
  ticklabels={};
  for i=1:numtimes2
    ticktime=timevector(i);
    ticktime.Format='eeee dd-MMM-uuuu HH:mm:ss';
    % Retrieve the string telling us the weekday
    ticktimestr=cellstr(ticktime);
    ticktimestr=strsplit(ticktimestr{1});
    tickdaystr=ticktimestr{1};
    % Daily averages: tick marks at Saturday and Sunday
    % Hourly averages: tick marks at midnight Saturday and Monday
    if strcmpi('Saturday',tickdaystr)
      if (rmstype==1 && ticktime.Hour==0) || rmstype==0
        ticklabels=vertcat(ticklabels,'Sa');
        ticksat=[ticksat;ticktime];
      end
    elseif strcmpi('Monday',tickdaystr) && rmstype==1
     if ticktime.Hour==0
       ticksat=[ticksat; ticktime];   
       ticklabels=vertcat(ticklabels,'M'); 
     end
    elseif strcmpi('Sunday',tickdaystr) && rmstype==0
      ticksat=[ticksat; ticktime];
      ticklabels=vertcat(ticklabels,'Su');
    end
  end
% Otherwise: place tick marks every hour
else
  ticksat=[];
  ticklabels={};
  tickcount=1;
  for i=1:numtimes2
    if tickcount==1
      ticktime=timevector(i);
      ticksat=[ticksat; ticktime];
      hrstr=datenum2str(ticktime.Hour,0);
      ticklabels=vertcat(ticklabels,sprintf('%s',hrstr));
    end
    if tickcount<4
      tickcount=tickcount+1;
    else
      tickcount=1;
    end
  end
end

% Figure out vertical axis limits
allyrs=[2017 2018 2019 2020];
if xyh==0
  allx=[];
  ally=[];
  allz=[];
  for i=1:4
    if ismember(allyrs(i),yrsplotted)
      allz=[allz; rmszmat2(:,i)];
      ally=[ally; rmsymat2(:,i)];
      allx=[allx; rmsxmat2(:,i)]; 
    end
  end
  dataminx=0.9*min(allx);
  dataminy=0.9*min(ally);
  dataminz=0.9*min(allz);
  datamaxx=1.2*max(allx);
  datamaxy=1.2*max(ally);
  datamaxz=1.2*max(allz);
  datamaxes=[datamaxx; datamaxy; datamaxz];
else
  allh=[];
  allz=[];
  for i=1:4
    if ismember(allyrs(i),yrsplotted)
      allz=[allz; rmszmat2(:,i)];
      allh=[allh; rmshmat2(:,i)];   
    end
  end
  dataminh=0.75*min(allh);
  dataminz=0.75*min(allz);
  datamaxh=1.25*max(allh);
  datamaxz=1.25*max(allz);
  datamaxes=[datamaxh; datamaxz];
end

% Scale our plot, if necessary
plotscale=1;
if max(datamaxes) > 1e6
  valunit(1:2)='mm';
  plotscale=1e6;
elseif max(datamaxes) > 1e3
  plotscale=1e3;
  if measval==0
    valunit='\mum';   
  elseif measval==1
    valunit='\mum/s';    
  else
    valunit='\mum/s^2';    
  end
end
dataminz=dataminz/plotscale;
datamaxz=datamaxz/plotscale;
allz=allz/plotscale;
if xyh==0
  dataminx=dataminx/plotscale;
  dataminy=dataminy/plotscale;
  datamaxx=datamaxx/plotscale;
  datamaxy=datamaxy/plotscale;
  allx=allx/plotscale;
  ally=ally/plotscale;
else
  dataminh=dataminh/plotscale;
  datamaxh=datamaxh/plotscale;
  allh=allh/plotscale;
end


% Plot the data!
axeshdl=[];
rmsplot=figure();
% Z Component
if xyh==0
  subplot(3,1,1)
else
  subplot(2,1,1)
end
plotted1st=0;
for i=1:4
  if ismember(allyrs(i),yrsplotted)
    plotdata=rmszmat2(:,i);
    plotdata=plotdata/plotscale;
    yrline=plot(timevector,plotdata);
    if length(yrsplotted)==1
      yrline.Color=[1 0 0];
    else
      yrline.Color=lineclrs{i};
    end
    yrline.LineStyle=linestyls{i};
    yrline.LineWidth=linewdh(i);
    if plotted1st==0
      hold on
      plotted1st=1;
    end
  end
end
ylim([dataminz datamaxz]);
xlim([timevector(1) timevector(length(timevector))])

% Plot vertical lines, if applicable
if ~isempty(vertlines)
  for i=1:length(vertlines)
    if strcmp(vertstyls{i},'--') || strcmp(vertstyls{i},':')
      line([vertlines(i) vertlines(i)],ylim,'LineStyle',vertstyls{i},...
        'Color',[.55 .55 .55],'LineWidth',1.5);
    else
      line([vertlines(i) vertlines(i)],ylim,'LineStyle',vertstyls{i},...
        'Color',[.55 .55 .55],'LineWidth',1.25);
    end
  end
end
% Add grid lines
nowaxes=gca;
axeshdl=[axeshdl; nowaxes];
nowaxes.XTickMode='manual';
nowaxes.XTick=ticksat;
grid on
% Remove horizontal axis labels
nolabels(nowaxes,1)
% Adjust and label vertical axes
prc0=prctile(allz,0);
if prc0<10
  prc0=round(prc0,2);
elseif prc0<100
  prc0=round(prc0,1);
else
  prc0=round(prc0);
end
prc50=prctile(allz,50);
if prc50<10
  prc50=round(prc50,2);
elseif prc50<100
  prc50=round(prc50,1);
else
  prc50=round(prc50);
end
prc100=max(allz);
if prc100<10
  prc100=round(prc100,2);
elseif prc100<100
  prc100=round(prc100,1);
else
  prc100=round(prc100);
end
if isempty(nowaxes.YTick) || isempty(nowaxes.YTickLabel)
  nowaxes.YTick=unique([prc0; prc50; prc100]);
  nowaxes.YTickLabel={num2str(prc0);num2str(prc50);num2str(prc100)};
end
%
ylabel(sprintf('Z %s',valunit))   

% Title
if isempty(customtitle)
  if isempty(prclimit) || prclimit==100
    if rmstype<2
      titlestr1=sprintf('RMS %s %s',rmsstr,vallabel);
    else
      titlestr1=sprintf('RMS %s %s',vallabel,rmsstr);
    end
  else
    if rmstype<2
      titlestr1=sprintf('RMS %s %s (Bottom %g%% per Hour)',...
        rmsstr,vallabel,prclimit);
    else
      titlestr1=sprintf('RMS %s %s (Bottom %g%% per Hour)',...
        vallabel,rmsstr,prclimit);
    end
  end  
  titlestr2='Recorded at Guyot Hall, Princeton University (PP S0001)';

  % Frequencies
  freqtitle=['[',freqstr1,' {\color{magenta}',freqstr2,' \color{magenta}',...
    freqstr3,'} ',freqstr4,'] Hz'];
  % Periods
  pdtitle=['[',pdstr4,' {\color{magenta}',pdstr3,' \color{magenta}',...
    pdstr2,'} ',pdstr1,'] s'];
  titlestr3=[freqtitle,'  ',pdtitle];
  if xyh==0
    if ~isempty(vertlines) && ~isempty(vertlinelabs)
      titlestrv='Vertical Lines Labeled Chronologically';
      title({titlestr1;titlestr2;titlestr3;titlestrv},'interpreter','tex')
    else
      title({titlestr1;titlestr2;titlestr3},'interpreter','tex')
    end
  else
    titlestr4='H = Horizontal; Z = Vertical';
    if ~isempty(vertlines) && ~isempty(vertlinelabs)
      titlestrv='Vertical Lines Labeled Chronologically';
      title({titlestr1;titlestr2;titlestr3;titlestr4;titlestrv},...
        'interpreter','tex')
    else
      title({titlestr1;titlestr2;titlestr3;titlestr4},'interpreter','tex')
    end
  end
else
  title(customtitle,'interpreter','tex')
end
  
shrink(nowaxes,0.95,.95) 
%
% Plot horizontal components
if xyh==0
  % Y Component
  subplot(3,1,2)
  plotted1st=0;
  for i=1:4
    if ismember(allyrs(i),yrsplotted)
      plotdata=rmsymat2(:,i);
      plotdata=plotdata/plotscale;
      yrline=plot(timevector,plotdata);
      if length(yrsplotted)==1
        yrline.Color=[0 1 0];
      else
        yrline.Color=lineclrs{i};
      end
      yrline.LineStyle=linestyls{i};
      yrline.LineWidth=linewdh(i);
      if plotted1st==0
        hold on
        plotted1st=1;
      end
    end
  end
  xlim([timevector(1) timevector(length(timevector))])
  ylim([dataminy datamaxy]);
  % Plot vertical lines, if applicable
  if ~isempty(vertlines)
    for i=1:length(vertlines)
      if strcmp(vertstyls{i},'--') || strcmp(vertstyls{i},':')
        line([vertlines(i) vertlines(i)],ylim,'LineStyle',vertstyls{i},...
          'Color',[.55 .55 .55],'LineWidth',1.5);
      else
        line([vertlines(i) vertlines(i)],ylim,'LineStyle',vertstyls{i},...
          'Color',[.55 .55 .55],'LineWidth',1.25);
      end
    end
  end
  % Add grid lines, if requested
  nowaxes=gca;
  axeshdl=[axeshdl; nowaxes];
  nowaxes.XTickMode='manual';
  nowaxes.XTick=ticksat;
  grid on
  % Remove horizontal axis label
  nolabels(nowaxes,1) 
  % Add vertical axis ticks and labels
  prc0=prctile(ally,0);
  if prc0<10
    prc0=round(prc0,2);
  elseif prc0<100
    prc0=round(prc0,1);
  else
    prc0=round(prc0);
  end
  prc50=prctile(ally,50);
  if prc50<10
    prc50=round(prc50,2);
  elseif prc50<100
    prc50=round(prc50,1);
  else
    prc50=round(prc50);
  end
  prc100=max(ally);
  if prc100<10
    prc100=round(prc100,2);
  elseif prc100<100
    prc100=round(prc100,1);
  else
    prc100=round(prc100);
  end
  if isempty(nowaxes.YTick) || isempty(nowaxes.YTickLabel)
    nowaxes.YTick=unique([prc0; prc50; prc100]);
    nowaxes.YTickLabel={num2str(prc0);num2str(prc50);num2str(prc100)};
  end
  %
  ylabel({sprintf('%s',vallabel);sprintf('Y (N) %s',valunit)})
  shrink(nowaxes,0.95,.95) 
end
%
% X (or H) Component
legendstrs={};
% X
if xyh==0
  subplot(3,1,3)
  plotted1st=0;
  for i=1:4
    if ismember(allyrs(i),yrsplotted)
      plotdata=rmsxmat2(:,i);
      plotdata=plotdata/plotscale;
      yrline=plot(timevector,plotdata);
      if length(yrsplotted)==1
        yrline.Color=[0 0 1];
      else
        yrline.Color=lineclrs{i};
      end
      yrline.LineStyle=linestyls{i};
      yrline.LineWidth=linewdh(i);
      if plotted1st==0
        hold on
        plotted1st=1;
      end
      legendstrs=vertcat(legendstrs,num2str(allyrs(i)));
    end
  end
  ylim([dataminx datamaxx]); 
  datamax=datamaxx;
% H
else
  subplot(2,1,2)
  plotted1st=0;
  for i=1:4
    if ismember(allyrs(i),yrsplotted)
      plotdata=rmshmat2(:,i);
      plotdata=plotdata/plotscale;
      yrline=plot(timevector,plotdata);
      if length(yrsplotted)==1
        yrline.Color=[0 .75 .75];
      else
        yrline.Color=lineclrs{i};
      end
      yrline.LineStyle=linestyls{i};
      yrline.LineWidth=linewdh(i);
      if plotted1st==0
        hold on
        plotted1st=1;
      end
      legendstrs=vertcat(legendstrs,num2str(allyrs(i)));
    end
  end
  ylim([dataminh datamaxh]);
  datamax=datamaxh;
end    
xlim([timevector(1) timevector(length(timevector))])

% Plot vertical lines, if applicable
if ~isempty(vertlines)
  for i=1:length(vertlines)
    if strcmp(vertstyls{i},'--') || strcmp(vertstyls{i},':')
      line([vertlines(i) vertlines(i)],ylim,'LineStyle',vertstyls{i},...
        'Color',[.55 .55 .55],'LineWidth',1.5);
    else
      line([vertlines(i) vertlines(i)],ylim,'LineStyle',vertstyls{i},...
        'Color',[.55 .55 .55],'LineWidth',1.25);
    end
    if ~isempty(vertlinelabs)  
      legendstrs=vertcat(legendstrs,vertlinelabs{i});
    end
  end
end 
% Add legend if requested
if addlegend==1 
  legend(legendstrs,'Location','northeast','FontSize',6); 
end
% Add grid lines
nowaxes=gca;
axeshdl=[axeshdl; nowaxes];
nowaxes.XTickMode='manual';
nowaxes.XTick=ticksat;
grid on
% Add horizontal axis ticks and labels
nowaxes.XTickLabelMode='manual';
nowaxes.XTickLabel=ticklabels;
monthnames={'Jan';'Feb';'Mar';'Apr';'May';'June';'July';'Aug';'Sept';...
  'Oct';'Nov';'Dec'};
startdate=timevector(1);
startwkday=getweekday(startdate);
finaldate=timevector(numtimes2);
finalwkday=getweekday(finaldate);
if rmstype==1
  datestr1=sprintf('%s:%s:%s %s, %s %d',datenum2str(startdate.Hour,0),...
    datenum2str(startdate.Minute,0),datenum2str(startdate.Second,0),...
    startwkday,monthnames{startdate.Month},startdate.Day);
  datestr2=sprintf('%s:59:59 %s, %s %d',datenum2str(finaldate.Hour,0),...
    finalwkday,monthnames{finaldate.Month},finaldate.Day);
else
  datestr1=sprintf('%s, %s %d',startwkday,monthnames{startdate.Month},...
    startdate.Day);
  datestr2=sprintf('%s, %s %d',finalwkday,monthnames{finaldate.Month},...
    finaldate.Day);
end
if isempty(customxlabel)
  if length(yrsplotted)<2
    xlabel(sprintf('%s to %s %d (%s)',datestr1,datestr2,yrsplotted,tzlabel)); 
  else
    xlabel(sprintf('%s to %s %s (MM/DD from %d)',datestr1,datestr2,...
      tzlabel,yrsplotted(length(yrsplotted))));
  end
else
  xlabel(customxlabel)
end
% Add vertical axis ticks and labels
if xyh==0
  prc0=prctile(allx,0);  
  prc50=prctile(allx,50);
  prc100=max(allx);
else
  prc0=prctile(allh,0);  
  prc50=prctile(allh,50);
  prc100=max(allh);
end
if prc0<10
  prc0=round(prc0,2);
elseif prc0<100
  prc0=round(prc0,1);
else
  prc0=round(prc0);
end
if prc50<10
  prc0=round(prc50,2);
elseif prc50<100
  prc50=round(prc50,1);
else
  prc50=round(prc50);
end
if prc100<10
  prc100=round(prc100,2);
elseif prc100<100
  prc100=round(prc100,1);
else
  prc100=round(prc100); 
end
if isempty(nowaxes.YTick) || isempty(nowaxes.YTickLabel)
  nowaxes.YTick=unique([prc0; prc50; prc100]);
  nowaxes.YTickLabel={num2str(prc0);num2str(prc50);num2str(prc100)};
end
%
% Vertical axis label
if xyh==0
  ylabel(sprintf('X (E) %s',valunit))  
else
  ylabel(sprintf('H %s',valunit))  
end
shrink(nowaxes,0.95,.95) 
% Move plots closer together
serre(axeshdl,1,'down')

% Adjust cosmetics of plot, if desired
if adjustplot==1
  keyboard
end

% Save figure
if saveplot==1
  yearstr=num2str(yrsplotted(1)-2000);
  if length(yrsplotted)>1
    for i=1:length(yrsplotted)-1
      yearstr=strcat(yearstr,num2str(yrsplotted(i+1)-2000));
    end
  end
  if rmstype==2
    starthr=datenum2str(starttime,0);
    endhr=datenum2str(finaltime,0);
  else
    starthr=datenum2str(starttime.Hour,0);
    endhr=datenum2str(finaltime.Hour,0);
  end
  if isempty(customfigname)
    if isempty(prclimit) || prclimit==100
      if xyh==0
        figname=sprintf(...
          'RMS%s%s.XYZ.%s.%sto%s.%sto%s_%s%s%s%s.%s.eps',...
          vallabel(1),rmsstr2,yearstr,datenum2str(jds(1),1),...
          datenum2str(jds(length(jds)),1),starthr,endhr,freqstr1,...
          freqstr2,freqstr3,freqstr4,upper(tzlabel));
      else
        figname=sprintf(...
          'RMS%s%s.HZ.%s.%sto%s.%sto%s_%s%s%s%s.%s.eps',...
          vallabel(1),rmsstr2,yearstr,datenum2str(jds(1),1),...
          datenum2str(jds(length(jds)),1),starthr,endhr,freqstr1,...
          freqstr2,freqstr3,freqstr4,upper(tzlabel));
      end
    else
      if xyh==0
        figname=sprintf(...
          'RMS%s%s.XYZ.%s.%sto%s.%sto%s_%s%s%s%s.%s.btm%g.eps',...
          vallabel(1),rmsstr2,yearstr,datenum2str(jds(1),1),...
          datenum2str(jds(length(jds)),1),starthr,endhr,freqstr1,...
          freqstr2,freqstr3,freqstr4,upper(tzlabel),prclimit);
      else
        figname=sprintf(...
          'RMS%s%s.HZ.%s.%sto%s.%sto%s_%s%s%s%s.%s.btm%g.eps',...
          vallabel(1),rmsstr2,yearstr,datenum2str(jds(1),1),...
          datenum2str(jds(length(jds)),1),starthr,endhr,freqstr1,...
          freqstr2,freqstr3,freqstr4,upper(tzlabel),prclimit);
      end
    end
  else
    figname=customfigname;
  end
  figname2=figdisp(figname,[],[],1,[],'epstopdf');
  [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
  figname=fullfile(savedir,figname);
  % Also have a PNG copy
  pause(1)
  fignamepng=figname;
  fignamepng(length(figname)-2:length(figname))='png';
  pngcmd=sprintf('convert -density 250 %s %s',figname,fignamepng);
  [status,cmdout]=system(pngcmd);
else
  figname='notsaved';
end


