function [seisplot,figname]=...
    stationpair(sacfiles1,sacfiles2,plotorder1,plotorder2,numsubplots,...
    measval,filterfreqs,stalalo1,staloc1,stacode1,samplefreq1,stalalo2,...
    staloc2,stacode2,samplefreq2,evtid,magnitude,evlalo,depth,swvel,...
    saveplot,savedir,phasenames1,ttimes1,phasenames2,ttimes2)
% 
% Function to plot the seismograms of one event, recorded on two stations,
% onto one figure. 
% 
% INPUTS
% sacfiles1 : A cell array containing the names of the SAC files from 
%             the first station. Enter one SAC file per directional
%             component!
% sacfiles2 : A cell array containing the names of the SAC files from 
%             the second station. Enter one SAC file per directional
%             component!
% plotorder1 : A vector of numbers listing the order in which each 
%              inputted SAC file from the first station should be plotted, 
%              from top subplot to bottom. 
% plotorder2 : A vector of numbers listing the order in which each 
%              inputted SAC file from the first station should be plotted, 
%              from top subplot to bottom. If plotorder1 and plotorder2 
%              share values, then the corresponding SAC files will 
%              be plotted on the same subplot, but with a vertical offset.
% numsubplots : How many total subplots do we want? This number should
%               equal the number of unique numbers in plotorder1 and 
%               plotorder 2.
% measval : What are we plotting?
%           0 - Displacement (nm, but scaled if needed)
%           1 - Velocity (nm/s)
%           2 - Acceleration (nm/s^2)
% filterfreqs : The frequencies at which the SAC data were filtered, 
%               entered as an array. Enter as an empty array if you 
%               don't know the filtered frequencies.
% stalalo1 : The latitude-longitude of the first station, entered as 
%            a vector in that order.
%            Enter [] if using the default: [40.34585 -74.65475], the
%            lat-lon of Guyot Hall from guyotphysics.m.
% staloc1 : The name of the first place/station where the seismic 
%           data were recorded. 
%           Enter an empty string if using the default:
%           'Guyot Hall, Princeton University'
% stacode1 : The network and/or station code for the first seismometer 
%            (separate with a period if using both). 
%            Enter an empty string if using the code for 
%            the first Guyot Hall seismometer
% samplefreq1 : How many samples per second were taken by the first 
%               seismometer?
%               Default if empty: 100
% stalalo2 : The latitude-longitude of the second station, entered as 
%            a vector in that order.
%            Default if empty: [40.34585 -74.65475], the
%            lat-lon of Guyot Hall from guyotphysics.m.
% staloc2 : The name of the second place/station where the seismic 
%           data were recorded. 
%           Enter an empty string if using the default:
%           'Guyot Hall, Princeton University'
% stacode2 : The network and/or station code for the second seismometer 
%            (separate with a period if using both). 
%            Enter an empty string if using the code for 
%            the second Guyot Hall seismometer
% samplefreq2 : How many samples per second were taken by the second
%               seismometer?
%               Default if empty: 100
% evtid : The event ID, as recorded in the IRIS catalog
% magnitude : The magnitude of the event being recorded
% evlalo : The latitude and longitude of the event, entered as a vector
%           with that order.
% depth : The depth, in km, of the event, as recorded in the IRIS catalog
% swvel : A surface wave velocity, defining the end of the range of 
%         times we plot. Enter an empty array if plotting all of an 
%         inputted SAC file.
% saveplot : Do we want to save our plot?
%            0 - No (default if empty)
%            1 - Yes 
% savedir : Where do we save our plot? Specify the directory as a string!
%           By default, the figure will be saved in your 'EPS' 
%           directory. Enter savedir as an empty string for the 
%           default.
% phasenames1 : If we want to plot predicted arrival times of seismic 
%               phases at the first station, enter the names of 
%               said phases, in a cell array
%               Default: {}
% ttimes1 : The predicted arrival times of the above phases, entered as 
%           a vector of the same length.
%           Default: []
% phasenames2 : If we want to plot predicted arrival times of seismic 
%               phases at the second station, enter the names of 
%               said phases, in a cell array
%               Default: {}
% ttimes2 : The predicted arrival times of the above phases, entered as 
%           a vector of the same length.
%           Default: []
% 
% OUTPUTS
% seisplot : The figure showing the seismograms of the inputted SAC files
% figname : The name of the figure saved, as an EPS file
% 
% References
% Uses defval.m, in csdms-contrib/slepian_alpha 
% Uses dat2jul.m and readsac.m, in csdms-contrib/slepian_oscar
% Uses figdisp.m, serre.m, label.m, and nolabels.m, in 
% csdms-contrib/slepian_alpha
% Uses char(176) to get the degree symbol, obtained from help
% forums on www.mathworks.com
% The lat-lon coordinates of Guyot Hall are from guyotphysics.m, in 
% csdms-contrib/slepian_zero
% 
% See plotsacdata.m
% 
% Last Modified by Yuri Tamama, 08/13/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set Default Values
if isempty(stalalo1)
  stalalo1=[40.34585 -74.65475];
end
if isempty(staloc1)
  staloc1='Guyot Hall, Princeton University';
end
if isempty(stacode1)
  stacode1='PP.S0001';
end
if isempty(samplefreq1)
  samplefreq1=100;
end
if isempty(stalalo2)
  stalalo2=[40.34585 -74.65475];
end
if isempty(staloc2)
  staloc2='Guyot Hall, Princeton University';
end
if isempty(stacode2)
  stacode2='PP.S0002';
end
if isempty(samplefreq2)
  samplefreq2=100;
end
defval('swvel',[])
defval('saveplot',0)
defval('savedir','')
defval('phasenames1',{});
defval('ttimes1',[]);
defval('phasenames2',{});
defval('ttimes2',[]);

% Check inputs
if isempty(sacfiles1) || length(sacfiles1)>3
  disp('Enter 1 SAC file per component.')
  return
end
if isempty(sacfiles2) || length(sacfiles2)>3
  disp('Enter 1 SAC file per component.')
  return
end
allorder=horzcat(plotorder1,plotorder2);
numunique=length(unique(allorder));
if numunique ~= numsubplots
  disp('Make sure you have data for each subplot.')
  return
end
nummatches=0;
maxmatches=min(length(plotorder1),length(plotorder2));
for i=1:length(plotorder1)
  orderval=plotorder1(i);
  if ismember(orderval,plotorder2)
    nummatches=nummatches+1;
  end
end
if (nummatches~=0) && (nummatches~=maxmatches)
  disp('Either have all subplots be "record sections" or plotted separately.')
  return
end

% Specify what the plot measures
if measval==0
  vallabelmini='Disp';
  valunit='nm';  
elseif measval==1
  vallabelmini='Vel';
  valunit='nm/s';
else
  vallabelmini='Acc';
  valunit='nm/s^2';  
end 

% Call plotsacdata.m for the first station
figure(gcf)
[seisplot1,axeshdl1,~]=plotsacdata(0,sacfiles1,...
    plotorder1,numsubplots,measval,filterfreqs,stalalo1,staloc1,...
    stacode1,samplefreq1,[],1,0,'','',1,evtid,magnitude,evlalo,...
    depth,phasenames1,ttimes1);
hold on
% Call plotsacdata.m for the second station
[seisplot,axeshdl2,~]=plotsacdata(0,sacfiles2,...
    plotorder2,numsubplots,measval,filterfreqs,stalalo2,staloc2,...
    stacode2,samplefreq2,[],1,0,'','',1,evtid,magnitude,evlalo,...
    depth,phasenames2,ttimes2);

% Put axis handles in order, from top subplot to bottom
if numsubplots>max(length(axeshdl1),length(axeshdl2))
  sortedhdlbeta=cell(numsubplots,1);
  axpos=zeros(numsubplots,1);
  for i=1:length(axeshdl1)+length(axeshdl2)
    if i>length(axeshdl1)
      testhdl=axeshdl2(i-length(axeshdl1));
    else
      testhdl=axeshdl1(i);
    end
    axpos(i)=sum(testhdl.Position);
  end
  axpos=sort(axpos,'descend');
  indices=1:length(axpos);
  for i=1:length(axeshdl1)+length(axeshdl2)
    if i>length(axeshdl1)
      testhdl=axeshdl2(i-length(axeshdl1));
    else
      testhdl=axeshdl1(i);
    end
    sumpos=sum(testhdl.Position);
    index=indices(sumpos==axpos);
    sortedhdlbeta{index}=testhdl;
  end
  sortedhdls=[];
  for h=1:length(sortedhdlbeta)
    sortedhdls=[sortedhdls; sortedhdlbeta{h}];
  end
else
  if length(axeshdl2)>=length(axeshdl1)
    sortedhdls=axeshdl2;
  else
    sortedhdls=axeshdl1;
  end
end

% Cut the horizonal axis limits, based on the surface wave velocity 
% threshold and epicentral distance
[~,header]=readsac(sacfiles1{1},0);
alltimes=0:header.DELTA:(header.NPTS/samplefreq)-header.DELTA;
timeind=1:length(alltimes);
[backazimuth1,~,distance1,~,distmtr1]=irisazimuth(evlalo,stalalo1);
[backazimuth2,~,distance2,~,distmtr2]=irisazimuth(evlalo,stalalo2);
if abs(distmtr1-distmtr2)/1000 < 20
  meandistkm=mean((1/1000)*[distmtr1 distmtr2]);
  finaltime=round(meandistkm/swvel,3);
  difftimes=abs(alltimes-finaltime);
  timeindex=timeind(difftimes==min(difftimes));
  finaltime=alltimes(timeindex);
  if finaltime*samplefreq<header.NPTS
    for c=1:length(sortedhdls)
      axishdl=sortedhdls(c);
      axishdl.XLim=[0 finaltime];
    end
  end
else
  finaltime1=round(distmtr1/(1000*swvel),3);
  difftimes1=abs(alltimes-finaltime1);
  timeindex1=timeind(difftimes1==min(difftimes1));
  finaltime1=alltimes(timeindex1);
  finaltime2=round(distmtr2/(1000*swvel),3);
  difftimes2=abs(alltimes-finaltime2);
  timeindex2=timeind(difftimes2==min(difftimes2));
  finaltime2=alltimes(timeindex2);
  if finaltime1*samplefreq<header.NPTS
    for c=1:length(axeshdl1)
      axishdl=axeshdl1(c);
      axishdl.XLim=[0 finaltime1];
    end
  end    
  if finaltime2*samplefreq<header.NPTS
    for c=1:length(axeshdl2)
      axishdl=axeshdl2(c);
      axishdl.XLim=[0 finaltime2];
    end
    if finaltime1<finaltime2
      for c=1:length(axeshdl1)
        axishdl=axeshdl1(c);
        set(axishdl,'Position',...
          get(axishdl,'Position').*[1 1 finaltime1/finaltime2 1])
      end
    else
      temphdl=axeshdl1(c);
      maxtime=max(temphdl.XLim);
      for c=1:length(axeshdl2)
        axishdl=axeshdl2(c);
        set(axishdl,'Position',...
          get(axishdl,'Position').*[1 1 finaltime2/maxtime 1])
      end
    end
  end   
end

% Make the vertical axis the same across all subplots
datalims=zeros(length(sortedhdls),1);
for c=1:length(sortedhdls)
  if c>length(axeshdl1)
    sacfile=sacfiles2{c-length(axeshdl1)};
    [seisdata,~]=readsac(sacfile,0);
    seisdata=seisdata(1:finaltime2*samplefreq2);
  else
    sacfile=sacfiles1{c};
    [seisdata,~]=readsac(sacfile,0);
    seisdata=seisdata(1:finaltime1*samplefreq1);
  end
  datalims(c)=max(abs(seisdata));
end
datalim=1.2*max(abs(datalims));
% Scale the subplots the same way
plotscale=1;
if datalim >= 5e6
  valunit(1:2)='mm';
  plotscale=1e6;
elseif datalim >= 5e3
  plotscale=1e3;
  if measval==0
    valunit='\mum';   
  elseif measval==1
    valunit='\mum/s';    
  else
    valunit='\mum/s^2';    
  end
end

% Scale the subplots!
for i=1:length(sortedhdls)
  axishdl=sortedhdls(i);
  axishdl.YLim=[-datalim datalim];
  vertlabel=axishdl.YLabel;
  if plotscale>1
    vertlblstrcell=strsplit(vertlabel.String);
    vertlblstrcell{length(vertlblstrcell)}=valunit;
    vertlabelstr=vertlblstrcell{1};
    for j=2:length(vertlblstrcell)
      vertlabelstr=sprintf('%s %s',vertlabelstr,vertlblstrcell{j});
    end
    vertlabel.String=vertlabelstr;
    tickval=axishdl.YTick(length(axishdl.YTick));
    tickval=round(tickval/plotscale);
    tickvalstr=sprintf('%d',tickval);
    axishdl.YTickLabelMode='manual';
    axishdl.YTickLabel={sprintf('-%s',tickvalstr);'0';tickvalstr};
  end
  if numsubplots>3
    vertlabel.FontSize=6.5;
  end
  shrink(axishdl,1,0.9)
end

% Move subplots next to one another
serre(sortedhdls,1,'down')

% Add the title to the uppermost subplot
% Location of event
locstr=irisevtloc(evtid);
titlestr1=sprintf('IRIS ID %s (%s)',num2str(evtid),locstr);
% Magnitude and depth
magstr=sprintf('Magnitude %.1f ',magnitude);
depstr=sprintf(' Depth=%.1f km',depth);
titlestr2=strcat(magstr,depstr);
% Network and station name
stastrs1=strsplit(stacode1,'.');
stastrs2=strsplit(stacode2,'.');
% Distance, back azimuth
deltastr1='\Delta';
deltastr21=sprintf('=%.1f%s',distance1,char(176));
backazstr1=strcat(sprintf('Back Azimuth %.2f',backazimuth1),...
    char(176));
deltastr2='\Delta';
deltastr22=sprintf('=%.1f%s',distance2,char(176));
backazstr2=strcat(sprintf('Back Azimuth %.2f',backazimuth2),...
    char(176));
if length(stastrs1)==2 && length(stastrs2)==2
  titlestr3=sprintf('%s (%s %s) & %s (%s %s)',staloc1,stastrs1{1},...
      stastrs1{2},staloc2,stastrs2{1},stastrs2{2});
  titlestr4=sprintf('%s %s: %s%s %s; %s %s: %s%s %s',stastrs1{1},...
      stastrs1{2},deltastr1,deltastr21,backazstr1,stastrs2{1},...
      stastrs2{2},deltastr2,deltastr22,backazstr2);
elseif length(stastrs1)==1 && length(stastrs2)==2
  titlestr3=sprintf('%s (%s) & %s (%s %s)',staloc1,stastrs1{1},...
      staloc2,stastrs2{1},stastrs2{2});
  titlestr4=sprintf('%s: %s%s %s; %s %s: %s%s %s',stastrs1{1},...
      deltastr1,deltastr21,backazstr1,stastrs2{1},stastrs2{2},...
      deltastr2,deltastr22,backazstr2);
elseif length(stastrs1)==2 && length(stastrs2)==1
  titlestr3=sprintf('%s (%s %s) & %s (%s)',staloc1,stastrs1{1},...
      stastrs1{2},staloc2,stastrs2{1});
  titlestr4=sprintf('%s %s: %s%s %s; %s %s: %s%s %s',stastrs1{1},...
      stastrs1{2},deltastr1,deltastr21,backazstr1,stastrs2{1},...
      deltastr2,deltastr22,backazstr2);  
else
  titlestr3=sprintf('%s (%s %s) & %s (%s)',staloc1,stastrs1{1},...
      staloc2,stastrs2{1});
  titlestr4=sprintf('%s: %s%s %s; %s: %s%s %s',stastrs1{1},deltastr1,...
      deltastr21,backazstr1,stastrs2{1},deltastr2,deltastr22,backazstr2); 
end
% Frequency and Period
freqstr1=sprintf('%g',filterfreqs(1));
freqstr2=sprintf('%g',filterfreqs(2));
freqstr3=sprintf('%g',filterfreqs(3));
freqstr4=sprintf('%g',filterfreqs(4)); 
pdstr1=sprintf('%.2f',1/filterfreqs(1));
pdstr2=sprintf('%.2f',1/filterfreqs(2));
pdstr3=sprintf('%.2f',1/filterfreqs(3));
pdstr4=sprintf('%.2f',1/filterfreqs(4));
freqtitle=['[',freqstr1,' {\color{magenta}',freqstr2,...
    ' \color{magenta}',freqstr3,'} ',freqstr4,'] Hz'];
pdtitle=['[',pdstr4,' {\color{magenta}',pdstr3,' \color{magenta}',...
    pdstr2,'} ',pdstr1,'] s'];
titlestr5=[freqtitle,'  ',pdtitle];

% Construct full title and add to plot
titlecell={titlestr1;titlestr2;titlestr3;titlestr4;titlestr5};
titleaxis=sortedhdls(1);
titleobj=titleaxis.Title;
titleobj.String=titlecell;
titleobj.FontSize=8.4;


% Save plot, if requested
if saveplot==1
  % Specify date of seismic event
  [~,header]=readsac(sacfiles1{1},0);
  yrstr=num2str(header.NZYEAR);  
  jdstr=datenum2str(header.NZJDAY,1);
  % Form figure name
  if ~isempty(ttimes1) || ~isempty(ttimes2)
    figname=sprintf('%s.and.%s.ID%s.%s.%s.%s.%ss_%s%s%s%s_pp.eps',...
      stacode1,stacode2,num2str(evtid),lower(vallabelmini),yrstr,...
      jdstr,num2str(intend),freqstr1,freqstr2,freqstr3,freqstr4);  
  else
    figname=sprintf('%s.and.%s.ID%s.%s.%s.%s.%ss_%s%s%s%s.eps',...
      stacode1,stacode2,num2str(evtid),lower(vallabelmini),yrstr,...
      jdstr,num2str(intend),freqstr1,freqstr2,freqstr3,freqstr4);
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

