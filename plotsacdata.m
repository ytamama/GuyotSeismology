function [seisplot,axeshdl,figname]=...
    plotsacdata(soleplot,sacfiles,measval,freqinfo,corder,spinfo,...
    stainfo,rmoutlier,stalbl,saveplot,savedir,evtinfo,timeinfo,addlgd)
% 
% Function to plot SAC files
% 
% INPUTS
% soleplot : Is this the only plot going on this figure?
%            0 - No 
%            1 - Yes
% sacfiles : A cell array, containing the names of the SAC files to plot
%            in the order in which we want to plot them!
%            Enter one SAC file per component. Furthermore, all SAC files
%            should be from the same station.
% measval : What are we plotting?
%           0 - Displacement (nm, but scaled if needed)
%           1 - Velocity (nm/s)
%           2 - Acceleration (nm/s^2)
% freqinfo : In what frequencies did we filter our SAC files?
%            Enter as a cell array, whose length is equal to the number of
%            SAC file "sets" we entered. For example, suppose we want 
%            to plot SAC data in the Z, Y, and X directions, filtered to
%            frequencies A, and SAC data in the same directions, filtered
%            to frequencies B. If we plot the files filtered through A
%            first, then for 'freqinfo', we input a cell array where 
%            the first element is the four-element vector containing
%            frequency range A. The second element is the four-element
%            vector containing frequency range B. 
%             
%            If you don't know the filtered frequencies, enter an empty
%            cell array. 
%
% corder : The order in which we enter and plot our components, from top 
%          subplot to bottom, entered as a cell array with the names of 
%          those components. These components should be in the same order 
%          as we entered our SAC files
%          Example: {'Z';'T';'R'}
% xyh : If inputting SAC files in the X and Y directions, do we wish to 
%       combine them into 1 horizontal direction?
%       0 : No (Default)
%       1 : Yes 
%       This option is valid only if we input SAC files in the X and Y 
%       directions, or R and T. 
%       Tentative future input argument
% spinfo : Information about how to format our subplots, entered as a 
%          3 element cell array like so:
%          {numsp; sporder; plotclrs} where
%          numsp : Number of subplots
%          sporder : On which subplots do we plot our data? Enter in the 
%                    same order as our SAC files to plot
%          plotclrs : In what color should we plot each component of data?
%                     Enter in the same order as our SAC files to plot
%
% stainfo : Information relevant to the location of the seismic station,
%           entered as a cell array like so:
%           {stalalo; staloc; stacode; samplefreq} where
%           stalalo : The latitude-longitude of the station, entered as a 
%                     vector in that order. 
%                     Default: [40.34585 -74.65475]
%           staloc : The name of the place/station where the seismic data 
%                    were recorded.
%                    Default : 'Guyot Hall, Princeton University'
%           stacode : The network and station code for the 
%                     seismometer, separated by a period
%                     Default : 'PP.S0001'
%           samplefreq : The sampling frequency of the seismometer
%                        Default: 100 samples/sec
%           Enter any of these as an empty array if we need to use the 
%           defaults
% rmoutlier :  How do we define and remove outliers for the values plotted?
%
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
% stalbl : Do we want to add the network + station code to the subplots?
%          0 - No (default)
%          1 - Yes
% saveplot : Do we want to save our plot?
%            0 - No (default)
%            1 - Yes 
% savedir : Where do we save our plot? Specify the directory as a string!
%           By default, figure will be saved in your current working
%           directory
% evtinfo : Information about the type of event we're plotting, entered as 
%           a 3 element cell array. The first element tells what event 
%           we're plotting, where: 
%           0 - Nothing, just noise (default)
%           1 - Earthquake
%           2 - Campus blast
%           
%           The 2nd and 3rd elements are left empty unless we plot an 
%           earthquake. For the 2nd element, we input a 1 row-table with
%           the following columns, from left to right: 
% 
%           eventID, date of event (string), event latitude, 
%           event longitude, depth, event magnitude, geoid distance from 
%           station to event (degrees), Great Circle distance from 
%           station to event (degrees), and the predicted travel time of
%           one seismic phase to Guyot Hall (seconds)
% 
%           For the 3rd element, we indicate whether we want to plot the 
%           arrivals of seismic phases:
%           0 - No
%           1 - Yes
%
% timeinfo : How are we defining our plotting interval? Enter these
%            parameters as a cell array, with the following format:
%            {timeorsw; intend; plotsw} where:
% 
%            timeorsw : Whether we are defining our plotting time interval
%                       by a time span or surface wave velocities
%                       0 - Plot everything in the SAC files inputted
%                       1 - Define a time span (s)
%                       2 - Define surface wave velocities (km/s)
%            intend : The time at which to cut our time interval, in
%                     seconds, if we set timeorsw=1. 
%                    
%                     OR: A two-element vector with the upper and lower 
%                     thresholds, in that order, of the surface wave
%                     velocities if we set timeorsw=2
%            plotsw : Do we want to label the surface wave speeds?
%                     0 - No
%                     1 - Yes
% 
%            Enter a 3 element cell array, but leave any of these empty
%            (or set the first element equal to 0) if we don't want to
%            define a time span
% addlgd : Do we want to add a legend?
%          0 : No [default]
%          1 : Yes
% 
% OUTPUTS
% seisplot : The figure showing the seismograms of the inputted SAC files
% axeshdl : The axis handles for each of the plotted subplots. The first
%           one contains the plot title, and the last one contains the 
%           x axis label
% figname : The name of the figure saved
% 
% References:
% Uses jul2dat.m, readsac.m, in csdms-contrib/slepian_oscar
% Uses figdisp.m, serre.m, nolabels.m, defval.m, shrink.m in 
% csdms-contrib/slepian_alpha
% Uses char(176) to get the degree symbol, obtained from help
% forums on www.mathworks.com
% The lat-lon coordinates of Guyot Hall are from guyotphysics.m, in 
% csdms-contrib/slepian_zero
% Uses IRIS's distance-azimuth and traveltime web services
% (see irisazimuth.m, iristtimes.m)
% 
% For more on SAC, see Helffrich et al., (2013), The Seismic Analysis 
% Code: a Primer and User's Guide
% 
% Last Modified by Yuri Tamama, 12/27/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values and get the values of our variables
defval('saveplot',0)
defval('measval',0)
defval('freqinfo',{})
defval('xyh',0)
% Subplot information
numsp=spinfo{1};
sporder=spinfo{2};
plotclrs=spinfo{3};
% Station information
stalalo=stainfo{1};
staloc=stainfo{2};
stacode=stainfo{3};
samplefreq=stainfo{4};
if isempty(stalalo)
  stalalo=[40.34585 -74.65475];
end
if isempty(staloc)
  staloc='Guyot Hall, Princeton University';
end
if isempty(stacode)
  stacode='PP.S0001'; 
end
if isempty(samplefreq)
  samplefreq=100;
end
defval('rmoutlier',[])
defval('stalbl',0)
defval('saveplot',0)
defval('savedir',pwd)
evttype=evtinfo{1};
if evttype==1
  rowdata=evtinfo{2};
  plotarrivals=evtinfo{3};
end
timeorsw=timeinfo{1};
defval('addlgd',0)

% Match up SAC file to component, and check which components we are missing
% Also check to see if we have the horizontal components we need, if 
% combining
components=cell(length(corder),1);
numexist=0;
xycount=0;
rtcount=0;
for i=1:length(corder)
  if ~isempty(sacfiles{i}) && exist(sacfiles{i})==2
    numexist=numexist+1;
    components{i}=corder{i};
  else
    components{i}='';
  end
end
if numexist==0
  disp('Please enter in SAC data! Exiting function...')
  axeshdl=[];
  seisplot=[];
  figname='';
  return
end

% Get data from rowdata
if evttype==1
  evtid=rowdata.IRISID;
  evtidstr=num2str(evtid);
  evtlat=rowdata.Latitude;
  evtlon=rowdata.Longitude;
  evlalo=[evtlat evtlon];
  depth=rowdata.Depth;
  magnitude=rowdata.Magnitude;
  distdeg=rowdata.DistanceTT;
  if distdeg<0
    % Use the distaz approximation if we have "airquakes"
    distdeg=rowdata.DistanceAZ;
  end
  % We need the back azimuth
  [backazimuth,~,~,~]=irisazimuth(evlalo,stalalo);
end  

% Check if we need to cut the data we plot, and if so, by how much?
if timeorsw>0
  % Time threshold
  if timeorsw==1
    finaltime=timeinfo{2};
  % Surface wave speed threshold (assume we're plotting an earthquake)
  else
    plotsw=timeinfo{3};
    swspeed=timeinfo{2};
    fastsw=swspeed{1};
    slowsw=swspeed{2};
    for i=1:length(corder)
      if ~isempty(sacfiles{i}) && exist(sacfiles{i})==2
        testfile=sacfiles{i};
        break
      end
    end
    % Define approximately where we end our time series 
    [backazimuth,~,~,distmtr]=irisazimuth(evlalo,stalalo);
    distkm=distmtr/1000;
    finaltime=round(distkm/slowsw,2);
  end  
end    

% Figure out units
valunits={'nm';'nm/s';'nm/s^2'};
valunit=valunits{measval+1};
vallabels={'Disp';'Vel';'Acc'};
vallabel=vallabels{measval+1};


% Strings necessary:
% Frequencies
freqstrs='';
if ~isempty(freqinfo)
  for f=1:length(freqinfo)
    frequency=freqinfo{f};
    freqstrs=sprintf('%s%.2f%.2f',freqstrs,frequency(2),frequency(3));
    if f<length(freqinfo)
      freqstrs=strcat(freqstrs,'_');
    end    
  end    
end    
% Dates/times corresponding to the data
for i=1:length(corder)
  sacfile=sacfiles{i};
  if ~isempty(sacfile) && exist(sacfile)==2
    [~,header]=readsac(sacfiles{i},0);
    break
  end
end
yrstr=num2str(header.NZYEAR);  
jdstr=datenum2str(header.NZJDAY,1);
hrstr=datenum2str(header.NZHOUR,0);
minstr=datenum2str(header.NZMIN,0);
hdrsec=round(header.NZSEC+(header.NZMSEC/100),2);
secstr=datenum2str(hdrsec,0);

% Go through the available data to see what we should set as the 
% vertical axis limits, if needed
if soleplot==1
  datalims=zeros(numexist,1);
  for c=1:length(corder)
    sacfile=sacfiles{c};
    if isempty(sacfile) || exist(sacfile)==0
      continue;
    end
    [seisdata,~]=readsac(sacfile,0);
    if timeorsw>0
      if finaltime*samplefreq<length(seisdata)
        seisdata=seisdata(1:finaltime*samplefreq);
      end
    end
    % How should we remove outliers?
    if ~isempty(rmoutlier)
      if rmoutlier(1)==0
        topprc=prctile(abs(seisdata),rmoutlier(2));    
        % Cut out signals at or above the inputted percentile
        seisdata(abs(seisdata)>=topprc)=NaN;
      else
        seismad=mad(seisdata,1);
        % More than # MADs from the median 
        lowlim=median(seisdata)-seismad*rmoutlier(2);
        highlim=median(seisdata)+seismad*rmoutlier(2);
        seisdata(seisdata<lowlim)=NaN;
        seisdata(seisdata>highlim)=NaN;
      end
    end
    datalims(c)=max(abs(seisdata));
  end
  datalim=1.25*max(abs(datalims));
end

% Scale our plot, if necessary
plotscale=1;
if soleplot==1
  if datalim > 1e6
    valunit(1:2)='mm';
    plotscale=1e6;
    datalim=datalim/plotscale;
  elseif datalim > 1e3
    plotscale=1e3;
    datalim=datalim/plotscale;
    valunits={'\mum';'\mum/s';'\mum/s^2'};
    valunit=valunits{measval+1};
  end
end

% Go through each of the SAC files and make our plot
% Set subplots first
seisplot=figure(gcf);
hold on
spuniq=unique(sporder);
for i=1:length(spuniq)
  subplot(numsp,1,spuniq(i));
  hold on
end

% Plot data
legendstrs={};
plotcount=0;
axeshdl=[];
madelgd=0;
% Indices 1 through the number of SAC files
spind=1:length(sporder);
compstr='';
for c=1:length(spuniq)
  component=components{c};
  compstr=strcat(compstr,component);
  nowsp=spuniq(c);
  nowinds=spind(sporder==nowsp);
  subplot(numsp,1,sporder(c))
  % Things to do before plotting data
  % Add current axes to axes array
  nowaxes=gca;
  axeshdl=[axeshdl; nowaxes];  
  % Adjust plot size
  shrink(nowaxes,0.95,.85) 
  % Remove labels if necessary
  if (plotcount+1)~=numsp
    nolabels(nowaxes,1)
  end
  % Add vertical axis label
  if ~isempty(component)
    if strcmpi(component,'Z')
      ylabel(sprintf('%s %s',component,valunit))
    elseif strcmpi(component,'Y')
      ylabel(sprintf('%s (N) %s',component,valunit))
    elseif strcmpi(component,'X')
      ylabel(sprintf('%s (E) %s',component,valunit))
    else 
      ylabel(sprintf('%s %s',component,valunit))
    end
    nowaxes.YLabel.FontSize=8;
  end
  % Add the x axis label for the bottommost subplot
  if c==numsp 
    monthnames={'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';...
      'Oct';'Nov';'Dec'};
    fulldate=jul2dat(header.NZYEAR,header.NZJDAY);
    monthname=monthnames{fulldate(1)};
    dayname=fulldate(2);
    % X axis label
    if evttype==1
      xlabel(sprintf(...
        'Time (s) since %s:%s:%s GMT %s %s %d (Day %s) [Origin Time]',...
        hrstr,minstr,secstr,yrstr,monthname,dayname,jdstr))
    else
      xlabel(sprintf(...
        'Time (s) since %s:%s:%s GMT %s %s %d (Day %s)',...
        hrstr,minstr,secstr,yrstr,monthname,dayname,jdstr))
    end
    nowaxes.XLabel.FontSize=8.5;
    % Adjust position of subplots if needed
    if soleplot==1
      serre(axeshdl,1,'down')
    end
  end
  % Add the title, if the current subplot is the top one
  if plotcount==0 && c==1
    if soleplot==1
      if evttype==1
        % Earthquake title
        evtinfo={freqinfo;measval;evtid;evlalo;magnitude;depth;...
          staloc;stacode;stalalo;distdeg;backazimuth;[];[];rmoutlier};
        titlestrs=sacplottitle(1,evtinfo);    
        if timeorsw==2
          if plotsw==1
            % If we also plot surface wave speeds
            evtinfo={freqinfo;measval;evtid;evlalo;magnitude;depth;...
              staloc;stacode;stalalo;distdeg;backazimuth;fastsw;slowsw;...
              rmoutlier};
            titlestrs=sacplottitle(1,evtinfo);
          end
        end
      else
        evtinfo={freqinfo;measval;header;stacode;staloc;rmoutlier};
        if evttype==2
          titlestrs=sacplottitle(2,evtinfo);
        else
          titlestrs=sacplottitle(0,evtinfo);
        end
      end
      title(titlestrs,'interpreter','tex')
      nowaxes.Title.FontSize=8.5;
    end
  end
  
  % Now get to plotting the data, if they exist!
  allempty=0;
  plottedsw=0;
  plottedph=0;
  alldata=[];
  for s=1:length(nowinds)
    nowind=nowinds(s);  
    sacfile=sacfiles{nowind};
    if exist(sacfile)~=2
      allempty=allempty+1;
      if allempty==length(nowinds)
        nolabels(nowaxes,2)
      end 
      % Move onto the next component if data do not exist
      continue
    end
    
    % Make a legend based on what frequency we are plotting
    if madelgd==0 && ~isempty(freqinfo)
      frequency=freqinfo{s};
      legendstrs=vertcat(legendstrs,sprintf('%.2f-%.2f Hz',...
        frequency(2),frequency(3)));
    end  
    
    [seisdata,header]=readsac(sacfile,0);
    timestep=round(header.DELTA,3);
    % Plot all the data or no?
    if timeorsw==0
      finaltime=(length(seisdata)/samplefreq)-(1/samplefreq);
      xrange=[0:timestep:finaltime];
    else
      xrange=[0:timestep:finaltime];
      seisdata=seisdata(1:length(xrange));
    end
    
    % Cut out the outliers
    if ~isempty(rmoutlier)
      if rmoutlier(1)==0
        topprc=prctile(abs(seisdata),rmoutlier(2));    
        % Cut out signals at or above the inputted percentile
        seisdata(abs(seisdata)>=topprc)=NaN;
      else
        seismad=mad(seisdata,1);
        % More than # MADs from the median 
        lowlim=median(seisdata)-seismad*rmoutlier(2);
        highlim=median(seisdata)+seismad*rmoutlier(2);
        seisdata(seisdata<lowlim)=NaN;
        seisdata(seisdata>highlim)=NaN;
      end
    end
    % Scale the remaining data
    seisdata=seisdata/plotscale;
    alldata=vertcat(alldata,seisdata);
    
    % Plot the surface wave speed thresholds
    if timeorsw==2 && plottedsw==0
      if plotsw==1
        % Fast
        fasttime=round(distkm/fastsw,3);
        fastline=line([fasttime fasttime],ylim,'Color','m','LineStyle',...
          ':','LineWidth',1.5);
        hold on
        % Slow
        slowtime=round(distkm/slowsw,3);
        slowline=line([slowtime slowtime],ylim,'Color','m','LineStyle',...
          ':','LineWidth',1.5);
      end
      plottedsw=1;
    end
    
    % Plot seismic phase arrivals, if requested
    if evttype==1 && plottedph==0
      ttimetbl=iristtimes(evlalo,depth,'',stalalo);
      phasenames=ttimetbl.phases;
      ttimes=ttimetbl.ttimes;
      phaselines=[];
      if plotarrivals==1
        numphases=length(ttimes);
        halfphase=floor(numphases/2);
        for i=1:numphases
          phase=phasenames{i};
          ttime=ttimes(i);
          if ttime<=xrange(length(xrange))
            phaseline=line([ttime ttime],ylim,'LineStyle','--','Color',...
              [0.4 0.4 0.4]);
            phaselines=[phaselines; phaseline];
            if i<=halfphase
              phaselbl=text(ttime+4,...
                round(max(abs(seisdata))*((halfphase-i)/(halfphase+2))),...
                phase,'FontSize',6.5,'Color',[0.4 0.4 0.4]);
            else
              phaselbl=text(ttime+4,...
                round(-max(abs(seisdata))*((i-halfphase)/(halfphase+2))),...
                phase,'FontSize',6.5,'Color',[0.4 0.4 0.4]);
            end
          end
        end
      end
      plottedph=1;
    end 
    
    % Plot the data
    dataplot=plot(xrange,seisdata);
    dataplot.Color=plotclrs{nowind};
    if madelgd==1
      dataplot.HandleVisibility='off';  
    end
    % Axis limits
    if soleplot==1
      ylim([-datalim datalim])
    end
    xlim([xrange(1) xrange(length(xrange))])
  end
  
  if addlgd==1
    if ~isempty(legendstrs) && madelgd==0
      % Add the legend
      plotlgd=legend(legendstrs,'Location','best');
      plotlgd.FontSize=6;
      keyboard
      madelgd=1;
    end
  end
  
  % Adjust vertical line labels and positions
  if timeorsw==2
    if plotsw==1
      fastline.YData=ylim;
      slowline.YData=ylim;
    end
  end
  if evttype==1
    for i=1:length(phaselines)
      nowline=phaselines(i);
      nowline.YData=ylim;
    end   
  end
  % Add station name label, if requested, along with components
  if stalbl==1
    stacodelbl=replace(stacode,'.',' ');
    stacodelbl=sprintf('%s %s',component,stacodelbl);
    text(round(0.9*endlim),round(0.9*max(abs(alldata))),stacodelbl,...
      'FontSize',6.5);
  end
  % Label vertical axis ticks as the largest value in the data for 
  % that component
  nowaxes.YTickMode='manual';
  tickval=max(abs(alldata));
  if tickval<100
    tickval=round(tickval,2);
  elseif tickval<1000
    tickval=round(tickval,1);
  else
    tickval=round(tickval);
  end
  nowaxes.YTick=[-tickval; 0; tickval];
  % Add to plot count
  plotcount=plotcount+1;
end


% Save plot
% Note: we technically only need the 2nd and 3rd freqlimits values 
if saveplot==1
  if ~isempty(rmoutlier)  
    rmstr=sprintf('.rm%d.%f',rmoutlier(1),rmoutlier(2));
  else
    rmstr='';
  end
  % Specify figure name and save
  % Earthquake
  if evttype==1
    if plotarrivals==0
      if timeorsw<2
        figname=sprintf('%s.%s.ID%s.%s.%s.%s.%ss_%s%s.eps',...
          stacode,compstr,evtidstr,vallabel(1),yrstr,jdstr,...
          num2str(round(finaltime)),freqstrs,rmstr);
      else
        figname=sprintf('%s.%s.ID%s.%s.%s.%s.%ss_%s_f%gs%g%s.eps',...
          stacode,compstr,evtidstr,vallabel(1),yrstr,jdstr,...
          num2str(round(finaltime)),freqstrs,fastsw,slowsw,rmstr);
      end
    else
      if timeorsw<2
        figname=sprintf('%s.%s.ID%s.%s.%s.%s.%ss_%s_pp%s.eps',...
          stacode,compstr,evtidstr,vallabel(1),yrstr,jdstr,...
          num2str(round(finaltime)),freqstrs,rmstr);
      else
        figname=sprintf('%s.%s.ID%s.%s.%s.%s.%ss_%s_f%gs%g_pp%s.eps',...
          stacode,compstr,evtidstr,vallabel(1),yrstr,jdstr,...
          num2str(round(finaltime)),freqstrs,fastsw,slowsw,rmstr);
      end
    end
  % Noise
  elseif evttype==0
    figname=sprintf('%s.%s.%s.%s.%s%s%s.%s.%ss_%s%s.eps',stacode,...
      compstr,yrstr,jdstr,hrstr,minstr,secstr,vallabel(1),...
      num2str(round(finaltime)),freqstrs,rmstr);
  % Campus blast
  else
    figname=sprintf('CB.%s.%s.%s.%s.%s%s%s.%s.%ss_%s%s.eps',stacode,...
      compstr,yrstr,jdstr,hrstr,minstr,secstr,vallabel(1),...
      num2str(round(finaltime)),freqstrs,rmstr);
  end
  figname2=figdisp(figname,[],[],1,[],'epstopdf');
  pause(0.5)
  if ~isempty(savedir)
    [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
    figname=fullfile(savedir,figname);
  else
    figname=figname2;
  end
  pause(0.5)
  % Make a PNG Version
  fignamepng=strcat(figname(1:length(figname)-3),'png');
  [status,cmdout]=system(sprintf('convert -density 250 %s %s',figname,...
    fignamepng));
  pause(0.5)
else
  figname='notsaved';
end

