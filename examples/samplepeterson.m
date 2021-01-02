% samplepeterson.m

% Example of plotting the Peterson Noise Model in terms of ground 
% displacement.

% Set the parameters and input arguments
measval=0;
datadir=fullfile(pwd,'datafiles');
lncsv=fullfile(datadir,'nlnm.csv');
hncsv=fullfile(datadir,'nhnm.csv');
saveplot=1;
% Insert your own directory to save your plots!
savedir=fullfile(pwd,'figures');
% Label the frequencies of 1.5 Hz and 5 Hz
freqband=[1.5 5];
% Plot against frequency
xval=0;
[fighdl1,figname1]=pnm(measval,xval,lncsv,hncsv,freqband,saveplot,savedir);
% Plot against period
xval=1;
[fighdl2,figname2]=pnm(measval,xval,lncsv,hncsv,freqband,saveplot,savedir);

