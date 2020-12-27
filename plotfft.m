function figurehdl=plotfft(sacbundle,plotorder,samplefreq,winlen,...
    dval,measval,filterfreqs,plotlimits,axisstyle,resample,...
    saveplot,savedir)
% 
% Function to plot the spectral density of the inputted time series 
% data, computed using the method of Chave 
% (from pchave.m in csdms-contrib/slepian_oscar)
% 
% INPUTS
% sacbundle : A cell array containing sets of SAC files, which contain the
%             the seismic data in the time domain. The cell array is 
%             structured such that each cell is itself a cell array of 
%             SAC files, one per directional component. This is so that 
%             we can plot multiple spectral density plots on one figure. 
%             Example: 
%             sacfiles = {1st set of SAC files; 2nd set of SAC files}
%             The directional components should be listed in the 
%             same order for all sets of SAC files, and each SAC file 
%             should measure the same thing (displacement, velocity, or 
%             acceleration) at the same sampling frequenecy and through
%             the same filtered frequencies.
% plotorder : A vector of numbers listing the order in which each 
%             inputted SAC file should be plotted, from top subplot to
%             bottom. 
% samplefreq : The sampling frequency of the seismometer, in samples/sec
% winlen : How long, in seconds, should our window length be for pchave.m?
%          If left empty, the default settings for pchave.m will be used
% dval: Parameter from pchave.m in csdms-contrib/slepian_oscar
%       'MAD' for mean absolute deviation scale
%       'IQ' for interquartile scale 
% measval : What do the SAC files measure?
%           0 - Displacement (nm, but scaled if needed)
%           1 - Velocity (nm/s)
%           2 - Acceleration (nm/s^2)
% filterfreqs : The frequencies at which the SAC data were filtered, 
%               entered as an array. If the upper limit of the passed
%               frequencies is below the original Nyquist frequency, 
%               the data will be resampled. 
% plotlimits : Do we wish to plot the upper and lower confidence limits?
%              0 - No
%              1 - Yes
% axisstyle : On what scale should we plot the data?
%             'loglog' - logarithmic vertical and horizontal axes
%             'loglinear' - logarithmic vertical, linear horizontal
%             'linearlog' - linear vertical, logarithmic horizonal
%             'linearlinear' - linear vertical and horizontal axes
% resample : Do we wish to resample our data?
%            0 - No (default)
%            1 - Yes
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
% (DOI : 10.1029/JB092iB01p00633)
% Uses jul2dat.m, readsac.m, in csdms-contrib/slepian_oscar
% Uses figdisp.m, serre.m, nolabels.m, defval.m, shrink.m in 
% csdms-contrib/slepian_alpha
% Trick to switching between existing subplots is from MATLAB help
% forums online
%
% Last Modified by Yuri Tamama, 12/27/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
staloc='Guyot Hall, Princeton University';
stacode='PP.S0001';
defval('savedir','')
defval('winlen',[])
defval('dval','MAD')
defval('resample',0)

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

% Set subplots first
figurehdl=figure(gcf);
for i=1:3
  subplot(3,1,plotorder(i));
  hold on
end

% Iterate through the sets of SAC files
max1=0;
max2=0;
max3=0;
legendstrs={};
addtitle=0;
wloriginal=winlen;
linestyls={'-';'-';'-';'-'};
for b=1:length(sacbundle)
  sacfiles=sacbundle{b};
  % Check that we have existing SAC files entered
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

  % Go through each of the SAC files (in order!) and make our plot
  plotcount=0;
  compclrs={'r';'g';'b'};
  plotclrs={'r';[1 .45 0];[1 .75 0];[0 0.75 0];[0 0.7 0.9];[.5 0 1];...
      [1 0 .75]};
  axeshdl=[];
  plotorder=sort(plotorder);
  wltosample=0;
  winlen=wloriginal;
  if isempty(winlen)
    defaultwl=1;
  else
    defaultwl=0;
  end
  gotlegend=0;
  for c=1:3
    component=orderedcomps{c};
    sacfile=orderedfiles{c};
    % Trick to switching between existing subplots is from MATLAB
    % help forums online
    if b==1
      if c==1
        axes1=subplot(3,1,1);
      elseif c==2
        axes2=subplot(3,1,2);
      else
        axes3=subplot(3,1,3);
      end
    else
      if c==1
        axes(axes1);
      elseif c==2
        axes(axes2);
      else
        axes(axes3);
      end
    end
    hold on
  
    % Things to do before plotting data (if it exists):
    nowaxes=gca;
    axeshdl=[axeshdl; nowaxes];
    if b==1
      % Adjust plot size
      shrink(nowaxes,0.95,.95) 
      % Add the x axis label for the bottommost subplot
      if (plotcount+1)==numexist && plotorder(c)==3
        % X Axis label
        xlabel('Frequency (Hz)')
        % Adjust position of subplots 
        serre(axeshdl,1,'down')
      end
    end
    % Add vertical axis label, if it is not already there
    if ~isempty(component) && isempty(nowaxes.YLabel.String)
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
  
    % Now get to plotting the data, if they exist!
    if isempty(sacfile)
      nolabels(nowaxes,2);
      % Move onto the next component if the data don't exist
      continue;
    end
    [seisdata,header]=readsac(sacfile,0);
    
    % Add the title, if we are on the top subplot and haven't added the 
    % title yet
    if addtitle==0
      % Add the title, if the current subplot is the top one
      if plotcount==0 && plotorder(c)==1 
        monthnames={'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';...
          'Oct';'Nov';'Dec'};
        fulldate=jul2dat(header.NZYEAR,header.NZJDAY);
        monthname=monthnames{fulldate(1)};
        dayname=fulldate(2);
        yrstr=num2str(header.NZYEAR);  
        hrstr=datenum2str(header.NZHOUR,0);
        minstr=datenum2str(header.NZMIN,0);
        secstr=datenum2str(header.NZSEC+(header.NZMSEC/1000),0); 
        titlestr1=sprintf('Spectral Density Function of %s',vallabel);
        titlestr2=sprintf('Window Length: %d Samples  Scale Estimate: %s',...
          winlen,dval);
        titlestr3=sprintf('Recorded at %s (%s)',...
          staloc,stacode);
        titlestr4=sprintf('%s:%s:%s GMT %s %s %d',hrstr,minstr,secstr,...
          yrstr,monthname,dayname);
        freqtitle=['[',freqstr1,' {\color{magenta}',freqstr2,...
          ' \color{magenta}',freqstr3,'} ',freqstr4,'] Hz'];
        pdtitle=['[',pdstr4,' {\color{magenta}',pdstr3,' \color{magenta}',...
          pdstr2,'} ',pdstr1,'] s'];
        titlestr5=[freqtitle,'  ',pdtitle];
        if length(sacbundle)>1
          title({titlestr1;titlestr2;titlestr3;titlestr5},...
            'interpreter','tex')
        else
          title({titlestr1;titlestr2;titlestr3;titlestr4;titlestr5},...
            'interpreter','tex')
        end
        addtitle=1;
      end
    end
   
    % Check if we need to resample our data!
    if resample==1
      nyquistold=samplefreq/2;
      nyquistnew=filterfreqs(4);
      if difer(nyquistold-nyquistnew,10)==1
        oldseisdata=seisdata;
        % Resample our data!
        seisdata=resample(oldseisdata,nyquistnew,nyquistold);
        samplefreq=samplefreq*(nyquistnew/nyquistold);
      end
    end
    % Compute the robust spectral density using pchave.m, from 
    % csdms-contrib/slepian_oscar
    % Overlap of 70% between segments
    % Default window function name of 'DPSS' (for discrete prolate
    % spheroidal sequences)
    % Default window function pareameter of 4
    % Default 95% confidence intervals
  
    % If using inputted parameters
    if defaultwl==0
      if wltosample==0
        winlen=winlen*samplefreq;
        wltosample=1;
      end
      nfft=length((1/samplefreq):(1/samplefreq):samplefreq);
      [sdensity,freqs,upperlog,lowerlog,upperlin,lowerlin,sdensitynon,qnon,...
        qrobust,qchi2]=pchave({seisdata},winlen,70,nfft,samplefreq,dval);
    else
      winlen=256;
      [sdensity,freqs,upperlog,lowerlog,upperlin,lowerlin,sdensitynon,qnon,...
        qrobust,qchi2]=pchave({seisdata},[],[],[],samplefreq);
    end

    sdplot=plot(freqs,sdensity);
    sdplot.Color=plotclrs{b};
    if mod(b,4)>0
      sdplot.LineStyle=linestyls{mod(b,4)};
    else
      sdplot.LineStyle=linestyls{4};
    end
    % Plot the upper and lower confidence limits, if necessary
    if strcmp(axisstyle(1:3),'log')
      nowaxes.YScale='log';
      if plotlimits==1
        upperlim=plot(freqs,upperlog);
        upperlim.Color=[.75 .75 .75];
        upperlim.HandleVisibility='off';
        lowerlim=plot(freqs,lowerlog);
        lowerlim.Color=[.75 .75 .75];
        lowerlim.HandleVisibility='off';
      end 
      maxval=ceil(max(sdensity));
      if i==1
        if maxval>=max1
          max1=maxval;
        end
        nowaxes.YLim=[1e-5 max1*1.1];
      elseif i==2
        if maxval>=max2
          max2=maxval;
        end
        nowaxes.YLim=[1e-5 max2*1.1];
      else
        if maxval>=max3
          max3=maxval;
        end
        nowaxes.YLim=[1e-5 max3*1.1];
      end
      nowaxes.YTick=[1e-4 1e-2 1 100];
    % Linear vertical axis
    else
      % Scale the axes so we don't get overlapping tick marks
      % Trick to obtaining the nearest power of 10 is from stackoverflow!
      maxval=ceil(max(sdensity));
      if i==1
        if maxval>=max1
          max1=maxval;
        end
        maxtickval=round(max1,(-1*floor(log10(max1)))+1);
        nowaxes.YLim=[0 maxtickval*1.1];
      elseif i==2
        if maxval>=max2
          max2=maxval;
        end
        maxtickval=round(max2,(-1*floor(log10(max2)))+1);
        nowaxes.YLim=[0 maxtickval*1.1];
      else
        if maxval>=max3
          max3=maxval;
        end
        maxtickval=round(max3,(-1*floor(log10(max3)))+1);
        nowaxes.YLim=[0 maxtickval*1.1];
      end
      nowaxes.YTickMode='manual';
      nowaxes.YTick=[0 (1/2)*maxtickval maxtickval];
      nowaxes.YTickLabelMode='manual';
      nowaxes.YTickLabel={'0';num2str(.5*maxtickval,'%.1e');...
        num2str(maxtickval,'%.1e')};
      nowaxes.YMinorTick='on';
      if plotlimits==1
        upperlim=plot(freqs,upperlin);
        upperlim.HandleVisibility='off';
        upperlim.Color=[.75 .75 .75];
        lowerlim=plot(freqs,lowerlin);
        lowerlim.HandleVisibility='off';
        lowerlim.Color=[.75 .75 .75];
      end
    end
    % Plot vertical lines to indicate the frequency range
    freqst=line([filterfreqs(2) filterfreqs(2)],ylim,'Color',[.5 .5 .5],...
      'LineStyle',':','LineWidth',1.5);
    freqst.HandleVisibility='off';
    freqend=line([filterfreqs(3) filterfreqs(3)],ylim,'Color',[.5 .5 .5],...
      'LineStyle',':','LineWidth',1.5);
    freqend.HandleVisibility='off';
    % Logarithmic horizontal axes
    if strcmp(axisstyle(length(axisstyle)-2:length(axisstyle)),'log')
      nowaxes.XScale='log';
    end
    % Display only the frequencies we filter through!
    nowaxes.XLim=[filterfreqs(1) filterfreqs(4)];
    nowaxes.XTick=[0.01 0.1 1 2 5 10 15 20 30 40];
    nowaxes.XGrid='on';
  
    % Remove labels if necessary
    if (plotcount+1)~=numexist
      nolabels(nowaxes,1)
    else
      if plotorder(c)==3
      else
        nolabels(nowaxes,1)
      end
    end  
    
    % Get information for the plot legend, if necessary
    if gotlegend==0
      mdy=jul2dat(header.NZYEAR,header.NZJDAY);
      jdstr=datenum2str(header.NZJDAY,1);
      yrstr=num2str(header.NZYEAR);  
      monthname=monthnames{mdy(1)};
      daystr=num2str(mdy(2));
      hrstr=datenum2str(header.NZHOUR,0);
      minstr=datenum2str(header.NZMIN,0);
      secstr=datenum2str(header.NZSEC+(header.NZMSEC/1000),0); 
      legendstrs=vertcat(legendstrs,sprintf('%s %s %s %s:%s:%s',yrstr,...
        monthname,daystr,hrstr,minstr,secstr));
      gotlegend=1;
    end
 
    % Add to plot count
    plotcount=plotcount+1;
  end
end

% Add the legend
plotlegend=legend(legendstrs);
plotlegend.Location='south';

% If saving the final plot
if saveplot==1
  if length(sacbundle)==1
    if plotlimits==1
      figname=sprintf('%s.%s.%s.%s.%s%s%s.%s%s%s%s.spec.%s.%s.%s.pl.eps',...
        stacode,lower(vallabelmini),yrstr,jdstr,hrstr,minstr,secstr,...
        freqstr1,freqstr2,freqstr3,freqstr4,num2str(round(winlen,1)),...
        dval,axisstyle);
    else
      figname=sprintf('%s.%s.%s.%s.%s%s%s.%s%s%s%s.spec.%s.%s.%s.eps',...
        stacode,lower(vallabelmini),yrstr,jdstr,hrstr,minstr,secstr,...
        freqstr1,freqstr2,freqstr3,freqstr4,num2str(round(winlen,1)),...
        dval,axisstyle);
    end
  else
    if plotlimits==1
      figname=sprintf('manyfft.%d.%s.%s.%s.%s.%s%s%s.%s%s%s%s.%s.%s.%s.pl.eps',...
        length(sacbundle),stacode,lower(vallabelmini),yrstr,jdstr,hrstr,...
        minstr,secstr,freqstr1,freqstr2,freqstr3,freqstr4,...
        num2str(round(winlen,1)),dval,axisstyle);
    else
      figname=sprintf('manyfft.%d.%s.%s.%s.%s.%s%s%s.%s%s%s%s.%s.%s.%s.eps',...
        length(sacbundle),stacode,lower(vallabelmini),yrstr,jdstr,hrstr,...
        minstr,secstr,freqstr1,freqstr2,freqstr3,freqstr4,...
        num2str(round(winlen,1)),dval,axisstyle);
    end
  end
  figname2=figdisp(figname,[],[],1,[],'epstopdf');
  if ~isempty(savedir)
    [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
    figname=fullfile(savedir,figname);
  else
    figname=figname2;
  end
end



