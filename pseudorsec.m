function [seishdls,saccsv]=pseudorsec(makefiles,saccsv,...
    measval,frequency,magnitudes,years,fastsw,slowsw,staloc,stacode,...
    stalalo,colorcode,plotevtids,saveplots,savedir)
%
% Function to make record-section-esque plots in the vertical and 
% horizontal directions, where seismograms of earthquakes within a 
% specified magnitude range will be plotted in one plot, separated by 
% distance to the station. In these plots, the surface wave windows 
% and the P and S arrivals will be labeled.
%
% The data for this plot are from the S0001 seismometer, situated in 
% Guyot Hall as part of the PP network.
% 
% INPUTS
% makefiles : Do we need to make SAC files of these events?
%             0 - No, they exist 
%             1 - Yes, make SAC files (Default)
% saccsv : The name of a CSV file containing the names of the existing
%          SAC files, if applicable. Enter an empty string if not
%          applicable. 
%          Note: The same CSV file can be used for plotsacevents.m
%          Note 2: If you have a CSV file that was made for another set of 
%          surface wave velocities, you can still use it as long as the 
%          lower velocity is less than or equal to the new one you plan 
%          to test.
%          Default: ''
% measval : Are we plotting displacement, velocity, or acceleration?
%           0 for displacement in nm (default)
%           1 for velocity in nm/s 
%           2 for acceleration in nm/(s^2)
% frequency : The frequencies to which the data will be filtered during
%             instrument correction
%             Default: [0.01 0.02 10.00 20.00] Hz
% magnitudes : The range of magnitudes of the events we wish to plot, 
%              entered as a vector of length 2 or as a single value, 
%              if considering only 1 magnitude value
%              Default: [7.5 10] (Earthquakes with M>=7.5)
%              The maximum magnitude between 2017-2019 is 8.2;
% 
%              Note: The magnitudes are inclusive on both ends!
% years : In which year(s) (from 2017-2019) will we look for events? 
%         Enter a vector if considering multiple years.
%         Default: 2019
% fastsw : The upper threshold for surface wave velocity in km/s, marking 
%          the beginning of the surface wave window
%          Default: 5 km/s
% slowsw : The lower threshold for surface wave velocity in km/s, marking
%          the end of the surface wave window
%          Default: 2.5 km/s
% staloc : The name of the place/station where the seismic data were
%          recorded. 
%          Default: 'Guyot Hall, Princeton University'
% stacode : The network and/or station code for the seismometer 
%           (separate with a period if using both). 
%           Default: 'PP.S0001' (the first Guyot Hall seismometer) 
% stalalo : The latitude-longitude of the station, entered as a vector
%           in that order.
%           Default: [40.34585 -74.65475], the lat-lon of Guyot Hall 
%           from guyotphysics.m.
% colorcode : How do we want to color-code our seismograms?
%             0 - No color code (Default)
%             1 - By magnitude
%             2 - By depth 
%             3 - By distance 
% plotevtids : Do we want to have the IRIS Event IDs for each earthquake
%              on the plot?
%              0 - No (Default)
%              1 - Yes
% saveplots : Do we want to save the figure handles? They will be saved
%             as EPS files if so
%             0 - No (Default)
%             1 - Yes
% savedir : In what directory will the plots be saved? By default, they 
%           will be saved in your 'EPS' directory
%
% Note: We can only make SAC files from scratch for the S0001 (first) 
%       seismometer in the Guyot Hall network.
% 
% OUTPUTS
% seishdls : Figure handles of the seismograms (Z, Y, X)
% saccsv : A csv file containing the names of the SAC files that were 
%          plotted
% phasehdls : Figure handles of the plots featuring phase arrivals
%             (Z, Y, X)
% 
% See mcevt2sac.m
% 
% References
% Uses defval.m, in csdms-contrib/slepian_alpha 
%
% Use of colormap, including how to adjust for the number of colors in 
% the colormap, from MATLAB help forums
%
% Last Modified by Yuri Tamama, 08/13/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('makefiles',1);
defval('saccsv','');
defval('measval',0);
defval('frequency',[0.01 0.02 10.00 20.00]); 
defval('magnitudes',[7.5 10]);
defval('years',2019);
defval('fastsw',5);
defval('slowsw',2.5);
defval('staloc','Guyot Hall, Princeton University')
defval('stacode','PP.S0001')
defval('stalalo',[40.34585 -74.65475]);
defval('colorcode',0);
defval('plotevtids',0);
defval('saveplots',0);
defval('savedir','');

% Specify necessary directories to get data - insert your own!
datadir=getenv('');

% Search for the events matching the inputted parameters
years=sort(years,'ascend');
for i=1:length(years)
  filename=sprintf('eq_%d',years(i));
  filename=fullfile(datadir,filename);
  if i==1
    eqdata=readtable(filename,'Format','%d%s%f%f%f%f%f%f%f');
  else
    tempdata=readtable(filename,'Format','%d%s%f%f%f%f%f%f%f');
    eqdata=vertcat(eqdata,tempdata);
  end
end
% Select earthquakes with the inputted magnitude(s)
magnitudes=sort(magnitudes,'ascend');
mgcol=eqdata.Var6;
if length(magnitudes)==2
  eqdata=eqdata(mgcol>=magnitudes(1) & mgcol<=magnitudes(2),:);
else
  eqdata=eqdata(mgcol==magnitudes,:);
end
numevts=size(eqdata);
numevts=numevts(1);

% Specify how long of an interval we wish to plot
% Also obtain epicentral distances and first arriving phases for each 
% earthquake!
maxtime=0;
maxdist=0;
for i=1:numevts
  rowdata=eqdata(i,:);
  evlalo=[rowdata.Var3 rowdata.Var4];
  % Distance
  [~,~,~,distmtr]=irisazimuth(evlalo,stalalo);
  distdeg=rowdata.Var7;
  distkm=distmtr/1000;
  % Maximum distance (degrees)
  if distdeg>maxdist
    maxdist=distdeg;
  end
  % Keep track of phase travel times and corresponding distances!
  evdep=rowdata.Var5;
  ttimetbl=iristtimes(evlalo,evdep,'',stalalo);
  phases=ttimetbl.phases;
  ttimes=ttimetbl.ttimes;
  % Make phase-time-distance table at the first event
  if i==1
    phasecell=cell(length(phases),1);
    for j=1:length(phases)
      nowcell=cell(1,3);
      % Add phase name, travel time, distance
      nowcell{1}=phases{j};
      nowcell{2}=ttimes(j);
      nowcell{3}=distdeg;
      phasecell{j}=nowcell;
    end
  else
    % Iterate through each phase in the phase list
    for p=1:length(phases)
      phasename=phases{p};
      phasettime=ttimes(p);
      % Look for which phase-time-dist cell has the matching phase
      hasphase=0;
      for c=1:length(phasecell)
        % Get each "table" of phase-time-dist
        nowcell=phasecell{c};
        % Which phase is this?
        nowphase=nowcell{1};
        if strcmp(phasename,nowphase)
          nowcell=vertcat(nowcell,{phasename,phasettime,distdeg});
          phasecell{c}=nowcell;
          hasphase=1;
          break
        end
      end
      % If there is no matching, pre-existing phase
      if hasphase==0
        newcell=cell(1,3);
        newcell{1}=phasename;
        newcell{2}=phasettime;
        newcell{3}=distdeg;
        phasecell=vertcat(phasecell,cell(1,1));
        phasecell{length(phasecell)}=newcell;
      end    
    end
  end
  % Total time
  totaltime=round(distkm/slowsw,2);
  % Maximum time
  if totaltime>maxtime
    maxtime=totaltime;
  end
end

% Compose tables of P/Pdiff and S arrivals, to plot in each figure
numphases=size(phasecell);
numphases=numphases(1);
pphases={};
pttimes=[];
pdistdegs=[];
sphases={};
sttimes=[];
sdistdegs=[];
for i=1:numphases
  nowphasetbl=phasecell{i};
  nowphase=nowphasetbl{1,1};
  if strcmp(nowphase,'P') || strcmp(nowphase,'Pdiff')
    numelements=size(nowphasetbl);
    numelements=numelements(1);
    for j=1:numelements
      pphases=vertcat(pphases,nowphasetbl{j,1});
      pttimes=[pttimes; nowphasetbl{j,2}];
      pdistdegs=[pdistdegs; nowphasetbl{j,3}];
    end
  end
  if strcmp(nowphase,'S') || strcmp(nowphase,'Sdiff')
    numelements=size(nowphasetbl);
    numelements=numelements(1);
    for j=1:numelements
      sphases=vertcat(sphases,nowphasetbl{j,1});
      sttimes=[sttimes; nowphasetbl{j,2}];
      sdistdegs=[sdistdegs; nowphasetbl{j,3}];
    end
  end
end
pphasetbl=table(pphases,pttimes,pdistdegs);
sphasetbl=table(sphases,sttimes,sdistdegs);

% Sort earthquake data table by epicentral distance
eqdata=sortrows(eqdata,7);


% Generate SAC files, if that hasn't been done already!
if makefiles==1 || exist(saccsv)==0
  corrfilesx={};
  corrfilesy={};
  corrfilesz={};
  for i=1:numevts
    rowdata=eqdata(i,:);
    swortime=1;
    intend=maxtime+100;
    corrfiles=mcevt2sac(rowdata,measval,swortime,intend,frequency);
    priorlenx=length(corrfilesx);
    priorleny=length(corrfilesy);
    priorlenz=length(corrfilesz);
    corrfilesx=vertcat(corrfilesx,corrfiles{contains(corrfiles,'HHX')});
    corrfilesy=vertcat(corrfilesy,corrfiles{contains(corrfiles,'HHY')});
    corrfilesz=vertcat(corrfilesz,corrfiles{contains(corrfiles,'HHZ')});
    if length(corrfilesx)==priorlenx
      corrfilesx=vertcat(corrfilesx,' ');
    end
    if length(corrfilesy)==priorleny
      corrfilesy=vertcat(corrfilesy,' ');
    end
    if length(corrfilesz)==priorlenz
      corrfilesz=vertcat(corrfilesz,' ');
    end
  end
  % Put corrected SAC file names in a table
  sactable=table(eqdata.Var7,corrfilesx,corrfilesy,corrfilesz);
  % Sort the files in order of ascending epicentral distance
  % (though it should already be sorted)
  sactable=sortrows(sactable);
  if length(magnitudes)>1
    if magnitudes(2)>8.2
      magstr=sprintf('%g+',magnitudes(1));
    elseif magnitudes(1)<-1.69
      magstr=sprintf('%g-',magnitudes(2));
    else
      magstr=sprintf('%gto%g',magnitudes(1),magnitudes(2));
    end
  else
    magstr=num2str(magnitudes(1));
  end
  if length(years)>1
    if years(length(years))-years(1) ~= length(years)-1 
      yrstr=sprintf('%dand%d',years(1)-2000,years(length(years))-2000);
    else
      yrstr=sprintf('%dto%d',years(1)-2000,years(length(years))-2000);
    end
  else
    yrstr=num2str(years(1)-2000);
  end
  saccsv=sprintf('%s.M%s.%s.%g%g%g%g.f%gs%g.csv',stacode,magstr,yrstr,...
    frequency(1),frequency(2),frequency(3),frequency(4),fastsw,slowsw);
  writetable(sactable,saccsv);  
else
  sactable=readtable(saccsv,'Delimiter',',');
  sactable=sortrows(sactable);
end

% Sorted distances, file names, and IRIS event IDs
sortedfilesx=sactable.corrfilesx;
sortedfilesy=sactable.corrfilesy;
sortedfilesz=sactable.corrfilesz;


%%%%%%%%%%
% Iterate through the events/files, plotting each onto the record
% sections in each direction

% Z 
zfigure=figure();
hold on
% Plot the surface wave speed lines
% Spherical approximation to convert from degrees to km
fastswdg=km2deg(fastsw);
slowswdg=km2deg(slowsw);
xrangeall=[0:maxtime];
yfast=xrangeall.*(fastswdg*75000);
yslow=xrangeall.*(slowswdg*75000);
fastline=line(xrangeall,yfast,'Color',[0.5 0.5 0.5],'LineStyle',...
  '--');
slowline=line(xrangeall,yslow,'Color',[0.3 0.3 0.3],'LineStyle',...
    ':','LineWidth',1.5);

% Plot each event, sorted by distance
nextloc=[];
for i=1:numevts
  rowdata=eqdata(i,:);
  evtidstr=num2str(rowdata.Var1);
  depth=rowdata.Var5;
  magnitude=rowdata.Var6;
  distdeg=rowdata.Var7;
  vertpos=distdeg*75000;

  % Plot each event and its P and S arrivals, if a file for it exists
  filez=sortedfilesz{i};
  if exist(filez)==2
    % Plot seismogram
    [sacdata,header]=readsac(filez,0);
  else
    continue
  end
  xrange=0:round(header.DELTA,3):round(header.E,2);
  sacdata=sacdata+vertpos;
  seismogram=plot(xrange,sacdata);
  seismogram.HandleVisibility='off';
  if colorcode==1
    seismogram.Color=pscolorcode(magnitude,colorcode);
  elseif colorcode==2
    seismogram.Color=pscolorcode(depth,colorcode);
  elseif colorcode==3
    seismogram.Color=pscolorcode(distdeg,colorcode);
  end    
  
  % Label IRIS Event ID, if requested
  if plotevtids==1
    % Event ID to the right end
    if distdeg<0.5*maxdist
      % If another seismogram is situated within 5 degrees, specify where
      % the label goes also on that seismogram
      if isempty(nextloc)
        idlabel=text(0.85*maxtime,0.92*vertpos,evtidstr,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
        arrlabel=text(0.65*ttime,0.92*vertpos,phasename,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
        if i<numevts && (sorteddist(i+1)-distdeg<5)
          nextloc=1;
        end
      else
        idlabel=text(0.95*maxtime,1.05*vertpos,evtidstr,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
        arrlabel=text(0.75*ttime,1.05*vertpos,phasename,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
      end
    % Event ID to the left end
    else
      labeltxt=sprintf('%s %s',evtidstr,phasename);
      if isempty(nextloc)
        fulllabel=text(50,0.98*vertpos,labeltxt,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
        if i<numevts && (sorteddist(i+1)-distdeg<5)
          nextloc=1;
        end
      else
        fulllabel=text(50,1.02*vertpos,labeltxt,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
      end
    end
  end
end    
xlim([0 maxtime])
ylim([0 1.1*maxdist*75000])

% Plot the P and S arrivals
numparrs=size(pphasetbl);
numparrs=numparrs(1);
numsarrs=size(sphasetbl);
numsarrs=numsarrs(1);
% P and Pdiff
firstp=0;
firstpdiff=0;
for i=1:numparrs
  phasename=pphasetbl(i,1);
  phasetime=pphasetbl(i,2);
  phasedist=pphasetbl(i,3);
  if strcmp(phasename,'P')
    phaseline=line([phasetime phasetime],...
      [(phasedist-3)*75000 (phasedist+3)*75000],'Color','m',...
      'LineWidth',1.5);
    if firstp==1
      phaseline.HandleVisibility='off';
    end
    firstp=1;
  elseif strcmp(phasename,'Pdiff')
    phaseline=line([phasetime phasetime],...
      [(phasedist-3)*75000 (phasedist+3)*75000],'Color',[0.65 0 0.65],...
      'LineWidth',1.5);
    if firstpdiff==1
      phaseline.HandleVisibility='off';
    end
    firstpdiff=1;
  end
end
%
% S and Sdiff
firsts=0;
firstsdiff=0;
for i=1:numsarrs
  phasename=sphasetbl(i,1);
  phasetime=sphasetbl(i,2);
  phasedist=sphasetbl(i,3);
  if strcmp(phasename,'S')
    phaseline=line([phasetime phasetime],...
      [(phasedist-3)*75000 (phasedist+3)*75000],'Color','g',...
      'LineWidth',1.5);
    if firsts==1
      phaseline.HandleVisibility='off';
    end
    firsts=1;
  elseif strcmp(phasename,'Sdiff')
    phaseline=line([phasetime phasetime],...
      [(phasedist-3)*75000 (phasedist+3)*75000],'Color',...
      [0 0.65 0],'LineWidth',1.5);
    if firstsdiff==1
      phaseline.HandleVisibility='off';
    end
    firstsdiff=1;
  end
end

% Add a legend for the phases
fastswlbl=sprintf('%g km/s',fastsw);
slowswlbl=sprintf('%g km/s',slowsw);
zlegend=legend(fastswlbl,slowswlbl,'P','Pdiff','S','Sdiff','Location',...
    'best');
zlegend.FontSize=7;

% Put a colorbar, if applicable
if colorcode==1
  cmap=colormap(jet(11));
  cbar=colorbar;
  cbar.TicksMode='manual';
  cbar.Ticks=[0:1/11:1];
  cbar.TickLabelsMode='manual';
  cbar.TickLabels={'-2';'-1';'0';'1';'2';'3';'4';'5';'6';'7';'8';'9'};
  cbar.Label.String='Magnitude';
elseif colorcode==2
  cmap=colormap(jet(14));
  cbar=colorbar;
  cbar.TicksMode='manual';
  cbar.Ticks=[0:1/14:1];
  cbar.TickLabelsMode='manual';
  cbar.TickLabels={'0';'50';'100';'150';'200';'250';'300';'350';'400';...
    '450';'500';'550';'600';'650';'700'};
  cbar.Label.String='Depth (km)';
elseif colorcode==3
  cmap=colormap(jet(18));
  cbar=colorbar;
  cbar.TicksMode='manual';
  cbar.Ticks=[0:1/18:1];
  cbar.TickLabelsMode='manual';
  cbar.TickLabels={'0';'10';'20';'30';'40';'50';'60';'70';'80';'90';...
    '100';'110';'120';'130';'140';'150';'160';'170';'180'};
  cbar.Label.String='Epicentral Distance (degrees)';
end
cbar.Location='eastoutside';
cbar.Label.Rotation=270;
cbar.Label.Position=(cbar.Label.Position).*[5/4 1 1];

% Add plot title
if measval==0
  measstr='Displacement';
elseif measval==1
  measstr='Velocity';
else
  measstr='Acceleration';
end
if length(magnitudes)>1
  if magnitudes(2)>8.2
    magstr2=sprintf('Above %g',magnitudes(1));
  elseif magnitudes(1)<-1.69
    magstr2=sprintf('Below %g',magnitudes(2));    
  else
    magstr2=sprintf('%g to %g',magnitudes(1),magnitudes(2));
  end
else
  magstr2=num2str(magnitudes);
end
if length(years)>1
  if years(length(years))-years(1) ~= length(years)-1  
    yrstr2=sprintf('%d, %d',years(1),years(length(years)));
  else
    yrstr2=sprintf('%d-%d',years(1),years(length(years)));
  end
else
  yrstr2=num2str(years(1));
end
titlestr1=sprintf('%s by Earthquakes of Magnitude %s in %s (Z)',measstr,...
  magstr2,yrstr2);
titlestr2=sprintf('Recorded at %s (%s)',staloc,replace(stacode,'.',' '));
% Frequency and period
freqstr1=sprintf('%g',frequency(1));
freqstr2=sprintf('%g',frequency(2));
freqstr3=sprintf('%g',frequency(3));
freqstr4=sprintf('%g',frequency(4)); 
pdstr1=sprintf('%.2f',1/frequency(1));
pdstr2=sprintf('%.2f',1/frequency(2));
pdstr3=sprintf('%.2f',1/frequency(3));
pdstr4=sprintf('%.2f',1/frequency(4));
freqtitle=['[',freqstr1,' {\color{magenta}',freqstr2,...
  ' \color{magenta}',freqstr3,'} ',freqstr4,'] Hz'];
pdtitle=['[',pdstr4,' {\color{magenta}',pdstr3,' \color{magenta}',...
  pdstr2,'} ',pdstr1,'] s'];
titlestr3=[freqtitle,'  ',pdtitle];
title({titlestr1;titlestr2;titlestr3})
nowaxis=gca;
plottitle=nowaxis.Title;
plottitle.FontSize=9;

% Horizontal axis label
xlabel('Time (s) since Earthquake Origin')
horzlabel=nowaxis.XLabel;
horzlabel.FontSize=9.5;
% Vertical Axis Ticks and Label
nowaxis.YTickMode='manual';
yticks=[];
yticklabels={};
if 1.1*maxdist>100
  for i=1:floor(1.1*maxdist/20)
    yticks=[yticks; 20*75000*i];
    yticklabels=vertcat(yticklabels,sprintf('%d',20*i));
  end
else
  for i=1:floor(1.1*maxdist/10)
    yticks=[yticks; 10*75000*i];
    yticklabels=vertcat(yticklabels,sprintf('%d',10*i));
  end
end
nowaxis.YTick=yticks;
nowaxis.YTickLabelMode='manual';
nowaxis.YTickLabel=yticklabels;
ylabel('Distance (deg) from Earthquake to Station')
vertlabel=nowaxis.YLabel;
vertlabel.FontSize=9.5;

% If saving this figure:
if saveplots==1
  % Strings for file names
  if length(magnitudes)>1
    if magnitudes(2)>8.2
      magstr=sprintf('%g+',magnitudes(1));
    elseif magnitudes(1)<-1.69
      magstr=sprintf('%g-',magnitudes(2));
    else
      magstr=sprintf('%gto%g',magnitudes(1),magnitudes(2));
    end
  else
    magstr=num2str(magnitudes(1));
  end
  if length(years)>1
    yrstr=sprintf('%dto%d',years(1)-2000,years(length(years))-2000);
  else
    yrstr=num2str(years(1)-2000);
  end
  
  if colorcode==0
    figname=sprintf('M%s.%s.Z.%g%g%g%g_f%gs%gs.eps',magstr,yrstr,...
      frequency(1),frequency(2),frequency(3),frequency(4),fastsw,...
      slowsw);
  else
    figname=sprintf('M%s.%s.Z.%g%g%g%g_f%gs%gs_cc%d.eps',magstr,yrstr,...
      frequency(1),frequency(2),frequency(3),frequency(4),fastsw,...
      slowsw,colorcode);
  end
  % Save figure
  figname2=figdisp(figname,[],[],1,[],'epstopdf');
  % Move figure to save directory
  if ~isempty(savedir)
    [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
    figname=fullfile(savedir,figname);
  else
    figname=figname2;
  end
end

  
  
% Y
yfigure=figure();
hold on
% Plot the surface wave speed lines
fastline=line(xrangeall,yfast,'Color',[0.5 0.5 0.5],'LineStyle',...
  '--');
slowline=line(xrangeall,yslow,'Color',[0.3 0.3 0.3],'LineStyle',...
    ':','LineWidth',1.5);

% Plot each event, sorted by distance
nextloc=[];
for i=1:numevts
  rowdata=eqdata(i,:);
  evtidstr=num2str(rowdata.Var1);
  depth=rowdata.Var5;
  magnitude=rowdata.Var6;
  distdeg=rowdata.Var7;
  vertpos=distdeg*75000;
  
  % Plot each event and its P and S arrivals, if a file for it exists
  filey=sortedfilesy{i};
  if exist(filey)==2
    % Plot seismogram
    [sacdata,header]=readsac(filey,0);
  else
    continue
  end
  xrange=0:round(header.DELTA,3):round(header.E,2);
  sacdata=sacdata+vertpos;
  seismogram=plot(xrange,sacdata);
  seismogram.HandleVisibility='off';
  if colorcode==1
    seismogram.Color=pscolorcode(magnitude,colorcode);
  elseif colorcode==2
    seismogram.Color=pscolorcode(depth,colorcode);
  elseif colorcode==3
    seismogram.Color=pscolorcode(distdeg,colorcode);
  end  
  
  % Label IRIS Event ID, if requested
  if plotevtids==1
    % Event ID to the right end
    if distdeg<0.5*maxdist
      % If another seismogram is situated within 5 degrees, specify where
      % the label goes also on that seismogram
      if isempty(nextloc)
        idlabel=text(0.85*maxtime,0.92*vertpos,evtidstr,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
        arrlabel=text(0.65*ttime,0.92*vertpos,phasename,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
        if i<numevts && (sorteddist(i+1)-distdeg<5)
          nextloc=1;
        end
      else
        idlabel=text(0.95*maxtime,1.05*vertpos,evtidstr,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
        arrlabel=text(0.75*ttime,1.05*vertpos,phasename,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
      end
    % Event ID to the left end
    else
      labeltxt=sprintf('%s %s',evtidstr,phasename);
      if isempty(nextloc)
        fulllabel=text(50,0.98*vertpos,labeltxt,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
        if i<numevts && (sorteddist(i+1)-distdeg<5)
          nextloc=1;
        end
      else
        fulllabel=text(50,1.02*vertpos,labeltxt,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
      end
    end
  end
end    
xlim([0 maxtime])
ylim([0 1.1*maxdist*75000])

% Plot the P and S arrivals
numparrs=size(pphasetbl);
numparrs=numparrs(1);
numsarrs=size(sphasetbl);
numsarrs=numsarrs(1);
% P and Pdiff
firstp=0;
firstpdiff=0;
for i=1:numparrs
  phasename=pphasetbl(i,1);
  phasetime=pphasetbl(i,2);
  phasedist=pphasetbl(i,3);
  if strcmp(phasename,'P')
    phaseline=line([phasetime phasetime],...
      [(phasedist-3)*75000 (phasedist+3)*75000],'Color'...
      ,'m','LineWidth',1.5);
    if firstp==1
      phaseline.HandleVisibility='off';
    end
    firstp=1;
  elseif strcmp(phasename,'Pdiff')
    phaseline=line([phasetime phasetime],...
      [(phasedist-3)*75000 (phasedist+3)*75000],...
      'Color',[0.65 0 0.65],'LineWidth',1.5);
    if firstpdiff==1
      phaseline.HandleVisibility='off';
    end
    firstpdiff=1;
  end
end
%
% S and Sdiff
firsts=0;
firstsdiff=0;
for i=1:numsarrs
  phasename=sphasetbl(i,1);
  phasetime=sphasetbl(i,2);
  phasedist=sphasetbl(i,3);
  if strcmp(phasename,'S')
    phaseline=line([phasetime phasetime],...
      [(phasedist-3)*75000 (phasedist+3)*75000],...
      'Color','g','LineWidth',1.5);
    if firsts==1
      phaseline.HandleVisibility='off';
    end
    firsts=1;
  elseif strcmp(phasename,'Sdiff')
    phaseline=line([phasetime phasetime],...
      [(phasedist-3)*75000 (phasedist+3)*75000],...
      'Color',[0 0.65 0],'LineWidth',1.5);
    if firstsdiff==1
      phaseline.HandleVisibility='off';
    end
    firstsdiff=1;
  end
end

% Add a legend for the phases
ylegend=legend(fastswlbl,slowswlbl,'P','Pdiff','S','Sdiff','Location',...
    'best');
ylegend.FontSize=7;

% Put a colorbar, if applicable
if colorcode==1
  cmap=colormap(jet(11));
  cbar=colorbar;
  cbar.TicksMode='manual';
  cbar.Ticks=[0:1/11:1];
  cbar.TickLabelsMode='manual';
  cbar.TickLabels={'-2';'-1';'0';'1';'2';'3';'4';'5';'6';'7';'8';'9'};
  cbar.Label.String='Magnitude';
elseif colorcode==2
  cmap=colormap(jet(14));
  cbar=colorbar;
  cbar.TicksMode='manual';
  cbar.Ticks=[0:1/14:1];
  cbar.TickLabelsMode='manual';
  cbar.TickLabels={'0';'50';'100';'150';'200';'250';'300';'350';'400';...
    '450';'500';'550';'600';'650';'700'};
  cbar.Label.String='Depth (km)';
elseif colorcode==3
  cmap=colormap(jet(18));
  cbar=colorbar;
  cbar.TicksMode='manual';
  cbar.Ticks=[0:1/18:1];
  cbar.TickLabelsMode='manual';
  cbar.TickLabels={'0';'10';'20';'30';'40';'50';'60';'70';'80';'90';...
    '100';'110';'120';'130';'140';'150';'160';'170';'180'};
  cbar.Label.String='Epicentral Distance (degrees)';
end
cbar.Location='eastoutside';
cbar.Label.Rotation=270;
cbar.Label.Position=(cbar.Label.Position).*[5/4 1 1];

% Add plot title
titlestr1=sprintf('%s by Earthquakes of Magnitude %s in %s (N/S)',measstr,...
  magstr2,yrstr2);
title({titlestr1;titlestr2;titlestr3})
nowaxis=gca;
plottitle=nowaxis.Title;
plottitle.FontSize=9;
% Horizontal axis label
xlabel('Time (s) since Earthquake Origin')
horzlabel=nowaxis.XLabel;
horzlabel.FontSize=9.5;
% Vertical Axis Ticks and Label
nowaxis.YTickMode='manual';
yticks=[];
yticklabels={};
if 1.1*maxdist>100
  for i=1:floor(1.1*maxdist/20)
    yticks=[yticks; 20*75000*i];
    yticklabels=vertcat(yticklabels,sprintf('%d',20*i));
  end
else
  for i=1:floor(1.1*maxdist/10)
    yticks=[yticks; 10*75000*i];
    yticklabels=vertcat(yticklabels,sprintf('%d',10*i));
  end
end
nowaxis.YTick=yticks;
nowaxis.YTickLabelMode='manual';
nowaxis.YTickLabel=yticklabels;
ylabel('Distance (deg) from Earthquake to Station')
vertlabel=nowaxis.YLabel;
vertlabel.FontSize=9.5;

% If saving this figure:
if saveplots==1
  if colorcode==0
    figname=sprintf('M%s.%s.Z.%g%g%g%g_f%gs%gs.eps',magstr,yrstr,...
      frequency(1),frequency(2),frequency(3),frequency(4),fastsw,...
      slowsw);
  else
    figname=sprintf('M%s.%s.Z.%g%g%g%g_f%gs%gs_cc%d.eps',magstr,yrstr,...
      frequency(1),frequency(2),frequency(3),frequency(4),fastsw,...
      slowsw,colorcode);
  end
  % Save figure
  figname2=figdisp(figname,[],[],1,[],'epstopdf');
  % Move figure to save directory
  if ~isempty(savedir)
    [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
    figname=fullfile(savedir,figname);
  else
    figname=figname2;
  end
end



% X
xfigure=figure();
hold on
% Plot the surface wave speed lines
fastline=line(xrangeall,yfast,'Color',[0.5 0.5 0.5],'LineStyle',...
  '--');
slowline=line(xrangeall,yslow,'Color',[0.3 0.3 0.3],'LineStyle',...
    ':','LineWidth',1.5);

% Plot each event, sorted by distance
nextloc=[];
for i=1:numevts
  rowdata=eqdata(i,:);
  evtidstr=num2str(rowdata.Var1);
  depth=rowdata.Var5;
  magnitude=rowdata.Var6;
  distdeg=rowdata.Var7;
  vertpos=distdeg*75000;
  
  % Plot each event and its P and S arrivals, if a file for it exists
  filex=sortedfilesx{i};
  if exist(filex)==2
    % Plot seismogram
    [sacdata,header]=readsac(filex,0);
  else
    continue
  end
  xrange=0:round(header.DELTA,3):round(header.E,2);
  sacdata=sacdata+vertpos;
  seismogram=plot(xrange,sacdata);
  seismogram.HandleVisibility='off';
  if colorcode==1
    seismogram.Color=pscolorcode(magnitude,colorcode);
  elseif colorcode==2
    seismogram.Color=pscolorcode(depth,colorcode);
  elseif colorcode==3
    seismogram.Color=pscolorcode(distdeg,colorcode);
  end   
  
  % Label IRIS Event ID, if requested
  if plotevtids==1
    % Event ID to the right end
    if distdeg<0.5*maxdist
      % If another seismogram is situated within 5 degrees, specify where
      % the label goes also on that seismogram
      if isempty(nextloc)
        idlabel=text(0.85*maxtime,0.92*vertpos,evtidstr,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
        arrlabel=text(0.65*ttime,0.92*vertpos,phasename,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
        if i<numevts && (sorteddist(i+1)-distdeg<5)
          nextloc=1;
        end
      else
        idlabel=text(0.95*maxtime,1.05*vertpos,evtidstr,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
        arrlabel=text(0.75*ttime,1.05*vertpos,phasename,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
      end
    % Event ID to the left end
    else
      labeltxt=sprintf('%s %s',evtidstr,phasename);
      if isempty(nextloc)
        fulllabel=text(50,0.98*vertpos,labeltxt,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
        if i<numevts && (sorteddist(i+1)-distdeg<5)
          nextloc=1;
        end
      else
        fulllabel=text(50,1.02*vertpos,labeltxt,'FontSize',5.5,...
          'Color',[0.55 0.55 0.55]);
      end
    end
  end 
end    
xlim([0 maxtime])
ylim([0 1.1*maxdist*75000])

% Plot the P and S arrivals
numparrs=size(pphasetbl);
numparrs=numparrs(1);
numsarrs=size(sphasetbl);
numsarrs=numsarrs(1);
% P and Pdiff
firstp=0;
firstpdiff=0;
for i=1:numparrs
  phasename=pphasetbl(i,1);
  phasetime=pphasetbl(i,2);
  phasedist=pphasetbl(i,3);
  if strcmp(phasename,'P')
    phaseline=line([phasetime phasetime],...
      [(phasedist-3)*75000 (phasedist+3)*75000],'Color'...
      ,'m','LineWidth',1.5);
    if firstp==1
      phaseline.HandleVisibility='off';
    end
    firstp=1;
  elseif strcmp(phasename,'Pdiff')
    phaseline=line([phasetime phasetime],...
      [(phasedist-3)*75000 (phasedist+3)*75000],...
      'Color',[0.65 0 0.65],'LineWidth',1.5);
    if firstpdiff==1
      phaseline.HandleVisibility='off';
    end
    firstpdiff=1;
  end
end
%
% S and Sdiff
firsts=0;
firstsdiff=0;
for i=1:numsarrs
  phasename=sphasetbl(i,1);
  phasetime=sphasetbl(i,2);
  phasedist=sphasetbl(i,3);
  if strcmp(phasename,'S')
    phaseline=line([phasetime phasetime],...
      [(phasedist-3)*75000 (phasedist+3)*75000],...
      'Color','g','LineWidth',1.5);
    if firsts==1
      phaseline.HandleVisibility='off';
    end
    firsts=1;
  elseif strcmp(phasename,'Sdiff')
    phaseline=line([phasetime phasetime],...
      [(phasedist-3)*75000 (phasedist+3)*75000],...
      'Color',[0 0.65 0],'LineWidth',1.5);
    if firstsdiff==1
      phaseline.HandleVisibility='off';
    end
    firstsdiff=1;
  end
end

% Add a legend for the phases
xlegend=legend(fastswlbl,slowswlbl,'P','Pdiff','S','Sdiff','Location',...
    'best');
xlegend.FontSize=7;

% Put a colorbar, if applicable
if colorcode==1
  cmap=colormap(jet(11));
  cbar=colorbar;
  cbar.TicksMode='manual';
  cbar.Ticks=[0:1/11:1];
  cbar.TickLabelsMode='manual';
  cbar.TickLabels={'-2';'-1';'0';'1';'2';'3';'4';'5';'6';'7';'8';'9'};
  cbar.Label.String='Magnitude';
elseif colorcode==2
  cmap=colormap(jet(14));
  cbar=colorbar;
  cbar.TicksMode='manual';
  cbar.Ticks=[0:1/14:1];
  cbar.TickLabelsMode='manual';
  cbar.TickLabels={'0';'50';'100';'150';'200';'250';'300';'350';'400';...
    '450';'500';'550';'600';'650';'700'};
  cbar.Label.String='Depth (km)';
elseif colorcode==3
  cmap=colormap(jet(18));
  cbar=colorbar;
  cbar.TicksMode='manual';
  cbar.Ticks=[0:1/18:1];
  cbar.TickLabelsMode='manual';
  cbar.TickLabels={'0';'10';'20';'30';'40';'50';'60';'70';'80';'90';...
    '100';'110';'120';'130';'140';'150';'160';'170';'180'};
  cbar.Label.String='Epicentral Distance (degrees)';
end
cbar.Location='eastoutside';
cbar.Label.Rotation=270;
cbar.Label.Position=(cbar.Label.Position).*[5/4 1 1];

% Add plot title
titlestr1=sprintf('%s by Earthquakes of Magnitude %s in %s (E/W)',measstr,...
  magstr2,yrstr2);
title({titlestr1;titlestr2;titlestr3})
nowaxis=gca;
plottitle=nowaxis.Title;
plottitle.FontSize=9;
% Horizontal axis label
xlabel('Time (s) since Earthquake Origin')
horzlabel=nowaxis.XLabel;
horzlabel.FontSize=9.5;
% Vertical Axis Ticks and Label
nowaxis.YTickMode='manual';
yticks=[];
yticklabels={};
if 1.1*maxdist>100
  for i=1:floor(1.1*maxdist/20)
    yticks=[yticks; 20*75000*i];
    yticklabels=vertcat(yticklabels,sprintf('%d',20*i));
  end
else
  for i=1:floor(1.1*maxdist/10)
    yticks=[yticks; 10*75000*i];
    yticklabels=vertcat(yticklabels,sprintf('%d',10*i));
  end
end
nowaxis.YTick=yticks;
nowaxis.YTickLabelMode='manual';
nowaxis.YTickLabel=yticklabels;
ylabel('Distance (deg) from Earthquake to Station')
vertlabel=nowaxis.YLabel;
vertlabel.FontSize=9.5;

% If saving this figure:
if saveplots==1
  if colorcode==0
    figname=sprintf('M%s.%s.Z.%g%g%g%g_f%gs%gs.eps',magstr,yrstr,...
      frequency(1),frequency(2),frequency(3),frequency(4),fastsw,...
      slowsw);
  else
    figname=sprintf('M%s.%s.Z.%g%g%g%g_f%gs%gs_cc%d.eps',magstr,yrstr,...
      frequency(1),frequency(2),frequency(3),frequency(4),fastsw,...
      slowsw,colorcode);
  end
  % Save figure
  figname2=figdisp(figname,[],[],1,[],'epstopdf');
  % Move figure to save directory
  if ~isempty(savedir)
    [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
    figname=fullfile(savedir,figname);
  else
    figname=figname2;
  end
end


% Add figure handles to output
seishdls=[zfigure; yfigure; xfigure];   
