function [figurehdls,saccsv]=plotsacevents(makefiles,saccsv,measval,frequency,...
  magrange,years,timeorsw,fastsw,slowsw,intend,staloc,stacode,...
  stalalo,samplefreq,saveplots,savedir,allorrand)
%
% Function to plot multiple earthquakes, of a given magnitude and year 
% range, by calling plotsacdata.m multiple times. In each plot, the 
% upper and lower surface wave speeds inputted will be marked. 
% 
% INPUTS
% makefiles : Do we need to make SAC files of these events?
%             0 - No, they exist 
%             1 - Yes, make SAC files (Default)
% saccsv : The name of a CSV file containing the names of the existing
%          SAC files, if applicable. Enter an empty string if not
%          applicable.
%          Default: ''
% measval : Are we plotting displacement, velocity, or acceleration?
%           0 for displacement in nm (default)
%           1 for velocity in nm/s 
%           2 for acceleration in nm/(s^2)
% frequency : The frequencies to which the data will be filtered during
%             instrument correction
%             Default: [0.01 0.02 10.00 20.00] Hz
% magrange : The range of magnitudes of the events we wish to plot, 
%            entered as a vector of length 2 
%            Default: [7.5 10] (Earthquakes with M>=7.5)
%            The maximum magnitude between 2017-2019 is 8.2;
% 
%              Note: The magnitudes are inclusive on both ends!
% years : In which year(s) (from 2017-2019) will we look for events? 
%         Enter a vector if considering multiple years.
%         Default: 2019
% timeorsw : Are we defining our plotting time interval (if we want to 
%            cut it) by a time span or by surface wave velocities?
%            1 - Time span (in seconds)
%            2 - Surface wave velocities (km/s)
%                NOTE: Selecting this option means we are plotting an event
% fastsw : The upper threshold for surface wave velocity in km/s, marking 
%          the beginning of the surface wave window
%          Default: 5 km/s
% slowsw : The lower threshold for surface wave velocity in km/s, marking
%          the end of the surface wave window
%          Default: 2.5 km/s
% intend : If we want to cut our time interval, at what time, in seconds, 
%          should we end our time series? 
%          Default: 1800s
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
% samplefreq : How many samples per second were taken by the seismometer?
%              Default: 100
% saveplots : Do we want to save our plots?
%            0 - No (default)
%            1 - Yes 
% savedir : Where do we save our plot? By default, it will be saved in 
%           your current working directory. 
% allorrand : Do we want to have all applicable events, plotted, or just
%             a randomly selected sample?
%             0 or empty - Plot all
%             Any integer greater than 0 - Select a sample of that size
%
% Note: We can only make SAC files from scratch for the S0001 (first) 
%       seismometer in the Guyot Hall network.
% 
% OUTPUTS
% figurehdls : The figure handles for each event plotted
% saccsv : A csv file containing the names of the SAC files that were 
%          plotted
% 
% References
% Uses defval.m, in csdms-contrib/slepian_alpha 
% Guyot Hall latitude and longitude from guyotphysics.m in 
% csdms-contrib/slepian_zero
% Uses the result of mcms2evt, in csdms-contrib/slepian_oscar
% Uses IRIS's distance-azimuth web service (see irisazimuth.m)
% 
% For more on SAC, see Helffrich et al., (2013), The Seismic Analysis 
% Code: a Primer and User's Guide
%
% Last Modified by Yuri Tamama, 12/27/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('makefiles',1);
defval('saccsv','');
defval('measval',0);
defval('frequency',[0.01 0.02 10.00 20.00]); 
defval('magrange',[7.5 10]);
defval('years',2019);
defval('fastsw',5);
defval('slowsw',2.5);
defval('intend',1800);
defval('staloc','Guyot Hall, Princeton University')
defval('stacode','PP.S0001')
defval('stalalo',[40.34585 -74.65475]);
defval('samplefreq',100);
defval('saveplots',0);
defval('savedir','');
defval('allorrand',[]);

% Specify necessary directories - insert your own!
datadir=getenv('MC0');

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
magrange=sort(magrange,'ascend');
mgcol=eqdata.Var6;
eqdata=eqdata(mgcol>=magrange(1) & mgcol<magrange(2),:);
% Inputted < for today, 8/10/2020, to avoid overlapping events
numevts=size(eqdata);
numevts=numevts(1);
% If randomly selecting events
if ~isempty(allorrand)
  if allorrand>0
    randinds=randi(numevts,allorrand,1);
    numevts=allorrand;
  end
else
  randinds=[];
end

% Find how long of an interval we wish to plot for all earthquakes
maxtime=0;
maxdist=0;
% tlens=zeros(numevts,1);
for i=1:numevts
  if isempty(randinds)
    rowdata=eqdata(i,:);
  else
    randind=randinds(i);
    rowdata=eqdata(randind,:);
  end
  evlalo=[rowdata.Var3 rowdata.Var4];
  % Distance
  [~,~,~,distmtr]=irisazimuth(evlalo,stalalo);
  distkm=distmtr/1000;
  % Maximum distance (degrees)
  distdeg=rowdata.Var7;
  if distdeg>maxdist
    maxdist=distdeg;
  end
  % Time
  if timeorsw==2
    totaltime=round(distkm/slowsw,2);
    % Maximum time
    if totaltime>maxtime
      maxtime=totaltime;
    end
  else
    maxtime=intend;
  end
end

% Generate SAC files, if that hasn't been done already!
if makefiles==1 || isempty(saccsv)
  corrfilesx={};
  corrfilesy={};
  corrfilesz={};
  distdegs2=[];
  evtids=[];
  for i=1:numevts
    if isempty(randinds)
      rowdata=eqdata(i,:);
    else
      randind=randinds(i);
      rowdata=eqdata(randind,:);
    end
    % Record event ID and distance of each event
    evtids=[evtids; rowdata.Var1];
    distdegs2=[distdegs2; rowdata.Var7];
    % Cut SAC files based on time when creating event intervals
    intend=maxtime+100;
    corrfiles=mcevt2sac(rowdata,measval,timeorsw,intend,frequency);
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
  % Put corrected SAC file names in a table, along with event ID and 
  % distance
  sactable=table(evtids,distdegs2,corrfilesx,corrfilesy,corrfilesz);
  if length(magrange)>1
    if magrange(2)>8.2
      magstr=sprintf('%g+',magrange(1));
    elseif magrange(1)<-1.69
      magstr=sprintf('%g-',magrange(2));
    else
      magstr=sprintf('%gto%g',magrange(1),magrange(2));
    end
  else
    magstr=num2str(magrange(1));
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
  if measval==0
    saccsv=sprintf('%s.disp.M%s.%s.%g%g%g%g.f%gs%g.csv',stacode,magstr,yrstr,...
      frequency(1),frequency(2),frequency(3),frequency(4),fastsw,slowsw);
  elseif measval==1
    saccsv=sprintf('%s.vel.M%s.%s.%g%g%g%g.f%gs%g.csv',stacode,magstr,yrstr,...
      frequency(1),frequency(2),frequency(3),frequency(4),fastsw,slowsw);
  else
    saccsv=sprintf('%s.acc.M%s.%s.%g%g%g%g.f%gs%g.csv',stacode,magstr,yrstr,...
      frequency(1),frequency(2),frequency(3),frequency(4),fastsw,slowsw);
  end
  writetable(sactable,saccsv);  
else
  sactable=readtable(saccsv,'Delimiter',',');
end

% Iterate through the events/files, and make a seismogram of each event
evtidlist=sactable.evtids;
filesx=sactable.corrfilesx;
filesy=sactable.corrfilesy;
filesz=sactable.corrfilesz;

figurehdls=[];
for i=1:numevts
  newfig=figure();
  soleplot=1;
  xfile=filesx{i};
  yfile=filesy{i};
  zfile=filesz{i};
  sacfiles={zfile;yfile;xfile};
  plotorder=[1 2 3];
  numsubplots=3;
  plotall=1;
  stalbl=0;
  evtornot=1;
  if isempty(randinds)
    rowdata=eqdata(i,:);
  else
    randind=randinds(i);
    rowdata=eqdata(randind,:);
  end
  evtid=rowdata.Var1;
  evtid2=evtidlist(i);
  plotarrivals=1;
  emptycount=0;
  for f=1:length(sacfiles)
    sacfile=sacfiles{f};
    if exist(sacfile)==0
      emptycount=emptycount+1;
    end
  end    
  if emptycount==length(sacfiles)
    fprintf('Event ID %d cannot be plotted, for data do not exist.',evtid);
    fprintf('\n')
    continue;
  end
  % Check that the event ID we'll list in our plot is actually the 
  % event ID of the data we're plotting
  if evtid~=evtid2
    disp('Check that your SAC files match up with rowdata.')
    return;
  end
  % Plot event and save the plots if desired
  if timeorsw==1
    plotsw=0;
    plotsacdata(soleplot,sacfiles,plotorder,numsubplots,measval,frequency,...
      stalalo,staloc,stacode,samplefreq,plotall,stalbl,saveplots,...
      savedir,evtornot,rowdata,timeorsw,[],[],intend,plotsw,...
      plotarrivals)
  else
    plotsw=1;
    plotsacdata(soleplot,sacfiles,plotorder,numsubplots,measval,frequency,...
      stalalo,staloc,stacode,samplefreq,plotall,stalbl,saveplots,...
      savedir,evtornot,rowdata,timeorsw,fastsw,slowsw,intend,plotsw,...
      plotarrivals)
  end

  % Add figure handle to array
  figurehdls=[figurehdls; newfig];
end


% Go through each of the figures, making sure that the x axis is 
% scaled the same across all figures
for i=1:length(figurehdls)
  figurehdl=figurehdls(i);
  axes=figurehdl.Children;
  for c=1:length(axes)
    nowaxis=figurehdl.Children(c);
    nowaxis.XLim=[0 maxtime+50];
  end
end
