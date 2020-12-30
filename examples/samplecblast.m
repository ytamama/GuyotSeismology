% samplecblast.m

% Example on plotting a seismogram of a campus blast, recorded by the
% broadband Nanometrics three-component seismometer in the basement of 
% Guyot Hall, Princeton University. A campus blast is defined as an 
% explosion, detonated by construction projects on Princeton 
% University's campus (information courtesy of Jonathan Baron, 
% Steven Hancock, and Thomas P. McKnight, of the Princeton University
% Office of Capital Projects)

% Let's plot one hour of seismic data, containing the campus blast from
% February 21, 2020

% Set directories to save the data and figures
datadir=fullfile(pwd,'/datafiles/');
savedir=fullfile(pwd,'/figures/');

% Set the input parameters
measval=0;
frequency=[0.75 1.5 5.0 10.0];
rmoutlier=[];
starttime=datetime(2020,2,21,11,0,0);
starttime.TimeZone='America/New_York';
starttime.TimeZone='UTC';
finaltime=datetime(2020,2,21,12,0,0);
finaltime.TimeZone='America/New_York';
finaltime.TimeZone='UTC';
makeplot=1;
saveplot=1;
% Plot the campus blast!
[corrfiles,figurehdl]=mstime2sac(measval,starttime,finaltime,...
  frequency,rmoutlier,savedir,makeplot,saveplot,savedir);


% Once you plot the data, use the command line interface to narrow down
% the signal to a 5 second interval surrounding the blast signal, with
% the following commands:

% Click on an axis to make it the current axis
ax=gca;
% 2563s to 2568s
ax.XLim=[2563 2568];
ax.XTick=2563:0.5:2568;
% Following two lines only for the bottommost subplot
ax.XTickLabel=[0 0.5 1 1.5 2 2.5 3 3.5 4 4.5 5];
ax.XLabel.String='Time (s) since 16:42:43 UTC 2020 February 21 (Day 52)';
% Following two lines only for the uppermost subplot
ax.Title.String{1}='Campus Blast from 2020 JD 052 16:42:43 UTC';
ax.Title.String{2}='Ground Displacement Recorded at Guyot Hall, Princeton University';
% Save the plot, using figdisp.m in csdms-contrib/slepian_alpha
figname='CB.2020.052.164243.D.5s.1.505.00.eps';
figname2=figdisp(figname,[],[],1,[],'epstopdf');
[status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
figname=fullfile(savedir,figname);


