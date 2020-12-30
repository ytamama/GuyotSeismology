% sampleearthquake.m

% Example on plotting a seismogram of an earthquake, recorded by the
% broadband Nanometrics three-component seismometer in the basement of 
% Guyot Hall, Princeton University

% As an example, we will plot an earthquake with a magnitude of at least
% 7.5, so that we can see the signals.

% First, retrieve a list of events from IRIS web services that satisfies 
% this criterion, from 2018 to now:
sttime=datetime(2018,1,1,0,0,0);
sttime.TimeZone='UTC';
fintime=datetime('now');
fintime.TimeZone='UTC';
magrange=[7.5 10];
eqinfo={magrange;sttime;fintime;[]};
evttbl=irisevent(eqinfo);

% Type in evttbl in the command window! You should get a table showing you,
% the properties of various earthquakes, with one earthquake per row.
% In order, these properties should be the:
% IRIS Event ID, origin time (UTC), latitude, longitude, depth, distance
% (in degrees, calculated using the distance-azimuth web service), distance
% (in degrees, calculated using the traveltime web service), and the
% approximate arrival time at Guyot Hall (UTC; calculated using 
% traveltime) 

% Let's pick one of those earthquakes to plot
% For now, let's pick the last one on the list, a Magnitude 7.5
% on January 10, 2018

numevts=size(evttbl);
numevts=numevts(1);
rowdata=evttbl(numevts,:);

% In this example, let's plot a 1-hour long seismogram of ground 
% displacement. The signal will be filtered between 0.01 and 1 Hz.
% In addition to the radial and transverse components, the 
% vertical, North-South, and East-West components of ground motion will
% be plotted. 
% We won't be labeling the seismic phases in this example.

% Set the necessary parameters and arguments
measval=0;
timeorsw=1;
intend=3599.99;
timeinfo={timeorsw;intend;0};
makeplot=1;
saveplot=1;
% Insert your own directories to save the SAC files and the resulting
% seismogram!
plotdir=fullfile(pwd,'figures');
savedir=fullfile(pwd,'datafiles');
addphases=0;
% Plot the Z Y X T R components
spinfo={5;[1 2 3 4 5];{'r';'g';'b';[0 .75 .55];[0 .6 .75]}};
stainfo={[];[];[];[]};
frequency=[0.005 0.01 1 2];

% Generate the SAC files for all 5 components
coord=2;
corrpieces=mcevt2sac(rowdata,measval,frequency,timeinfo,...
  savedir,makeplot,saveplot,plotdir,coord,addphases);
% Plot all 5 SAC files!
soleplot=1;
corder={'Z';'Y';'X';'T';'R'};
evtinfo={1;rowdata;addphases};
saveplot=1;
figure();
[seisplot,axeshdl,figname]=...
  plotsacdata(soleplot,corrpieces,measval,{frequency},corder,spinfo,...
  stainfo,100,0,saveplot,savedir,evtinfo,timeinfo);


