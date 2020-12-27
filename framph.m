function [fafig,fpfig]=framph(fname,measval,yrname,jd,staname,netname,...
  freqband,minmax,saveplot,savedir)
%
% Function to plot the frequency-amplitude and frequency-phase response of 
% a seismometer. The values for frequency, amplitude, and phase are 
% obtained using IRIS's evalresp software.
% 
% INPUTS
% fnames : The name of the file containing the frequency-amplitude-phase 
%          responses of a seismometer. 
% measval : In what units are we plotting the instrument response?
%           0 : Displacement
%           1 : Velocity
%           2 : Acceleration
%           3 : Default 
% yrname : The year that we entered into evalresp to create the inputted
%          files
% jd : The Julian Day that we entered into evalresp to create the inputted
%      files
% staname : The name of the station (default: 'S0001')
% netname : The name of the seismic network (default: 'PP')
% freqband : If we want to plot any frequency bands, enter a 2 element
%            array with the low and high end of the frequency band!
%            Default: Empty array, for nothing
% minmax : Input a two-element vector, with the first element indicating
%          the minimum frequency the seismometer is sensitive to, and the
%          second element indicating the maximum frequency 
%          Default: Empty array, for nothing
% saveplot : Do we wish to save our plot?
%            0 : No
%            1 : Yes (Default)
% savedir : Where do we save our plot? Specify the directory as a string!
%           Default: current working directory
%
% OUTPUTS
% fafig : The figure handle of the resulting frequency-amplitude plot
% fpfig : The figure handle of the resulting frquency-phase plot
%
% References
% Uses IRIS's evalresp program to create the frequency-amplitude-phase
% files, which are inputted into this program to plot
% Uses defval.m, decibel.m, figdisp.m, xtraxis.m in 
% csdms-contrib/slepian_alpha 
%
% For more on decibels, see Bormann (2015), Seismic Noise
% DOI : 10.1007/978-3-642-36197-5_289-1
% 
% Last Modified by Yuri Tamama, 12/27/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('staname','S0001')
defval('netname','PP')
defval('freqband',[])
defval('minmax',[])
defval('saveplot',1)
defval('savedir',pwd)

% Units
vallbl={'disp';'vel';'acc';'def'};

% Plot frequency amplitude response
fafig=figure();
fafig.Units='normalized';
fafig.OuterPosition(4)=.92;
ax=gca;
% Scale the figure
ax.Position(4)=.65;
% Load data and plot
fadata=readtable(fname,'Delimiter',' ');   
% Var 1 is frequency, Var 2 is amplitude
freqs=fadata.Var1;
amps=fadata.Var2;
% Convert amplitude to decibels, using decibel.m
ampsdb=decibel(amps);
evplot=plot(freqs,ampsdb);  
hold on
% Specify plot scale
ax.XScale='log';
ax.YScale='linear';
ax.XLabel.String='Frequency (Hz)';
ax.XLabel.FontSize=10;
ax.YLabel.String='Amplitude in dB';
ax.YLabel.FontSize=10.5;
ax.XLim=[min(freqs) max(freqs)];
ax.YLim=[min(ampsdb) max(ampsdb)+5];
ax.XTick=[0.0001 0.01 1 1e2];
% Title the plot
titlestr1='Frequency-Amplitude Response';
titlestr2=sprintf('of the %s Seismometer (Network %s)',...
  staname,netname); 
titlestr3=sprintf('%s Julian Day %s',num2str(yrname),num2str(jd));
ax.Title.String={titlestr1;titlestr2;titlestr3};
ax.Title.FontSize=10;
ax.Title.Units='normalized';
ax.Title.Position(2)=1.175;
% Frequency limits
freq1=num2str(freqs(1));
freqlast=num2str(freqs(length(freqs)));
% Plot the frequency bands
if ~isempty(freqband)
  val1str=num2str(freqband(1));
  vline1=line([freqband(1) freqband(1)],ylim,'LineStyle','--','Color',...
    [0.35 0.35 0.35]);
  vline1.HandleVisibility='off';
  val2str=num2str(freqband(2));
  vline2=line([freqband(2) freqband(2)],ylim,'LineStyle','--','Color',...
    [0.35 0.35 0.35]);
  vline2.HandleVisibility='off';
end
% Plot the minimum and maximum frequencies
if ~isempty(minmax)
  val3str=num2str(minmax(1));
  vline3=line([minmax(1) minmax(1)],ylim,'LineStyle','--','Color',...
    [0.35 0.35 0.35]);
  vline3.HandleVisibility='off';
  val4str=num2str(freqband(2));
  vline4=line([minmax(2) minmax(2)],ylim,'LineStyle','--','Color',...
    [0.35 0.35 0.35]);
  vline4.HandleVisibility='off';
end
% Add an axis for the period, as well
x2pos=[1e-4 1e-2 1 100];
x2lbls={'10000';'100';'1';'0.01';};
newax=xtraxis(ax,x2pos,x2lbls,'Period (s)',[],[],[]);
newax.XLim=[1/max(freqs) 1/min(freqs)];
newax.XTick=[0.01 1 1e2 1e4];
newax.XDir='reverse';
newax.XTickLabel={'0.01';'1';'100';'10000'};
newax.XLabel.FontSize=10;


% Save the plot
if saveplot==1
  if ~isempty(freqband)
    figname=sprintf('AmpFreq.%s.%s.%d.JD%d.%s.%sto%s_%s%s.eps',...
      netname,staname,yrname,jd,vallbl{measval+1},freq1,freqlast,...
      val1str,val2str);
  else
    figname=sprintf('AmpFreq.%s.%s.%d.JD%d.%s.%sto%s.eps',...
      netname,staname,yrname,jd,vallbl{measval+1},freq1,freqlast);
  end
  fignameb=figdisp(figname,[],[],1,[],'epstopdf');
  pause(0.25)
  if ~strcmpi(savedir,pwd)
    [status,cmdout]=system(sprintf('mv %s %s',fignameb,savedir));
    figname=fullfile(savedir,figname);
    pause(0.25)
  end
  % Make a PNG version
  fignamepng=strcat(figname(1:length(figname)-3),'png');
  [status,cmdout]=system(sprintf('convert -density 250 %s %s',figname,...
    fignamepng));
  pause(.5)
end


% Plot the frequency-phase response
fpfig=figure();
fpfig.Units='normalized';
fpfig.OuterPosition(4)=.92;
ax2=gca;
% Scale the figure
ax2.Position(4)=.65;
% Var 3 is phase
phases=fadata.Var3;
evplot2=plot(freqs,phases);  
hold on
% Specify plot scale
ax2.YLim=[.9*min(phases) 1.1*max(phases)];
ax2.XLim=[min(freqs) max(freqs)];
ax2.XTick=[0.0001 0.01 1 1e2];
ax2.YTick=[45 90 135 180 225 270 315];
ax2.XScale='log';
ax2.YScale='linear';
ax2.XLabel.String='Frequency (Hz)';
ax2.XLabel.FontSize=10;
ax2.YLabel.String='Phase Response (Degrees)';
ax2.YLabel.FontSize=10;
% Title the plot
titlestr1='Frequency-Phase Response';
titlestr2=sprintf('of the %s Seismometer (Network %s)',...
  staname,netname); 
titlestr3=sprintf('%s Julian Day %s',num2str(yrname),num2str(jd));
ax2.Title.String={titlestr1;titlestr2;titlestr3};
ax2.Title.FontSize=10;
ax2.Title.Units='normalized';
ax2.Title.Position(2)=1.175;
%
% Plot the frequency bands
if ~isempty(freqband)
  val1str=num2str(freqband(1));
  vline1=line([freqband(1) freqband(1)],ylim,'LineStyle','--','Color',...
    [0.35 0.35 0.35]);
  vline1.HandleVisibility='off';
  val2str=num2str(freqband(2));
  vline2=line([freqband(2) freqband(2)],ylim,'LineStyle','--','Color',...
    [0.35 0.35 0.35]);
  vline2.HandleVisibility='off';
end
% Plot the minimum and maximum frequencies
if ~isempty(minmax)
  val3str=num2str(minmax(1));
  vline3=line([minmax(1) minmax(1)],ylim,'LineStyle','--','Color',...
    [0.35 0.35 0.35]);
  vline3.HandleVisibility='off';
  val4str=num2str(freqband(2));
  vline4=line([minmax(2) minmax(2)],ylim,'LineStyle','--','Color',...
    [0.35 0.35 0.35]);
  vline4.HandleVisibility='off';
end
% Add an axis for the period, as well
x2pos=[1e-4 1e-2 1 100];
x2lbls={'10000';'100';'1';'0.01'};
newax2=xtraxis(ax2,x2pos,x2lbls,'Period (s)',[],[],[]);
newax2.XLim=[1/max(freqs) 1/min(freqs)];
newax2.XTick=[0.01 1 1e2 1e4];
newax2.XDir='reverse';
newax2.XTickLabel={'0.01';'1';'100';'10000'};
newax2.XLabel.FontSize=10;


% Save the plot
if saveplot==1
  if ~isempty(freqband)
    figname=sprintf('PhaseFreq.%s.%s.%d.JD%d.%s.%sto%s_%s%s.eps',...
      netname,staname,yrname,jd,vallbl{measval+1},freq1,freqlast,...
      val1str,val2str);
  else
    figname=sprintf('PhaseFreq.%s.%s.%d.JD%d.%s.%sto%s.eps',...
      netname,staname,yrname,jd,vallbl{measval+1},freq1,freqlast);
  end
  fignameb=figdisp(figname,[],[],1,[],'epstopdf');
  pause(0.25)
  if ~strcmpi(savedir,pwd)
    [status,cmdout]=system(sprintf('mv %s %s',fignameb,savedir));
    figname=fullfile(savedir,figname);
    pause(0.25)
  end
  % Make a PNG version
  fignamepng=strcat(figname(1:length(figname)-3),'png');
  [status,cmdout]=system(sprintf('convert -density 250 %s %s',figname,...
    fignamepng));
  pause(.5)
end


