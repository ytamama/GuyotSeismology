function [figurehdl,figname]=pnm(measval,xval,lncsv,hncsv,...
  freqband,saveplot,savedir)
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
%        0 : Frequency (default; with period on the top x axis)
%        1 : Period 
% lncsv : CSV file containing the values for the piecewise functions that
%         construct the NLNM. See nlnm.csv 
%         Enter the full path to that file if necessary.
%         Default: 'nlnm.csv'
% hncsv : CSV file containing the values for the piecewise functions that
%         construct the NHNM. See nhnm.csv 
%         Enter the full path to that file if necessary.
%         Default: 'nhnm.csv'
% freqband : If we want to plot any frequency bands, enter a 2 element
%            array with the low and high end of the frequency band!
%            Default: Empty array, for nothing
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
% References:
% Peterson, J. R. Observations and modeling of seismic background noise. 
%    http://pubs.er.usgs.gov/publication/ofr93322 (1993). Last Accessed
%    Nov 4 2020
% Uses defval.m, shrink.m, figdisp.m, xtraxis.m, from 
% csdms-contrib/slepian_alpha
%
% For more on decibels, see Bormann (2015), Seismic Noise
% DOI : 10.1007/978-3-642-36197-5_289-1
%
% Last Modified by Yuri Tamama, 01/02/2021
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('measval',0)
defval('xval',0)
defval('lncsv','nlnm.csv')
defval('hncsv','nhnm.csv')
defval('freqband',[])
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
yunits={'dB (m^2/Hz)';'dB ((m/s)^2/Hz)';'dB ((m/s^2)^2/Hz)'};
figurehdl=figure();
lnplot=plot(lnx,nlnm);
hold on
hnplot=plot(hnx,nhnm);
ax=gca;
ax.YLim=[-250 150];
ax.XScale='log';
% Scale the figure
ax.Position(4)=.65;
% Plot the frequency band
if ~isempty(freqband)
  if xval==0
    val1=freqband(1);
    val2=freqband(2);
  else
    val1=1/freqband(1);
    val2=1/freqband(2);
  end
  val1str=num2str(val1);
  vline1=line([val1 val1],ylim,'LineStyle','--','Color',[0.35 0.35 0.35]);
  vline1.HandleVisibility='off';
  val2str=num2str(val2);
  vline2=line([val2 val2],ylim,'LineStyle','--','Color',[0.35 0.35 0.35]);
  vline2.HandleVisibility='off';
end
% Title
title('Peterson (1993) Noise Model')
ax.Title.Units='normalized';
ax.Title.Position(2)=1.175;
% Axis labels and legend
if ~isempty(freqband)
  plotlgd=legend({'New Low Noise Model';'New High Noise Model'});
else
  plotlgd=legend({'New Low Noise Model';'New High Noise Model'});
end
if xval==0
  xlabel('Frequency (Hz)')
  ax.XLabel.FontSize=10;
  ax.XLim=[1e-5 10];
  plotlgd.Location='southwest';
  % Add an axis for the period, as well
  x2pos=[1e-4 1e-2 1];
  x2lbls={'10000';'100';'1'};
  newax=xtraxis(ax,x2pos,x2lbls,'Period (s)',[],[],[]);
  newax.XLim=[0.1 1e5];
  newax.XTick=[1 1e2 1e4];
  newax.XDir='reverse';
  newax.XTickLabel={'1';'100';'10000'};
  newax.XLabel.FontSize=10;
else
  xlabel('Period (s)')
  ax.XLim=[0.1 10^5];
  plotlgd.Location='southeast';
end
ax.YLabel.String=sprintf('Power Spectral Density %s',yunits{measval+1});
hold off
% Adjust plot size
figurehdl.Units='normalized';
figurehdl.Position(3)=.75;

if saveplot==1
  yunit={'disp';'vel';'acc'};
  xunit={'freq';'pd'};
  if ~isempty(freqband)
    figname=sprintf('PetersonNoise_%s_%s_%s%s.eps',yunit{measval+1},...
      xunit{xval+1},val1str,val2str);  
  else
    figname=sprintf('PetersonNoise_%s_%s.eps',yunit{measval+1},...
      xunit{xval+1});   
  end
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

