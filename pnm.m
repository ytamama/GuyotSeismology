function [figurehdl,figname]=pnm(measval,xval,lncsv,hncsv,saveplot,savedir)
% 
% Function to plot the New Low Noise Model (NLNM) and New High Noise Model 
% (NHNM), developed by Peterson 1993 
% 
% INPUTS
% measval : Displacement, velocity, or acceleration?
%           0 : Displacement (default)
%           1 : Velocity
%           2 : Acceleration
% xval : Frequency (1/s) or period (s) on the x axis?
%        0 : Frequency (default)
%        1 : Period 
% lncsv : CSV file containing the values for the piecewise functions that
%         construct the NLNM. See nlnm.csv 
%         Enter the full path to that file if necessary.
%         Default: 'nlnm.csv'
% hncsv : CSV file containing the values for the piecewise functions that
%         construct the NHNM. See nhnm.csv 
%         Enter the full path to that file if necessary.
%         Default: 'nhnm.csv'
% saveplot : Do we want to save our figure?
%            0 - No (default)
%            1 - Yes
% savedir : Where do you want to save your plot?
%           Default: pwd
% 
% OUTPUTS
% figurehdl : The figure handle of our NLNM, NHNM plot
% figname : The name and path to our figure, if saving, as an EPS file
%           Note that we will also create a PNG version of our figure
%           using the same name
% 
% References
% Peterson, J. R. Observations and modeling of seismic background noise. 
%    http://pubs.er.usgs.gov/publication/ofr93322 (1993). Last Accessed
%    October 5 2020
% Uses defval.m, shrink.m, and figdisp.m from csdms-contrib/slepian_alpha
%
% Last Modified by Yuri Tamama, 10/05/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('measval',0)
defval('xval',0)
defval('lncsv','nlnm.csv')
defval('hncsv','nhnm.csv')
defval('saveplot',0)
defval('savedir',pwd)

% Load our data
% Columns, in order: P, A, B
lndata=readtable(lncsv,'Delimiter',',');
lnp=lndata.P;
lna=lndata.A;
lnb=lndata.B;
hndata=readtable(hncsv,'Delimiter',',');
hnp=hndata.P;
hna=hndata.A;
hnb=hndata.B;

% Equations for noise model:
if measval==0
% Displacement Noise Model : A + Blog10(P) + 20log10(P^2/(4pi^2))
  nlnm=lna+lnb.*log10(lnp)+20*log10((lnp.^2)/(4*pi*pi));
  nhnm=hna+hnb.*log10(hnp)+20*log10((hnp.^2)/(4*pi*pi));
elseif measval==1
% Velocity Noise Model : A + Blog10(P) + 20log10(P/(2pi)) 
  nlnm=lna+lnb.*log10(lnp)+20*log10((lnp)/(2*pi));
  nhnm=hna+hnb.*log10(hnp)+20*log10((hnp)/(2*pi));
else
% Acceleration Noise Model : A + Blog10(P)    
  nlnm=lna+lnb.*log10(lnp);
  nhnm=hna+hnb.*log10(hnp);
end
% X axis units: frequency or period?
if xval==0
  lnx=1./lnp;  
  hnx=1./hnp;
else
  lnx=lnp;
  hnx=hnp;
end

% Plot the noise model
yunits={'(m^2/Hz)';'((m/s)^2/Hz)';'((m/s^2)^2/Hz)'};
figurehdl=figure();
lnplot=plot(lnx,nlnm);
hold on
hnplot=plot(hnx,nhnm);
ax=gca;
ax.YLim=[-200 -60];
ax.XScale='log';
% Title
title('Peterson (1993) Noise Model')
% Axis labels and legend
if xval==0
  xlabel('Frequency (Hz)')
  ax.XLim=[1e-5 10];
  plotlgd=legend({'New Low Noise Model';'New High Noise Model'},...
    'Location','southwest');
else
  xlabel('Period (s)')
  ax.XLim=[0.1 10^5];
  plotlgd=legend({'New Low Noise Model';'New High Noise Model'},...
    'Location','northwest');
end
ylabel(sprintf('Power Spectral Density %s',yunits{measval+1}))
% Adjust plot size
figurehdl.Units='Normalized';
figurehdl.OuterPosition(3)=.75;
figurehdl.OuterPosition(4)=.8;
shrink(ax,1,1.25) 
hold off

if saveplot==1
  yunit={'disp';'vel';'acc'};
  xunit={'freq';'pd'};
  figname=sprintf('PetersonNoise_%s_%s.eps',yunit{measval+1},...
    xunit{xval+1});   
  % Save and move to our requested directory
  figname2=figdisp(figname,[],[],1,[],'epstopdf');
  [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
  figname=fullfile(savedir,figname);
  % Also have a PNG copy
  pause(1)
  fignamepng=figname;
  fignamepng(length(figname)-2:length(figname))='png';
  pngcmd=sprintf('convert -density 250 %s %s',figname,fignamepng);
  [status,cmdout]=system(pngcmd);
else
  figname='';  
end    

