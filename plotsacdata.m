function [seisplot,axeshdl,figname]=...
    plotsacdata(soleplot,sacfiles,plotorder,numsubplots,measval,filterfreqs,...
    stalalo,staloc,stacode,samplefreq,plotall,stalbl,saveplot,...
    savedir,evtornot,rowdata,fastsw,slowsw,labelsw,plotarrivals)
% 
% Function to plot SAC files, recording ambient ground motion or 
% a recorded seismic event
% 
% INPUTS
% soleplot : Is this the only plot going on this figure?
%            0 - No (see stationpair.m)
%            1 - Yes
% sacfiles : A cell array, containing the names of the SAC files to plot.
%            Enter one SAC file per component! Furthermore, all SAC files
%            should be from the same station.
% plotorder : A vector of numbers listing the order in which each 
%             inputted SAC file should be plotted, from top subplot to
%             bottom. 
% numsubplots : How many subplots do we want in total?
% measval : What are we plotting?
%           0 - Displacement (nm, but scaled if needed)
%           1 - Velocity (nm/s)
%           2 - Acceleration (nm/s^2)
% filterfreqs : The frequencies at which the SAC data were filtered, 
%               entered as an array. Enter as an empty array if you 
%               don't know the filtered frequencies.
% stalalo : The latitude-longitude of the station, entered as a vector
%           in that order.
%           Default: [40.34585 -74.65475], the lat-lon of Guyot Hall 
%           from guyotphysics.m.
% staloc : The name of the place/station where the seismic data were
%          recorded. 
%          Default:
%          'Guyot Hall, Princeton University'
% stacode : The network and/or station code for the seismometer 
%           (separate with a period if using both). 
%           Default: 'PP.S0001' (the first Guyot Hall seismometer) 
% samplefreq : How many samples per second were taken by the seismometer?
%              Default: 100
% plotall : Do we want to plot all of the inputted data?
%           0 - No (default)
%           1 - Yes
%           Note: if we're plotting seismograms not associated with any 
%           event, then we have to plot all of the inputted data.
% stalbl : Do we want to add the network + station code to the subplots?
%          0 - No (default)
%          1 - Yes
% saveplot : Do we want to save our plot?
%            0 - No (default)
%            1 - Yes 
% savedir : Where do we save our plot? Specify the directory as a string!
%           By default, figure will be saved as an EPS file in your 'EPS' 
%           directory.
% evtornot : Are we plotting an event or not?
%            0 - No 
%            1 - Yes
% rowdata : One row of IRIS catalog data, created by mcms2evt
%           Columns (left to right): eventID, date of event (string),
%           event latitude, event longitude, depth, event magnitude,
%           geoid distance from station to event (degrees), Great Circle
%           distance from station to event (degrees), and the predicted 
%           travel time of one seismic phase to Guyot Hall (seconds)
% fastsw : An upper threshold for surface wave velocity in km/s, marking 
%          the beginning of the surface wave window
%          Default: 5 km/s
% slowsw : A lower threshold for surface wave velocity in km/s, marking
%          the end of the surface wave window
%          Default: 2.5 km/s
% labelsw : Do we want to label the surface wave speeds?
%           0 - No (default)
%           1 - Yes 
% plotarrivals : Do we want to plot the arriving phases?
%                0 - No, only the first one (Default)
%                1 - Yes, all of them
% 
% OUTPUTS
% seisplot : The figure showing the seismograms of the inputted SAC files
% axeshdl : The axis handles for each of the plotted subplots. The first
%           one contains the plot title, and the last one contains the 
%           x axis label
% figname : The name of the figure saved
% 
% References:
% Uses defval.m, in csdms-contrib/slepian_alpha 
% Uses dat2jul.m and readsac.m, in csdms-contrib/slepian_oscar
% Uses figdisp.m, serre.m, label.m, and nolabels.m, in 
% csdms-contrib/slepian_alpha
% Uses char(176) to get the degree symbol, obtained from help
% forums on www.mathworks.com
% The lat-lon coordinates of Guyot Hall are from guyotphysics.m, in 
% csdms-contrib/slepian_zero
% 
% Last Modified by Yuri Tamama, 08/03/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default values
defval('saveplot',0);
defval('stalalo',[40.34585 -74.65475]);
defval('staloc','Guyot Hall, Princeton University');
defval('stacode','PP.S0001');
defval('samplefreq',100);
defval('fastsw',5);
defval('slowsw',2.5);
defval('labelsw',0);
defval('plotall',0);
defval('evtornot',0);
defval('stalbl',0);
defval('plotarrivals',0);

% Check how many components we have, and their order
components=cell(length(plotorder),1);
numexist=0;
for i=1:3
  if ~isempty(sacfiles{i}) && exist(sacfiles{i})==2
    numexist=numexist+1;
    [~,hdr]=readsac(sacfiles{i});
    channel=hdr.KCMPNM;
    components{i}=channel(3);
  else
    components{i}='';
  end
end
if numexist==0
  disp('Please enter in SAC data! Exiting function...')
  axeshdl=[];
  figname='';
  return
end

% Get data from rowdata
if evtornot==1
  evtid=rowdata.Var1;
  evtlat=rowdata.Var3;
  evtlon=rowdata.Var4;
  evlalo=[evtlat evtlon];
  depth=rowdata.Var5;
  magnitude=rowdata.Var6;
  distdeg=rowdata.Var7;
end  

% Check if we have enough data points to plot the slow surface wave
% speed threshold
if evtornot==1
  for i=1:3
  if ~isempty(sacfiles{i}) && exist(sacfiles{i})==2
    testfile=sacfiles{i};
    break
  end
  end
  [testdata,~]=readsac(testfile,0);
  [~,~,~,distmtr]=irisazimuth(evlalo,stalalo);
  distkm=distmtr/1000;
  maxtime=distkm/slowsw;
  if plotall==0 || labelsw==1
    if (maxtime*samplefreq>length(testdata))  
      disp('Enter more data or choose a faster lower threshold!')
      return
    end
  end
end

% Place the SAC files, and their components, in the desired order
orderedcomps=cell(3,1);
orderedfiles=cell(3,1);
indices=1:3;
sortorder=sort(plotorder);
for i=1:3
  if isempty(sacfiles{i}) || exist(sacfiles{i})==0
    orderedcomps{i}='';
    orderedfiles{i}='';
  else
    index=indices(plotorder==sortorder(i));
    orderedcomps{i}=components{index};
    orderedfiles{i}=sacfiles{index};
  end
end

% Figure out units
if measval==0
  valunit='nm';
  vallabel='Displacement';
  vallabelmini='Disp';
elseif measval==1
  valunit='nm/s';
  vallabel='Velocity';
  vallabelmini='Vel';
else
  valunit='nm/s^2';
  vallabel='Acceleration';
  vallabelmini='Acc';
end

% Strings necessary:
% Frequencies
if ~isempty(filterfreqs)
  freqstr1=sprintf('%g',filterfreqs(1));
  freqstr2=sprintf('%g',filterfreqs(2));
  freqstr3=sprintf('%g',filterfreqs(3));
  freqstr4=sprintf('%g',filterfreqs(4)); 
  % Periods
  pdstr1=sprintf('%.2f',1/filterfreqs(1));
  pdstr2=sprintf('%.2f',1/filterfreqs(2));
  pdstr3=sprintf('%.2f',1/filterfreqs(3));
  pdstr4=sprintf('%.2f',1/filterfreqs(4));
end
% If plotting an event
if evtornot==1
  % Event ID
  evtidstr=num2str(evtid);
end
% Times corresponding to the data
for i=1:3
  sacfile=orderedfiles{i};
  if ~isempty(sacfile) && exist(sacfile)==2
    [~,header]=readsac(orderedfiles{i},0);
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
if evtornot==1
  [backazimuth,~,~,distmtr]=irisazimuth(evlalo,stalalo);
  if plotall==0 
    finaltime=round(distmtr/(1000*slowsw),2);
  end
end
if soleplot==1
  datalims=zeros(numexist,1);
  for c=1:3
    sacfile=orderedfiles{c};
    if isempty(sacfile) || exist(sacfile)==0
      continue;
    end
    [seisdata,~]=readsac(sacfile,0);
    if evtornot==1 && plotall==0
      if finaltime*samplefreq<length(seisdata)
        seisdata=seisdata(1:finaltime*samplefreq);
      end
    end
    datalims(c)=max(abs(seisdata));
  end
  datalim=1.2*max(abs(datalims));
end

% Scale our plot, if necessary
plotscale=1;
if soleplot==1
  if datalim >= 5e6
    valunit(1:2)='mm';
    plotscale=1e6;
    datalim=datalim/plotscale;
  elseif datalim >= 5e3
    plotscale=1e3;
    datalim=datalim/plotscale;
    if measval==0
      valunit='\mum';   
    elseif measval==1
      valunit='\mum/s';    
    else
      valunit='\mum/s^2';    
    end
  end
end

% Go through each of the SAC files (in order!) and make our plot
% Set subplots first
seisplot=figure(gcf);
hold on
for i=1:3
  subplot(numsubplots,1,plotorder(i));
  hold on
end

% Plot data
plotcount=0;
compclrs={'-r';'-g';'-b'};
axeshdl=[];
plotorder=sort(plotorder);
for c=1:3
  component=orderedcomps{c};
  sacfile=orderedfiles{c};
  subplot(numsubplots,1,plotorder(c))
  %
  % Things to do before plotting data (if it exists):
  % Add current axes to axes array
  nowaxes=gca;
  axeshdl=[axeshdl; nowaxes];
  % Adjust plot size
  shrink(nowaxes,0.95,.95) 
  % Remove labels if necessary
  if (plotcount+1)~=numexist
    nolabels(nowaxes,1)
  else
    if plotorder(c)==numsubplots
    else
      nolabels(nowaxes,1)
    end
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
  end
  % Add the x axis label for the bottommost subplot 
  if (plotcount+1)==numexist 
    if plotorder(c)==numsubplots 
      monthnames={'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';...
        'Oct';'Nov';'Dec'};
      fulldate=jul2dat(header.NZYEAR,header.NZJDAY);
      monthname=monthnames{fulldate(1)};
      dayname=fulldate(2);
      % X axis label
      if evtornot==1
        xlabel(sprintf(...
          'Time (s) since %s:%s:%s GMT %s %s %d (Day %s) [Origin Time]',...
          hrstr,minstr,secstr,yrstr,monthname,dayname,jdstr))
      else
        xlabel(sprintf(...
          'Time (s) since %s:%s:%s GMT %s %s %d (Day %s)',...
          hrstr,minstr,secstr,yrstr,monthname,dayname,jdstr))
      end
      % Adjust position of subplots if needed
      if soleplot==1
        serre(axeshdl,1,'down')
      end
    end
  end
  % Add the title, if the current subplot is the top one
  if plotcount==0 && plotorder(c)==1
    if soleplot==1
      if ~isempty(filterfreqs)
        freqtitle=['[',freqstr1,' {\color{magenta}',freqstr2,...
          ' \color{magenta}',freqstr3,'} ',freqstr4,'] Hz'];
        pdtitle=['[',pdstr4,' {\color{magenta}',pdstr3,' \color{magenta}',...
          pdstr2,'} ',pdstr1,'] s'];
        titlestr4=[freqtitle,'  ',pdtitle];
      end
      if evtornot==1
        % Location of event
        locstr=irisevtloc(evtid);
        % Flag if back azimuth is a cardinal direction
        if abs(backazimuth-0)<1 || abs(backazimuth-360)<1
          disp(...
            'The instrument is due South of the event. The P-waves should be stronger in Y.')
        elseif abs(backazimuth-90)<1
          disp(...
            'The instrument is due West of the event. The P-waves should be stronger in X.')
        elseif abs(backazimuth-180)<1
          disp(...
            'The instrument is due North of the event. The P-waves should be stronger in Y.')
        elseif abs(backazimuth-270)<1
          disp(...
            'The instrument is due East of the event. The P-waves should be stronger in X.')
        else
        end
        % Title
        titlestr1=sprintf('IRIS ID %s (%s)',evtidstr,locstr);
        magstr=sprintf('Magnitude %.1f ',magnitude);
        depstr=sprintf(' Depth=%.1f km',depth);
        deltastr=' \Delta';
        deltastr2=sprintf('=%.2f%s ',round(distdeg,2),char(176));
        backazstr=strcat(sprintf(' Back Azimuth %.2f',backazimuth),...
          char(176));
        titlestr2=strcat(magstr,depstr,deltastr,deltastr2,backazstr);
        titlestr3=sprintf('%s at %s (%s)',vallabel,staloc,stacode);
        if labelsw==1
          titlestr5=sprintf(...
            'Upper (%g km/s) and Lower (%g km/s) Surface Wave Speeds in Magenta',...
            fastsw,slowsw);
        end  
        if ~isempty(filterfreqs)
          if labelsw==1
            title({titlestr1;titlestr2;titlestr3;titlestr4;titlestr5},...
              'interpreter','tex')
          else
            title({titlestr1;titlestr2;titlestr3;titlestr4},...
              'interpreter','tex')
          end
        else
          if labelsw==1
            title({titlestr1;titlestr2;titlestr3;titlestr5},...
              'interpreter','tex')
          else
            title({titlestr1;titlestr2;titlestr3},'interpreter','tex') 
          end
        end
      else
        titlestr1=sprintf('Ground %s on %s JD %s %s:00:00',...
          vallabel,yrstr,jdstr,hrstr);
        titlestr2=sprintf('Recorded at %s (%s)',staloc,stacode);
        if ~isempty(filterfreqs)
          title({titlestr1;titlestr2;titlestr4},'interpreter','tex')
        else
          title({titlestr1;titlestr2},'interpreter','tex')
        end
      end
    end
  end
  
  % Now get to plotting the data, if they exist!
  if isempty(sacfile)
    nolabels(nowaxes,2);
    % Move onto the next component if the data don't exist
    continue;
  end
  [seisdata,header]=readsac(sacfile,0);
  finaltime=(length(seisdata)/samplefreq);
  xrange=[0:header.DELTA:finaltime-header.DELTA];
  
  % If cutting out data with surface wave speed threshold
  if evtornot==1 && plotall==0
    finaltime=round(distmtr/(1000*slowsw),3);
    difftimes=abs(xrange-finaltime);
    timeind=1:length(xrange);
    timeindex=timeind(difftimes==min(difftimes));
    finaltimeplot=xrange(timeindex);
    seisdata=seisdata(1:round(finaltimeplot*samplefreq));
    xrange=[0:header.DELTA:finaltimeplot-header.DELTA];
  end
  if evtornot==1 && labelsw==1
    % Plot the surface wave speed thresholds
    % Fast
    fasttime=round(distmtr/(1000*fastsw),3);
    fastline=line([fasttime fasttime],ylim,'Color','m','LineStyle',...
      ':','LineWidth',1.5);
    hold on
    % Slow
    slowtime=round(distmtr/(1000*slowsw),3);
    slowline=line([slowtime slowtime],ylim,'Color','m','LineStyle',...
      ':','LineWidth',1.5);
  end
  seisdata=seisdata/plotscale;
  % Plot the arrival times, if requested, and at least the first arrival
  if evtornot==1
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
    else
      firstphase=phasenames{strcmp(phasenames,'Pdiff') | strcmp(phasenames,'P')};
      firsttime=ttimes(strcmp(phasenames,'Pdiff') | strcmp(phasenames,'P'));
      phaseline=line([firsttime firsttime],ylim,'LineStyle','--',...
        'Color',[0.4 0.4 0.4]);
      phaselines=[phaselines; phaseline];
      phaselbl=text(0.9*firsttime,0.2*max(abs(seisdata)),firstphase,...
        'FontSize',6.5,'Color',[0.4 0.4 0.4]);
    end 
  end  
  
  % Figure out x axis range and limits
  startlim=0;
  endlim=finaltime;
  % Plot the data!
  plot(xrange,seisdata,compclrs{c})
  % Axis limits
  xlim([startlim endlim])
  if soleplot==1
    ylim([-datalim datalim])
  end
  % Adjust vertical line labels and positions
  if labelsw==1 && evtornot==1
    fastline.YData=ylim;
    slowline.YData=ylim;
  end
  if evtornot==1
    for i=1:length(phaselines)
      nowline=phaselines(i);
      nowline.YData=ylim;
    end   
  end
  % Add station name label, if requested, along with components
  if stalbl==1
    stacodelbl=replace(stacode,'.',' ');
    stacodelbl=sprintf('%s %s',component,stacodelbl);
    text(round(0.9*endlim),round(0.9*max(abs(seisdata))),stacodelbl,...
      'FontSize',6.5);
  end
  % Label vertical axis ticks as the largest value in the data for 
  % that component
  nowaxes.YTickMode='manual';
  tickval=round(max(abs(seisdata)));
  nowaxes.YTick=[-1*tickval; 0; tickval];
  tickvalstr=sprintf('%d',tickval);
  nowaxes.YTickLabelMode='manual';
  nowaxes.YTickLabel={sprintf('-%s',tickvalstr);'0';tickvalstr};
  % Add to plot count
  plotcount=plotcount+1;
end


% Save plot
if saveplot==1
  % Specify figure name and save
  if evtornot==1
    if plotarrivals==0
      if ~isempty(filterfreqs)
        if plotall==1
          figname=sprintf('%s.ID%s.%s.%s.%s.%ss_%s%s%s%s.eps',...
            stacode,evtidstr,lower(vallabelmini),yrstr,jdstr,...
            num2str(round(finaltime)),freqstr1,freqstr2,freqstr3,...
            freqstr4);
        else
          figname=sprintf('%s.ID%s.%s.%s.%s.%ss_%s%s%s%s_f%gs%g.eps',...
            stacode,evtidstr,lower(vallabelmini),yrstr,jdstr,...
            num2str(round(finaltime)),freqstr1,freqstr2,freqstr3,...
            freqstr4,fastsw,slowsw);
        end
      else
        if plotall==1
          figname=sprintf('%s.ID%s.%s.%s.%s.%ss.eps',...
            stacode,evtidstr,lower(vallabelmini),yrstr,jdstr,...
            num2str(round(finaltime)));
        else
          figname=sprintf('%s.ID%s.%s.%s.%s.%ss_f%gs%g.eps',...
            stacode,evtidstr,lower(vallabelmini),yrstr,jdstr,...
            num2str(round(finaltime)),fastsw,slowsw);
        end
      end
    else
      if ~isempty(filterfreqs)
        if plotall==1
          figname=sprintf('%s.ID%s.%s.%s.%s.%ss_%s%s%s%s_pp.eps',...
            stacode,evtidstr,lower(vallabelmini),yrstr,jdstr,...
            num2str(round(finaltime)),freqstr1,freqstr2,freqstr3,...
            freqstr4);
        else
          figname=sprintf('%s.ID%s.%s.%s.%s.%ss_%s%s%s%s_f%gs%g_pp.eps',...
            stacode,evtidstr,lower(vallabelmini),yrstr,jdstr,...
            num2str(round(finaltime)),freqstr1,freqstr2,freqstr3,...
            freqstr4,fastsw,slowsw);
        end
      else
        if plotall==1
          figname=sprintf('%s.ID%s.%s.%s.%s.%ss_pp.eps',...
            stacode,evtidstr,lower(vallabelmini),yrstr,jdstr,...
            num2str(round(finaltime)));
        else
          figname=sprintf('%s.ID%s.%s.%s.%s.%ss_f%gs%g_pp.eps',...
            stacode,evtidstr,lower(vallabelmini),yrstr,jdstr,...
            num2str(round(finaltime)),fastsw,slowsw);
        end
      end
    end
  else
    if ~isempty(filterfreqs)
      figname=sprintf('%s.%s.%s.%s.%ss_%s%s%s%s.eps',stacode,...
        yrstr,jdstr,lower(vallabelmini),num2str(round(finaltime)),...
        freqstr1,freqstr2,freqstr3,freqstr4);
    else
      figname=sprintf('%s.%s.%s.%s.%ss.eps',stacode,...
        yrstr,jdstr,lower(vallabelmini),num2str(round(finaltime)));
    end
  end
  figname2=figdisp(figname,[],[],1,[],'epstopdf');
  if ~isempty(savedir)
    [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
    figname=fullfile(savedir,figname);
  else
    figname=figname2;
  end
else
  figname='notsaved';
end

