% samplerms.m

% Some examples in computing and plotting the root mean square (RMS) 
% of ground motion, recorded by a broadband Nanometrics three-component
% seismometer in Guyot Hall, Princeton University.

%%%%%%%%%%
% Example 1: 
% Compute and plot the root mean squared ground displacement for 
% every hour for March through April 2020, Eastern Time. We will do so
% in the vertical and horizontal (combined North-South and East-West) 
% components.

% To show cultural noise, we will filter these data from 1.5 to 5 Hz. 
% We will also remove outliers from each hour, to remove signals not 
% associated with day-to-day human activities, like earthquakes. 
% Feel free to adjust the parameters below!

% Set directories to save the data and figures
datadir=fullfile(pwd,'/datafiles/');
savedir=fullfile(pwd,'/figures/');

% Set the input arguments
measval=0;
frequency=[0.75 1.5 5.0 10.0];
tzone='America/New_York';
tzlabel='ET';
% Define the outliers as signals, within each hour, +/- 2.5 median
% absolute deviations from the median
rmoutlier=[1 2.5];
starttime3=datetime(2020,3,1,0,0,0);
starttime3.TimeZone='America/New_York';
finaltime3=datetime(2020,3,31,23,0,0);
finaltime3.TimeZone='America/New_York';
%
starttime4=datetime(2020,4,1,0,0,0);
starttime4.TimeZone='America/New_York';
finaltime4=datetime(2020,4,30,23,0,0);
finaltime4.TimeZone='America/New_York';

% Run the code
% March
[~,seiscsv3,probtimes3,mmstimes3,msctimes3,mdtimes3]=guyotrmsseishr(measval,...
    starttime3,finaltime3,frequency,rmoutlier,tzone,tzlabel);
[status,cmdout]=system('rmm PP.*.SAC');
pause(0.5)
[status,cmdout]=system(sprintf('mv %s datafiles',seiscsv3));
seiscsv3=fullfile(datadir,seiscsv3);
% We should get file names like the following:
% csvfile='RMSDinNM_HR2020JD061to091_ET_F0.751.5510_YYYYMMDD_rmMAD2.50+.csv';
%
% where 'YYYYMMDD' is the year (YYYY), month (MM), and day (DD) when you 
% run this code.
if exist(probtimes3)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',probtimes3));
end
if exist(mmstimes3)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',mmstimes3));
end
if exist(msctimes3)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',msctimes3));
end
if exist(mdtimes3)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',mdtimes3));
end
% Note: there might be issues present in the data, such as the .miniseed
% file being missing or not converting correctly to SAC. The output
% arguments listed to the right of 'csvfile' keep track of that!

% April
[~,seiscsv4,probtimes4,mmstimes4,msctimes4,mdtimes4]=guyotrmsseishr(measval,...
    starttime4,finaltime4,frequency,rmoutlier,tzone,tzlabel);
[status,cmdout]=system('rmm PP.*.SAC');
pause(0.5)
[status,cmdout]=system(sprintf('mv %s datafiles',seiscsv4));
seiscsv4=fullfile(datadir,seiscsv4);
%
if exist(probtimes4)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',probtimes4));
end
if exist(mmstimes4)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',mmstimes4));
end
if exist(msctimes4)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',msctimes4));
end
if exist(mdtimes4)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',mdtimes4));
end


% For the sake of practice, let's combine the CSV files for March and
% April 2020 into one file
oldcsvs={seiscsv3;seiscsv4};
starttime=datetime(2020,3,1,0,0,0);
starttime.TimeZone='America/New_York';
finaltime=datetime(2020,4,30,23,59,59);
finaltime.TimeZone='America/New_York';
valtype=0;
newname='RMSDinNM_HR2020JD061to121_ET_F0.751.5510_rmMAD2.50+.csv';
seiscsv20=adjrms(oldcsvs,newname,valtype,starttime,finaltime,tzone);
% Move to the datafiles directory
[status,cmdout]=system(sprintf('mv %s datafiles',seiscsv20));
seiscsv20=fullfile(datadir,seiscsv20);


%%%%%%%%
% Now let's plot these data as a time series
% Set function inputs
% 
% If we had the data, we would put the CSV files for (left to right) 
% 2017, 2018, 2019, and 2020. But for now let's stick to 2020
csvfiles={'';'';'';seiscsv20};
rmstype=1;
saveplot=1;
xyh=[1 0];
adjustplot=0;
yrsplotted=2020;
addlegend=1;
% Don't superimpose weather variables, for now
wthrinfo={0; []; []};
% Customize appearance of the line graph
lineclrs={[1 .65 0];[0 0.7 0.9];[0 0.85 0];[1 0 0.25]};
linewdh=[.5 .5 .5 .75];
linestyls={'-';'-';'-';'-'};
% No custom figure/axis names
customtitle=[];
customxlabel=[];
customfigname=[];
% Let's also label when the New Jersey 'stay-at-home' order began:
% 21:00:00 Eastern Time on March 21, 2020
vertdate=datetime(2020,3,21,21,0,0);
vertdate.TimeZone='America/New_York';
vertlines=[vertdate];
vertclrs={[.75 0 0]};
vertlinelabs={};
%
[rmsplot,axeshdl,figname]=guyotrmsplot(csvfiles,...
  measval,rmstype,yrsplotted,starttime,finaltime,tzone,tzlabel,...
  rmoutlier,saveplot,savedir,addlegend,frequency,xyh,wthrinfo,adjustplot,...
  vertlines,vertclrs,vertlinelabs,customtitle,customxlabel,...
  customfigname,lineclrs,linewdh,linestyls);


%%%%%%%%%%%%%%%%%
% Example 2: 
% Same as above, but let's now superimpose the hourly RMS wind speed,
% also recorded at Guyot Hall over the same time period

% Set input parameters
measval2=2;
rmoutlier2=[];
finaltime2=datetime(2020,4,30,23,0,0);
finaltime2.TimeZone='America/New_York';
[~,csv20mw,~,~]=vairmshr(measval2,starttime,finaltime2,tzone,...
  tzlabel,rmoutlier2);
% Move this to the datafiles directory
[status,cmdout]=system(sprintf('mv %s datafiles',csv20mw));
csv20mw=fullfile(datadir,csv20mw);

% Plot RMS wind speed AND ground displacement!
wthrinfo={1;csv20mw;2};
[rmsplot,axeshdl,figname]=guyotrmsplot(csvfiles,...
  measval,rmstype,yrsplotted,starttime,finaltime,tzone,tzlabel,...
  rmoutlier,saveplot,savedir,addlegend,frequency,xyh,wthrinfo,adjustplot,...
  vertlines,vertclrs,vertlinelabs,customtitle,customxlabel,...
  customfigname,lineclrs,linewdh,linestyls);


%%%%%%%%%%%%%%%%%
% Example 3:
% How do the RMS wind speeds correlate with ground displacement in 
% March-April 2020? Let's find out.
% 
% For more on wind speeds and ground displacement, see 
% Withers et al. (1996), High-frequency analysis of seismic background 
% noise as a function of wind speed and shallow depth
% and 
% Johnson et al. (2019), DOI: 10.1029/2018JB017151

% Set input parameters
measval1=0;
rmoutlier1=[1 2.5];
measval2=2;
rmoutlier2=[];
% For now, we won't constrain the wind speeds, but feel free to 
% do so with this parameter:
maxvals=[];
[outputtbl,figurehdl]=vaivseisrms(seiscsv20,measval1,frequency,...
  rmoutlier1,csv20mw,measval2,rmoutlier2,starttime,finaltime,tzone,...
  tzlabel,xyh,maxvals,saveplot,savedir);


%%%%%%%%%%%%%%%%
% Example 4:
% Lockdowns imposed as a result of the 2020 coronavirus pandemic led to
% an unparalleled decrease on human activity on Princeton's campus. 
% It would be interesting to visualize how that decrease manifests in the
% seismic record!

% For that, let's compare the amount of RMS ground displacement in 
% March through April 2020 (which we computed), relative to February 
% 2020 (which we will compute) using seiscsv.m, seiscsvplot.m


% First, let's retrieve the RMS ground displacement data for February 
measval=0;
frequency=[0.75 1.5 5.0 10.0];
starttime=datetime(2020,2,1,0,0,0);
starttime.TimeZone='America/New_York';
finaltime=datetime(2020,2,29,23,0,0);
finaltime.TimeZone='America/New_York';
rmoutlier=[1 2.5];
[~,seiscsv2,probtimes2,mmstimes2,msctimes2,mdtimes2]=guyotrmsseishr(...
    measval,starttime,finaltime,frequency,rmoutlier,tzone,tzlabel);
[status,cmdout]=system('rmm PP.*.SAC');
[status,cmdout]=system(sprintf('mv %s datafiles',seiscsv2));
seiscsv2=fullfile(datadir,seiscsv2);
%
if exist(probtimes2)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',probtimes2));
end
if exist(mmstimes2)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',mmstimes2));
end
if exist(msctimes2)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',msctimes2));
end
if exist(mdtimes2)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',mdtimes2));
end


% Next, use seiscsv.m (which then calls seiscsvplot.m) to create color
% coded bar plots, showing the percent changes in March and April
% 2020, relative to February 2020
csvfiles={seiscsv2;seiscsv3;seiscsv4};
timeinfo=1;
avgmode=0;
measval=0;
frequency=[0.75 1.5 5 10];
xyh=0;
tzone='America/New_York';
tzlabel='ET';
makeplot=1;
saveplot=1;
[seistbls,seiscsvs]=seiscsv(csvfiles,timeinfo,avgmode,measval,...
  frequency,xyh,tzone,tzlabel,makeplot,saveplot,savedir);


%%%%%%%%%%%%%%%%%%%
% Examples 5-6: 
% Let's compare the ground displacement trends in February-April 2020, 
% with those of 2018!
measval=0;
frequency=[0.75 1.5 5.0 10.0];
tzone='America/New_York';
tzlabel='ET';
rmoutlier=[1 2.5];

% First, compute the hourly RMS ground displacement in 2018
% February
starttime2=datetime(2018,2,1,0,0,0);
starttime2.TimeZone='America/New_York';
finaltime2=datetime(2018,2,28,23,0,0);
finaltime2.TimeZone='America/New_York';
[~,seiscsv218,probtimes218,mmstimes218,msctimes218,mdtimes218]=...
    guyotrmsseishr(...
    measval,starttime2,finaltime2,frequency,rmoutlier,tzone,tzlabel);
[status,cmdout]=system('rmm PP.*.SAC');
[status,cmdout]=system(sprintf('mv %s datafiles',seiscsv218));
seiscsv218=fullfile(datadir,seiscsv218);
%
if exist(probtimes218)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',probtimes218));
end
if exist(mmstimes218)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',mmstimes218));
end
if exist(msctimes218)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',msctimes218));
end
if exist(mdtimes218)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',mdtimes218));
end

% March
starttime3=datetime(2018,3,1,0,0,0);
starttime3.TimeZone='America/New_York';
finaltime3=datetime(2018,3,31,23,0,0);
finaltime3.TimeZone='America/New_York';
[~,seiscsv318,probtimes318,mmstimes318,msctimes318,mdtimes318]=...
    guyotrmsseishr(...
    measval,starttime3,finaltime3,frequency,rmoutlier,tzone,tzlabel);
[status,cmdout]=system('rmm PP.*.SAC');
[status,cmdout]=system(sprintf('mv %s datafiles',seiscsv318));
seiscsv318=fullfile(datadir,seiscsv318);
%
if exist(probtimes318)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',probtimes318));
end
if exist(mmstimes318)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',mmstimes318));
end
if exist(msctimes318)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',msctimes318));
end
if exist(mdtimes318)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',mdtimes318));
end

% April
starttime4=datetime(2018,4,1,0,0,0);
starttime4.TimeZone='America/New_York';
finaltime4=datetime(2018,4,30,23,0,0);
finaltime4.TimeZone='America/New_York';
[~,seiscsv418,probtimes418,mmstimes418,msctimes418,mdtimes418]=...
    guyotrmsseishr(...
    measval,starttime4,finaltime4,frequency,rmoutlier,tzone,tzlabel);
[status,cmdout]=system('rmm PP.*.SAC');
[status,cmdout]=system(sprintf('mv %s datafiles',seiscsv418));
seiscsv418=fullfile(datadir,seiscsv418);
%
if exist(probtimes418)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',probtimes418));
end
if exist(mmstimes418)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',mmstimes418));
end
if exist(msctimes418)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',msctimes418));
end
if exist(mdtimes418)==2
  [status,cmdout]=system(sprintf('mv %s datafiles',mdtimes418));
end


% Example 5
% Make a comparative plot, between February-April 2018 and 
% February-April 2020
csvfiles={seiscsv218;seiscsv2;seiscsv318;seiscsv3;seiscsv418;seiscsv4};
timeinfo=2;
avgmode=0;
measval=0;
frequency=[0.75 1.5 5 10];
xyh=0;
tzone='America/New_York';
tzlabel='ET';
makeplot=1;
saveplot=1;
[seistbls,seiscsvs]=seiscsv(csvfiles,timeinfo,avgmode,measval,...
  frequency,xyh,tzone,tzlabel,makeplot,saveplot,savedir);



% And make a time series superimposing those times
% Combine February-April 2018 and 2020
oldcsvs={seiscsv2;seiscsv3;seiscsv4};
starttime=datetime(2020,2,1,0,0,0);
starttime.TimeZone='America/New_York';
finaltime=datetime(2020,4,30,23,59,59);
finaltime.TimeZone='America/New_York';
valtype=0;
newname='RMSDinNM_HR2020JD032to121_ET_F0.751.5510_rmMAD2.50+.csv';
seiscsv20=adjrms(oldcsvs,newname,valtype,starttime,finaltime,tzone);
[status,cmdout]=system(sprintf('mv %s datafiles',seiscsv20));
seiscsv20=fullfile(datadir,seiscsv20);
%
oldcsvs={seiscsv218;seiscsv318;seiscsv418};
starttime2=datetime(2018,2,1,0,0,0);
starttime2.TimeZone='America/New_York';
finaltime2=datetime(2018,4,30,23,59,59);
finaltime2.TimeZone='America/New_York';
newname='RMSDinNM_HR2018JD032to120_ET_F0.751.5510_rmMAD2.50+.csv';
seiscsv18=adjrms(oldcsvs,newname,valtype,starttime2,finaltime2,tzone);
[status,cmdout]=system(sprintf('mv %s datafiles',seiscsv18));
seiscsv18=fullfile(datadir,seiscsv18);

% Example 6
% Time series
csvfiles={'';seiscsv18;'';seiscsv20};
rmstype=1;
saveplot=1;
xyh=[1 0];
adjustplot=0;
yrsplotted=[2018 2020];
addlegend=1;
% Don't superimpose weather variables, for now
wthrinfo={0; []; []};
% Customize appearance of the line graph
lineclrs={[1 .65 0];[0 0.7 0.9];[0 0.85 0];[1 0 0.25]};
linewdh=[.5 .5 .5 .75];
linestyls={'-';'-';'-';'-'};
% No custom figure/axis names
customtitle=[];
customxlabel=[];
customfigname=[];
% Label when the New Jersey 'stay-at-home' order began
vertdate=datetime(2020,3,21,21,0,0);
vertdate.TimeZone='America/New_York';
vertlines=[vertdate];
vertclrs={[.75 0 0]};
vertlinelabs={};
%
[rmsplot,axeshdl,figname]=guyotrmsplot(csvfiles,...
  measval,rmstype,yrsplotted,starttime,finaltime,tzone,tzlabel,...
  rmoutlier,saveplot,savedir,addlegend,frequency,xyh,wthrinfo,adjustplot,...
  vertlines,vertclrs,vertlinelabs,customtitle,customxlabel,...
  customfigname,lineclrs,linewdh,linestyls);


