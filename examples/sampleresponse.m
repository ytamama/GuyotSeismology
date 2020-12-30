% sampleresponse.m

% Plot an example of the frequency-amplitude and frequency-phase response
% plots!

netname='PP';
locname='00';
staname='S0001';
jd=300;
freqinfo=[10^-4,100,1000];
measval=0;
components={'Z';'Y';'X'};
saveplot=1;
% Choose your own directory to save your figures
savedir=fullfile(pwd,'figures');
respfmt='PP.S0001.00.HH%s.resp';
respfmt=fullfile(getenv('RESP'),respfmt);
yrname=2020;
chaname='HHZ';
fname20=iriseval(netname,locname,staname,chaname,yrname,jd,...
  freqinfo,fnameinz,measval);
% Move the data file to the /datafiles/ directory
[status,cmdout]=system(sprintf('mv %s datafiles',fname20));
datadir=fullfile(pwd,'datafiles');
fname20=fullfile(datadir,fname20);


% Plot the frequency-amplitude (fafig) and frequency-phase (fpfig) 
% responses!
measval=0;
% Label 1.5 Hz and 5 Hz
freqband=[1.5 5];
% Label the sensitivity limit and Nyquist frequency
minmax=[1/120; 50];
[fafig,fpfig]=framph(fname20,measval,yrname,jd,staname,netname,...
  freqband,minmax,saveplot,savedir);


