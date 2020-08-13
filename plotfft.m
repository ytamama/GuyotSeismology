function figurehdl=plotfft(sacfiles,plotorder,samplefreq,numsegments,...
    dval,measval,filterfreqs,plotlimits,axisstyle,saveplot,savedir)
% 
% Function to plot the spectral density of the inputted time series 
% data, computed using the method of Chave 
% (from pchave.m in csdms-contrib/slepian_oscar)
% 
% INPUTS
% sacfiles : SAC files containing seismic data in the time domain, one 
%            file per directional component
% plotorder : A vector of numbers listing the order in which each 
%             inputted SAC file should be plotted, from top subplot to
%             bottom. 
% samplefreq : The sampling frequency of the seismometer
% numsegments : Into how many segments should each SAC file be divided?
%               This number should be an integer, and the length of the 
%               SAC files should be divisible by this value. 
% dval: Parameter from pchave.m in csdms-contrib/slepian_oscar
%       'MAD' for mean absolute deviation scale
%       'IQ' for interquartile scale 
% measval : What do the SAC files measure?
%           0 - Displacement (nm, but scaled if needed)
%           1 - Velocity (nm/s)
%           2 - Acceleration (nm/s^2)
% filterfreqs : The frequencies at which the SAC data were filtered, 
%               entered as an array. Enter as an empty array if you 
%               don't know the filtered frequencies.
% plotlimits : Do we wish to plot the upper and lower confidence limits?
%              0 - No
%              1 - Yes
% axisstyle: On what scale should we plot the data?
%            'loglog' - logarithmic vertical and horizontal axes
%            'loglinear' - logarithmic vertical, linear horizontal
%            'linearlog' - linear vertical, logarithmic horizonal
%            'linearlinear' - linear vertical and horizontal axes
% saveplot : Do we wish to save our plot?
%            0 - No
%            1 - Yes
% savedir : If so, where do we wish to save the plot? Specify a directory!
%           Default: in your 'EPS' directory
%
% OUTPUT
% figurehdl : The figure handle of the resulting plot
%
% References:
% Uses pchave.m, from csdms-contrib/slepian_oscar to compute the robust 
% spectral density using the method of Chave et al., 1987
% 
% Uses defval.m, from csdms-contrib/slepian_alpha
%
% Last Modified by Yuri Tamama, 08/13/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
staloc='Guyot Hall, Princeton University';
stacode='PP.S0001';
defval('savedir','')

components=cell(length(plotorder),1);
numexist=0;
for i=1:3
  if ~isempty(sacfiles{i}) && exist(sacfiles{i})==2
    numexist=numexist+1;
    [~,hdr]=readsac(sacfiles{i});
    channel=hdr.KCMPNM;
    components{i}=channel(3);
  else
    components{i}='';
  end
end
if numexist==0
  disp('Please enter in SAC data! Exiting function...')
  figurehdl=[];
  return
end

% Place the SAC files, and their components, in the desired order
orderedcomps=cell(3,1);
orderedfiles=cell(3,1);
indices=1:3;
sortorder=sort(plotorder);
for i=1:3
  if isempty(sacfiles{i}) || exist(sacfiles{i})==0
    orderedcomps{i}='';
    orderedfiles{i}='';
  else
    index=indices(plotorder==sortorder(i));
    orderedcomps{i}=components{index};
    orderedfiles{i}=sacfiles{index};
  end
end

% Figure out units
if measval==0
  vallabel='Displacement';
  vallabelmini='Disp';
  valunit='nm^2/Hz';
elseif measval==1
  vallabel='Velocity';
  vallabelmini='Vel';
  valunit='(nm/s)^2/Hz';
else
  vallabel='Acceleration';
  vallabelmini='Acc';
  valunit='(nm/s^2)^2/Hz';
end

% Strings necessary:
% Frequencies
if ~isempty(filterfreqs)
  freqstr1=sprintf('%g',filterfreqs(1));
  freqstr2=sprintf('%g',filterfreqs(2));
  freqstr3=sprintf('%g',filterfreqs(3));
  freqstr4=sprintf('%g',filterfreqs(4)); 
  % Periods
  pdstr1=sprintf('%.2f',1/filterfreqs(1));
  pdstr2=sprintf('%.2f',1/filterfreqs(2));
  pdstr3=sprintf('%.2f',1/filterfreqs(3));
  pdstr4=sprintf('%.2f',1/filterfreqs(4));
end

% Times corresponding to the data
for i=1:3
  sacfile=orderedfiles{i};
  if ~isempty(sacfile) && exist(sacfile)==2
    [~,header]=readsac(orderedfiles{i},0);
    break
  end
end
yrstr=num2str(header.NZYEAR);  
jdstr=datenum2str(header.NZJDAY,1);
hrstr=datenum2str(header.NZHOUR,0);
minstr=datenum2str(header.NZMIN,0);
hdrsec=round(header.NZSEC+(header.NZMSEC/100),2);
secstr=datenum2str(hdrsec,0);

% Go through each of the SAC files (in order!) and make our figure
% Set subplots first
figurehdl=figure(gcf);
hold on
for i=1:3
  subplot(3,1,plotorder(i));
  hold on
end

% Plot data
plotcount=0;
compclrs={'-r';'-g';'-b'};
axeshdl=[];
plotorder=sort(plotorder);
for c=1:3
  component=orderedcomps{c};
  sacfile=orderedfiles{c};
  subplot(3,1,plotorder(c))
  %
  % Get current axes (and store all axes handles, for reference)
  nowaxes=gca;
  axeshdl=[axeshdl; nowaxes];
  % Adjust plot size
  shrink(nowaxes,0.95,.95) 
  % Remove labels if necessary
  if (plotcount+1)~=numexist
    nolabels(nowaxes,1)
  else
    if plotorder(c)==3
    else
      nolabels(nowaxes,1)
    end
  end  
  % Add vertical axis label
  if ~isempty(component)
    if strcmpi(component,'Z')
      ylabel(sprintf('%s %s',component,valunit))
    elseif strcmpi(component,'Y')
      ylabel(sprintf('%s (N) %s',component,valunit))
    elseif strcmpi(component,'X')
      ylabel(sprintf('%s (E) %s',component,valunit))
    else 
      ylabel(sprintf('%s %s',component,valunit))
    end
  end
  % Add the x axis label for the bottommost subplot 
  if (plotcount+1)==numexist 
    if plotorder(c)==3 
      % X Axis label
      xlabel('Frequency (Hz)')
      % Adjust position of subplots 
      serre(axeshdl,1,'down')
    end
  end
  
  if isempty(sacfile)
    nolabels(nowaxes,2);
    % Move onto the next component if the data don't exist
    continue;
  end
  
  [seisdata,header]=readsac(sacfile,0);
  % Compute the robust spectral density using pchave.m, from 
  % csdms-contrib/slepian_oscar
  datalen=length(seisdata);
  winlen=datalen/numsegments;
  % Overlap of 70% between segments
  % Default window function name of 'DPSS' (for discrete prolate
  % spheroidal sequences)
  % Default window function pareameter of 4
  % Default 95% confidence intervals
  [sdensity,freqs,upperlog,lowerlog,upperlin,lowerlin,sdensitynon,qnon,...
      qrobust,qchi2]=pchave({seisdata},winlen,70,winlen,samplefreq,dval);
  
  % Plot the resulting spectral density function 
  % Change the axes to logarithmic if specified, and plot the upper and
  % lower limits of the confidence interval if necessary
  sdplot=plot(freqs,sdensity,compclrs{c});
  if strcmp(axisstyle(1:3),'log')
    nowaxes.YScale='log';
    nowaxes.YLim=[1e-10 1e10];
    nowaxes.YTickMode='manual';
    nowaxes.YTick=[1e-8 1 1e8];
    nowaxes.YTickLabelMode='manual';
    nowaxes.YTickLabel={'10^{-8}';'10^{0}';'10^{8}'};
    if plotlimits==1
      upperlim=plot(freqs,upperlog);
      upperlim.Color=[.75 .75 .75];
      lowerlim=plot(freqs,lowerlog);
      lowerlim.Color=[.75 .75 .75];
    end 
  else
    % Scale the axes so we don't get overlapping tick marks
    maxval=max(sdensity);
    % Trick to obtaining the nearest power of 10 is from stackoverflow!
    maxtickval=round(maxval,(-1*floor(log10(maxval)))+1);
    nowaxes.YLim=[0 maxtickval*1.1];
    nowaxes.YTickMode='manual';
    nowaxes.YTick=[0 (1/2)*maxtickval maxtickval];
    nowaxes.YTickLabelMode='manual';
    nowaxes.YTickLabel={'0';num2str(.5*maxtickval,'%.1e');...
      num2str(maxtickval,'%.1e')};
    nowaxes.YMinorTick='on';
    if plotlimits==1
      upperlim=plot(freqs,upperlin);
      upperlim.Color=[.75 .75 .75];
      lowerlim=plot(freqs,lowerlin);
      lowerlim.Color=[.75 .75 .75];
    end
  end
  if strcmp(axisstyle(length(axisstyle)-2:length(axisstyle)),'log')
    nowaxes.XScale='log';
    nowaxes.XLim=[nowaxes.XLim(1) samplefreq/2];
  end
  
  % Add the title, if the current subplot is the top one
  if plotcount==0 && plotorder(c)==1
    titlestr1=sprintf('Spectral Density Function of %s',vallabel);
    titlestr2=sprintf('Window Length: %d Samples  Scale Estimate: %s',...
      winlen,dval);
    titlestr3=sprintf('Recorded at %s (%s)',...
      staloc,stacode);
    freqtitle=['[',freqstr1,' {\color{magenta}',freqstr2,...
      ' \color{magenta}',freqstr3,'} ',freqstr4,'] Hz'];
    pdtitle=['[',pdstr4,' {\color{magenta}',pdstr3,' \color{magenta}',...
      pdstr2,'} ',pdstr1,'] s'];
    titlestr4=[freqtitle,'  ',pdtitle];
    title({titlestr1;titlestr2;titlestr3;titlestr4},'interpreter','tex')
  end
  
  % Add to plot count
  plotcount=plotcount+1;
end


% If saving the final plot
if saveplot==1
  figname=sprintf('%s.%s.%s.%s.%s%s%s.%s%s%s%s.spec.%s.%s.%s.eps',...
    stacode,lower(vallabelmini),yrstr,jdstr,hrstr,minstr,secstr,...
    freqstr1,freqstr2,freqstr3,freqstr4,num2str(round(winlen,1)),...
    dval,axisstyle);
  figname2=figdisp(figname,[],[],1,[],'epstopdf');
  if ~isempty(savedir)
    [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
    figname=fullfile(savedir,figname);
  else
    figname=figname2;
  end
end



