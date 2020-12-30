% sampleweather.m

% An example in plotting weather data, collected by an instrument
% stationed at Guyot Hall, Princeton University.

% Plot the hourly-averaged root mean squared (RMS) wind 
% velocity, over several months in 2020

% Set input parameters
measval2=2;
rmoutlier=[];
tzone='America/New_York';
tzlabel='ET';
% February through May
starttime=datetime(2020,2,1,0,0,0);
starttime.TimeZone='America/New_York';
finaltime=datetime(2020,5,31,23,0,0);
finaltime.TimeZone='America/New_York';
[~,csv201mw,~,~]=vairmshr(measval2,starttime,finaltime,tzone,...
  tzlabel,rmoutlier);
% June through August
starttime=datetime(2020,6,1,0,0,0);
starttime.TimeZone='America/New_York';
finaltime=datetime(2020,8,31,23,0,0);
finaltime.TimeZone='America/New_York';
[~,csv202mw,~,~]=vairmshr(measval2,starttime,finaltime,tzone,...
  tzlabel,rmoutlier);

% As an exercise, let's use adjrms.m to combine the two CSV files 
% with the RMS values of wind velocity for every hour, into one CSV
% file, with data from February through the end of August
oldcsvs={csv201mw;csv202mw};
starttime=datetime(2020,2,1,0,0,0);
starttime.TimeZone='America/New_York';
finaltime=datetime(2020,8,31,23,59,59);
finaltime.TimeZone='America/New_York';
valtype=1;
newname='RMSMWSinmps_HRLYAVG2020JD032to244_ET.csv';
% New file!
allmws20=adjrms(oldcsvs,newname,valtype,starttime,finaltime,tzone);

% Move these files to the datafiles directory
datadir=fullfile(pwd,'datafiles');
[status,cmdout]=system(sprintf('mv %s datafiles',csv201mw));
[status,cmdout]=system(sprintf('mv %s datafiles',csv202mw));
[status,cmdout]=system(sprintf('mv %s datafiles',allmws20));


%%%%%
% Note: sometimes, the weather data file might be formatted incorrectly for 
% a few times in 2018. In that case, the program will prommpt you to 
% examine the "problem file" by hand, remove the line causing the issue, 
% and resume the program. 
%%%%%

% Now plot the RMS wind speed from February through August, in one time
% series:
allmws20=fullfile(datadir,newname);
measval=2;
prclimit=100;
saveplot=1;
% Insert your own directory!
savedir=fullfile(pwd,'figures');
% No legend, no need to "pause" the program to adjust plot cosmetics, 
% no vertical lines, no custom plot names, etc
addlegend=0;
adjustplot=0;
vertlines=[];
vertlinelabs=[];
customtitle='';
customxlbl='';
customfname='';
% Plot the weather data as a grey line plot
lineclr=[0.3 0.3 0.3];
[rmsplot,figname]=vairmsplot(allmws20,...
  2,starttime,finaltime,tzone,tzlabel,100,saveplot,savedir,0,0,...
  [],[],'','','',[0.3 0.3 0.3]);


