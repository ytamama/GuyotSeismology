function [outputtbl,figurehdl]=vaivseisrms(csvfile1,measval1,frequency,...
  rmoutlier1,csvfile2,measval2,rmoutlier2,starttime,finaltime,tzone,...
  tzlabel,xyh,maxvals,saveplot,savedir)
% 
% Function to directly plot the hourly-averaged, root mean squared (RMS)
% values of a weather phenomenon, recorded by the Vaisala
% WXT530 Weather Station (with the Septentrio PolaRx5 receiver) 
% atop Guyot Hall, Princeton University, with the hourly RMS values
% of seismic data recorded from the same time (made using guyotrmsseishr.m)
% The seismic data are collected by the Nanometrics Meridian 
% PH-120 seismometer in the basement of Guyot Hall.
%
% INPUTS
% csvfile1 : CSV file containing the hourly RMS values of seismic data
% measval1 : What are we plotting, in terms of seismic data?
%            0 for displacement in nm (default)
%            1 for velocity in nm/s 
%            2 for acceleration in nm/(s^2)
% frequency : To what frequencies are we filtering the seismic data?
%             Enter as a four-element vector 
%             Default: [0.75 1.50 5.00 10.00] Hz
% rmoutlier1 : How were the outliers defined and removed from the seismic
%              data, if any?
%
%              0 - Used a percentage limit. For every SAC file, we remove
%                  signals that are at or above this percentile. 
%                  Enter a two number vector, with 0 as the first element
%                  and the percentile limit as the second.
%              1 - Removed outliers that are more than a certain number of
%                  median standard deviations (MAD) away from the median. 
%                  Enter a 2 number vector, with 1 as the first element 
%                  and the # of MADs as the second, like this:
%                  [1 3] - Remove signals at least 3 MADs away from the
%                          median for every SAC file
% 
%              Input an empty array if we didn't remove any signals
%              (default)
% csvfile2 : CSV file containing the hourly RMS values of weather data
% measval2 : Which weather phenomenon are we plotting?
%            1 - Mean wind direction (degrees)
%            2 - Mean wind speed (meters/s; default)
%            3 - Air temperature (celsius)
%            4 - Relative humidity (percent)
%            5 - Air pressure (bars)
%            6 - Rain accumulation (mm)
%            7 - Hail accumulation (# hits)
%            Enter one of these values
% rmoutlier2 : How were the outliers defined and removed from the weather 
%              data, if any?
%
%              0 - Used a percentage limit. For every SAC file, we remove
%                  signals that are at or above this percentile. 
%                  Enter a two number vector, with 0 as the first element
%                  and the percentile limit as the second.
%              1 - Removed outliers that are more than a certain number of
%                  median standard deviations (MAD) away from the median. 
%                  Enter a 2 number vector, with 1 as the first element 
%                  and the # of MADs as the second, like this:
%                  [1 3] - Remove signals at least 3 MADs away from the
%                          median for every SAC file
% 
%              Input an empty array if we didn't remove any signals
%              (default)
% starttime : The time at which we start our time series, entered with the
%             time zone (inclusive)
% finaltime : The time at which we end our time series, entered with the
%             time zone (inclusive) 
% tzone : The MATLAB time zone of the times plotted
%         Default: 'UTC'
% tzlabel : The label characterizing the time zone of the times plotted
% xyh : Do we want to combine the X (East) and Y (North) RMS values 
%       into one horizontal (H) value, and if so, how? Enter as a 2 element
%       vector with the following elements:
%       [xyorh, xyhhow] where
%       xyorh : Do we want to plot horizontal values instead of X or Y? 
%               0 : No (Default)
%               1 : Yes 
%       xyhhow : How do we want to get horizontal values?
%                0 : By using the H column in the CSV file
%                1 : By combining the X and Y RMS values
%       Leave empty if plotting X and Y separately
% maxvals : If we want to constrain the wind speeds of our plot, such that
%           plot the top X values of wind speed or wind speeds above X 
%           m/s, how should we go about doing that? Enter a 2 element
%           vector, where the first element is:
%           0 : Enter a number for the top X wind speeds
%           1 : Enter a wind speed X at or above which we consider
%           And the second element indicates X for either case.
%           Default: an empty vector, signifying we don't want to cut
%           out any values.
%           Note: Only valid if measval2=2
% saveplot : Do we want to save our plot?
%            0 - No (default)
%            1 - Yes 
% savedir : Where do we save our plot? Specify the directory as a string!
%           By default, figure will be saved as an EPS file in your 'EPS' 
%           directory.
%
% OUTPUTS
% outputtbl : A table showing the seismic data, compared with the 
%             weather data during the same time
% figurehdls : The array of figure handle(s) produced
%
% See mstime2sac.m, vaisalats.m, guyotrmsseishr.m 
% 
% Note: 
% Both the seismic RMS and weather RMS data should span the same time, 
% and have their times in the same time zone
% 
% References
% Uses defval.m, in csdms-contrib/slepian_alpha
% Uses figdisp.m, in csdms-contrib/slepian_alpha 
% Uses char(176) to get the degree symbol, obtained from help
% forums on www.mathworks.com
% See guyotweather.m in csdms-contrib/slepian_oscar
%
% Idea of constraining the plots based on wind speed from 
% Groos and Ritter (2009), doi: 10.1111/j.1365-246X.2009.04343.x
% Computing the RMS of seismic data is inspired by SeismoRMS,
% by Thomas Lecocq et. al.,
% https://github.com/ThomasLecocq/SeismoRMS, as well as 
% Lecocq et al., (2020), DOI: 10.1126/science.abd2438
%
% Last Modified by Yuri Tamama, 11/2/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('measval1',0)
defval('frequency',[0.75 1.50 5.00 10.00])
defval('rmoutlier1',[])
defval('measval2',2)
defval('rmoutlier2',[])
defval('tzone','UTC')
defval('xyh',1)
defval('maxvals',[])
defval('saveplot',0)
defval('savedir',pwd)
if isempty(xyh)
  xyorh=0;
else
  if length(xyh)>1
    xyorh=xyh(1);
    xyhhow=xyh(2);
  end
end

% What are we measuring?
% Seismic Data
valunits={'nm';'nm/s';'nm/s^2'};
vallabels={'Displacement';'Velocity';'Acceleration'};
vallblminis={'D';'V';'A'};
valunit=valunits{measval1+1};
vallabel=vallabels{measval1+1};
vallblmini=vallblminis{measval1+1};
% Frequencies
freqstr1=sprintf('%.2f',frequency(1));
freqstr2=sprintf('%.2f',frequency(2));
freqstr3=sprintf('%.2f',frequency(3));
freqstr4=sprintf('%.2f',frequency(4));
% Weather Data
wnameshort={'MWD';'MWS';'AT';'RH';'AP';'RA';'HA'};
wnames={'Mean Wind Direction';'Mean Wind Speed';'Air Temperature';...
  'Relative Humidity';'Air Pressure';'Rain Accumulation';...
  'Hail Accumulation'};
wnameslong={'Mean Wind Direction (degrees)';'Mean Wind Speed (m/s)';...
  'Air Temperature (Celsius)';'Relative Humidity (%)';...
  'Air Pressure (bars)';'Rain Accumulation (mm)';...
  'Hail Accumulation (hits)'};
wunits={'deg';'mps';'deg';'%';'bars';'mm';'hits'};
wnameshort=wnameshort{measval2};
wname=wnames{measval2};
wnamelong=wnameslong{measval2};
wunit=wunits{measval2};

% Load the seismic and weather data
% Seismic
seisdata=readtable(csvfile1,'Delimiter',',');
seistime=seisdata.outputtimes;
seistime=datetime(seistime,'InputFormat','eeee dd-MMM-uuuu HH:mm:ss');
seistime.TimeZone=tzone;
zseis=seisdata.rmsz;
zseis(zseis==-1)=NaN;
if xyorh==1
  if xyhhow==0
    hseis=seisdata.rmsh;
    hseis(hseis==-1)=NaN;
  else
    xvectemp=seisdata.rmsx;
    yvectemp=seisdata.rmsy;
    % Only 'discard' where RMS values could not be found for both
    % X and Y
    xvectemp(xvectemp==-1 && yvectemp==-1)=NaN;
    xvectemp(xvectemp==-1)=0;
    yvectemp(xvectemp==-1 && yvectemp==-1)=NaN;
    yvectemp(yvectemp==-1)=0;
    hseis=sqrt(xvectemp.^2+yvectemp.^2);
  end
else
  xseis=seisdata.rmsx;
  xseis(xseis==-1)=NaN;
  yseis=seisdata.rmsy;
  yseis(yseis==-1)=NaN;
end 
% Weather
wthrdata=readtable(csvfile2,'Delimiter',',');
wthrvals=wthrdata.outputvec;
wthrvals(wthrvals==-1)=NaN;

wtimestrs=wthrdata.outputtimes;
% Convert the times, which consists of strings, to datetime
wthrtime=[];
try
  for i=1:length(wtimestrs)
    nowtime=datetime(wtimestrs{i},'InputFormat','eeee dd-MMM-uuuu HH:mm:ss');
    % The time values are in the inputted time zone!  
    nowtime.TimeZone=tzone;
    wthrtime=[wthrtime; nowtime];  
  end
catch
  wthrtime=wtimestrs;
  wthrtime.TimeZone=tzone;
end

% Cut from start to end time
% Seismic
zseis=zseis(seistime>=starttime & seistime<=finaltime);
if xyorh==1
  hseis=hseis(seistime>=starttime & seistime<=finaltime);
else
  xseis=xseis(seistime>=starttime & seistime<=finaltime);
  yseis=yseis(seistime>=starttime & seistime<=finaltime);
end
% Weather
wthrvals=wthrvals(wthrtime>=starttime & wthrtime<=finaltime);
% Time itself
seistime=seistime(seistime>=starttime & seistime<=finaltime);
wthrtime=wthrtime(wthrtime>=starttime & wthrtime<=finaltime);

% Both vectors ~should~ be the same length, but check just in case
if length(wthrvals)~=length(zseis)
  keyboard
end
% Likewise, check that the times are the same
if seistime~=wthrtime
  keyboard
end


% Generate the table comparing the weather data and the seismic data
% And remove values from the seismic data that are NaN in the weather data, 
% and vice versa
seisvals={};
if xyorh==1
  outputtbl=table(seistime,zseis,hseis,wthrvals);
  outputtbl=outputtbl(~isnan(outputtbl.zseis),:);
  outputtbl=outputtbl(~isnan(outputtbl.hseis),:);
  outputtbl=outputtbl(~isnan(outputtbl.wthrvals),:);
  % If requested, constrain the wind speeds!
  if ~isempty(maxvals) && measval2==2
    if maxvals(1)==0
      outputtbl=sortrows(outputtbl,4,'descend');
      outputtbl=outputtbl(1:maxvals(2),:);
    else
      outputtbl=outputtbl(outputtbl.(4)>=maxvals(2),:);    
    end
  end
  %
  zseis=outputtbl.zseis;
  hseis=outputtbl.hseis;
  seisvals={zseis;hseis};
  components={'Z';'H'};
  plotclrs={'r';[0 .75 .75]};
  wthrvals=outputtbl.wthrvals;
else
  outputtbl=table(seistime,zseis,xseis,yseis,wthrvals);
  outputtbl=outputtbl(~isnan(outputtbl.zseis),:);
  outputtbl=outputtbl(~isnan(outputtbl.yseis),:);
  outputtbl=outputtbl(~isnan(outputtbl.xseis),:);
  outputtbl=outputtbl(~isnan(outputtbl.wthrvals),:);
  % If requested, constrain the wind speeds!
  if ~isempty(maxvals) && measval2==2
    if maxvals(1)==0
      outputtbl=sortrows(outputtbl,4,'descend');
      outputtbl=outputtbl(1:maxvals(2),:);
    else
      outputtbl=outputtbl(outputtbl.(4)>=maxvals(2),:);    
    end
  end
  %
  zseis=outputtbl.zseis;
  yseis=outputtbl.yseis;
  xseis=outputtbl.xseis;
  seisvals={zseis;yseis;xseis};
  components={'Z';'Y';'X'};
  plotclrs={'r';'g';'b'};
  wthrvals=outputtbl.wthrvals;
end


% Plot the seismic data as a function of weather data, in each component!
figurehdl=figure();
figurehdl.Units='normalized';
figurehdl.Position(1)=0.15;
figurehdl.Position(2)=0.15;
figurehdl.Position(3)=0.75;
figurehdl.Position(4)=0.70;

for c=1:length(components)
  sbplot=subplot(1,length(components),c);
  ax=gca;
  sbplot.Position(2)=.15;
  if length(components)>2
    if c==1
      sbplot.Position(1)=.07;
    elseif c==2
      sbplot.Position(1)=.385;    
    else
      sbplot.Position(1)=.7;
    end
    sbplot.Position(3)=.25;  
    sbplot.Position(4)=.5;
  else
    if c==1
      sbplot.Position(1)=.125;    
    else
      sbplot.Position(1)=.55;  
    end
    sbplot.Position(3)=.32;  
    sbplot.Position(4)=.62;
  end
  % Plot the seismic data as a function of weather data
  swplot=plot(wthrvals,seisvals{c},'o');
  hold on
  swplot.HandleVisibility='off';
  swplot.MarkerFaceColor=plotclrs{c};
  swplot.MarkerEdgeColor='k';
  ax.XLim=[0 1.2*max(wthrvals)];
  ax.YLim=[0 1.2*max(seisvals{c})];
  
  % Label the axes
  ax.XLabel.String=wnamelong;
  ax.YLabel.String=sprintf('%s %s (%s)',components{c},vallabel,valunit);
  
  % Add the title for the middle subplot
  if c==2
    titlestr1=sprintf(...
      'Hourly RMS Ground %s (%s) filtered between %s and %s Hz',vallabel,...
      valunit,freqstr2,freqstr3);
    titlestr2=sprintf('vs Hourly RMS %s',wnamelong);
    titlestr3=sprintf('%s to %s (%s)',datestr(starttime),...
      datestr(finaltime),tzlabel);
    if ~isempty(rmoutlier1)
      if rmoutlier1(1)==0
        titlestrrms=sprintf('Seismic: Bottom %g%% per File',rmoutlier1(2));
      else
        titlestrrms=sprintf('Seismic: No signals +/- %.2f MAD from the median',...
          rmoutlier1(2));
      end
    else
      titlestrrms='';
    end
    if ~isempty(rmoutlier2)
      if rmoutlier2(1)==0
        titlestrrmw=sprintf('Weather: Bottom %g%% per File',rmoutlier2(2));
      else
        titlestrrmw=sprintf('Weather: No signals +/- %.2f MAD from the median',...
          rmoutlier2(2));
      end
    else
      titlestrrmw='';
    end
    if ~isempty(maxvals) && measval2==2
      if maxvals(1)==0
        titlestrwmax=sprintf('Top %d Values of Mean Wind Speed',maxvals(2));
      else
        titlestrwmax=sprintf('Mean Wind Speeds at or above %.2f m/s',...
          maxvals(2));  
      end
    else
      titlestrwmax='';
    end
    %
    if ~isempty(titlestrrms) && ~isempty(titlestrrmw)
      if ~isempty(titlestrwmax)
        titlestrs={titlestr1;titlestr2;titlestr3;titlestrrms;...
          titlestrrmw;titlestrwmax};
      else
        titlestrs={titlestr1;titlestr2;titlestr3;titlestrrms;...
          titlestrrmw};
      end
    elseif ~isempty(titlestrrms)
      if ~isempty(titlestrwmax)
        titlestrs={titlestr1;titlestr2;titlestr3;titlestrrms;titlestrwmax};
      else
        titlestrs={titlestr1;titlestr2;titlestr3;titlestrrms};
      end
    elseif ~isempty(titlestrrmw)
      if ~isempty(titlestrwmax)
        titlestrs={titlestr1;titlestr2;titlestr3;titlestrrmw;titlestrwmax};
      else
        titlestrs={titlestr1;titlestr2;titlestr3;titlestrrmw};
      end
    else
      if ~isempty(titlestrwmax)
        titlestrs={titlestr1;titlestr2;titlestr3;titlestrwmax};
      else
        titlestrs={titlestr1;titlestr2;titlestr3};
      end
    end
    ax.Title.String=titlestrs;
    ax.Title.FontSize=9.5;
    % Adjust location if necessary
    if length(components)<3
      ax.Title.Units='normalized';
      ax.Title.Position(1)=-.15;
      ax.Title.Position(2)=1.025;
    end
  end
  
  % Compute the correlation coefficient and make a linear approximation
  % Ground motion as a function of weather
  seismdl=fitlm(wthrvals,seisvals{c});
  % Ordinary or "adjusted" r squared value?
  rsqval=seismdl.Rsquared.Ordinary;
  % Linear fit model
  intval=seismdl.Coefficients.Estimate(1);
  coeffval=seismdl.Coefficients.Estimate(2);
  % P-value of the slope
  pval=seismdl.Coefficients.pValue(2);
  
  % Plot the linear model
  linplot=plot(wthrvals,coeffval*wthrvals+intval);
  linplot.LineWidth=2;
  if c==1
    linplot.Color=[0 0.8 0];
  elseif c==2 
    linplot.Color=[1 0 0];
  elseif c==3
    linplot.Color=[1 0 1];
  end
  lgdstr1=sprintf('R^{2} = %.2f',rsqval);
  plotlgd=legend({lgdstr1},'Location','northeast');
  
end

% Save the plot, if requested
if saveplot==1
  startyr=starttime.Year;
  startjd=dat2jul(starttime.Month,starttime.Day,starttime.Year);
  starthms=sprintf('%s%s%s',datenum2str(starttime.Hour,0),...
    datenum2str(starttime.Minute,0),datenum2str(starttime.Second,0));
  finalyr=finaltime.Year;
  finaljd=dat2jul(finaltime.Month,finaltime.Day,finaltime.Year);
  finalhms=sprintf('%s%s%s',datenum2str(finaltime.Hour,0),...
    datenum2str(finaltime.Minute,0),datenum2str(finaltime.Second,0));
  if ~isempty(rmoutlier1)
    if rmoutlier1(1)==0
      rmseisstr=sprintf('.srm%.2f',rmoutlier1(2));
    else
      rmseisstr=sprintf('.srmMAD%.2f',rmoutlier1(2));  
    end
  else
    rmseisstr='';
  end
  if ~isempty(rmoutlier2)
    if rmoutlier2(1)==0
      rmwthrstr=sprintf('.wrm%.2f',rmoutlier2(2));    
    else
      rmwthrstr=sprintf('.wrmMAD%.2f',rmoutlier2(2));    
    end
  else
    rmwthrstr='';
  end
  if ~isempty(maxvals) && measval2==2
    if maxvals(1)==0
      wmaxstr=sprintf('.top%dmws',maxvals(2));
    else
      wmaxstr=sprintf('.mwsabove%.2f',maxvals(2));
    end
  else
    wmaxstr='';
  end
  figname=sprintf('RMSHR%svs%s.%d.%d.%s.to.%d.%d.%s_%s%s%s%s%s%s%s.eps',...
    vallblmini,wnameshort,startyr,startjd,starthms,finalyr,finaljd,...
    finalhms,freqstr1,freqstr2,freqstr3,freqstr4,rmseisstr,rmwthrstr,...
    wmaxstr);
  figname2=figdisp(figname,[],[],1,[],'epstopdf');
  pause(0.25)
  if ~strcmp(savedir,pwd)
    [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
    figname=fullfile(savedir,figname);
  end
  pause(.5)
  % Convert to PNG
  fignamepng=strcat(figname(1:length(figname)-3),'png');
  [status,cmdout]=system(sprintf('convert -density 250 %s %s',figname,...
    fignamepng));
  pause(.5)
    
end


