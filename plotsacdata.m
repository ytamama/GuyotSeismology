function [seisplot,figname,figname2]=plotsacdata(fileornot,sacdata,measval,...
    filterfreqs,saveplot,evtornot,savedir,arrtime,evtid,magnitude,distance,...
    depth,intstart,intend)
% 1) plotsacevent(fileordata,sacdata,measval,filterfreqs,evtornot,...
%    saveplot)
% 2) plotsacevent(fileordata,sacdata,measval,filterfreqs,evtornot,...
%    saveplot,arrtime,evtid,magntude,distance,intstart,intend)
% 
% Function to plot SAC files or data. The SAC data could be from 
% hourly SAC files, just recording the ambient ground motion, or be 
% intervals surrounding a particular event, made by mcevt2sac.m
% 
% INPUTS
% fileornot : Are we inputting SAC files or SAC data?
%              0 - Data
%              1 - Files
% sacdata : A cell array, containing the names of the SAC files to plot
%           OR the SAC data. Either way, the files/data must be 
%           listed in order of Z, Y, and X. If a component is missing, 
%           an empty string/vector must take its place.
%           If inputting SAC data as opposed to files, the last entry
%           in the cell array must be the header of one of the SAC files.
%           Examples)
%           {sacfilez; sacfiley; sacfilex};
%           {sacfilez; ''; sacfilex};
%           {sacdataz; sacdatay; sacdatax; header};
%           {sacdataz; []; sacdatax; header};                
% measval : What are we plotting?
%           0 - Displacement (nm, but scaled if needed)
%           1 - Velocity (nm/s)
%           2 - Acceleration (nm/s^2)
% filterfreqs : The frequencies at which the SAC data were filtered, 
%               entered as an array
% saveplot : Do we want to save our plot?
%            0 - No (default)
%            1 - Yes 
%            If saving, the plot will go into your EPS files directory
%            Specify where that is!
% evtornot : Are we plotting an event or not?
%            0 - No
%            1 - Yes
% savedir : Where do we save our plot? Specify the directory as a string!
%           By default, the EPS figure will be saved in your 'EPS' 
%           directory, and your PNG figure will be saved in your current
%           working directory. Enter savedir as an empty string if the 
%           default is okay.
% arrtime : The arrival time of the event, inputted as a datetime
% evtid : The event ID, as recorded in the IRIS catalog
% magnitude : The magnitude of the event being recorded
% distance : The distance, in degrees, from the event to Guyot Hall, 
%            Princeton University
%            Found using IRIS Web Services' Distaz
% depth : The depth, in km, of the event, as recorded in the IRIS catalog
% intstart : Number of seconds before the arrival time the interval begins
% intend : Number of seconds after the arrival time the interval ends
% 
% OUTPUT
% seisplot : A figure showing the seismograms of the inputted SAC files
% figname : The name of the figure saved, as an EPS file
% figname2 : The name of the figure saved, as a JPEG file
% 
% References:
% Uses defval.m, in csdms-contrib/slepian_alpha 
% Uses dat2jul.m and readsac.m, in csdms-contrib/slepian_oscar
% Uses figdisp.m, serre.m, label.m, and nolabels.m, in 
% csdms-contrib/slepian_alpha
% Uses char(176) to get the degree symbol, obtained from help
% forums on www.mathworks.com
% 
% Last Modified by Yuri Tamama, 07/10/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Important directories - insert your own!
epsdir='';

% Set default values
defval('saveplot',0);

% Check how many components we have
numexist=0;
for i=1:3
  if ~isempty(sacdata{i})
    numexist=numexist+1;
  end
end
if numexist==0
  disp('Please enter in SAC data! Exiting function...')
  figname='';
  return
end

% Figure out units
if measval==0
  valunit='nm';
  vallabel='Displacement';
  vallabelmini='Disp';
elseif measval==1
  valunit='nm/s';
  vallabel='Velocity';
  vallabelmini='Vel';
else
  valunit='nm/s^2';
  vallabel='Acceleration';
  vallabelmini='Acc';
end

% Strings necessary:
% Frequencies
freqstr1=sprintf('%.2f',filterfreqs(1));
freqstr2=sprintf('%.2f',filterfreqs(2));
freqstr3=sprintf('%.2f',filterfreqs(3));
freqstr4=sprintf('%.2f',filterfreqs(4)); 
% Periods
pdstr1=sprintf('%.2f',1/filterfreqs(1));
pdstr2=sprintf('%.2f',1/filterfreqs(2));
pdstr3=sprintf('%.2f',1/filterfreqs(3));
pdstr4=sprintf('%.2f',1/filterfreqs(4));
% If plotting an event
if evtornot==1
  % Arrival year and JD
  arryrstr=num2str(arrtime.Year);
  arrjd=dat2jul(arrtime.Month,arrtime.Day,arrtime.Year);
  arrjdstr=datenum2str(arrjd,1);
  % Length of our interval
  inttotal=num2str(intstart+intend);
  % Event ID
  evtidstr=num2str(evtid);
end
if fileornot==0
  header=sacdata{4};
else
  [~,header]=readsac(sacdata{1},0);
end
filejd=header.NZJDAY;
jdstr=datenum2str(filejd,1);
fileyr=header.NZYEAR;
yrstr=num2str(fileyr);  
filehr=header.NZHOUR;
hrstr=datenum2str(filehr,0);

% Before plotting, go through the available data to see what we should
% set as the vertical axis limits
datalims=zeros(3,1);
for c=1:3
  if isempty(sacdata{c})
    continue;
  else
    if fileornot==1
      sacfile=sacdata{c};
      [seisdata,~]=readsac(sacfile,0);
    else
      seisdata=sacdata{c};
    end
    datalims(c)=1.2*max(abs(seisdata));
  end
end
datalim=max(abs(datalims));
% Scale our plot, if necessary
plotscale=1;
if datalim >= 1e8
  valunit(1:2)='mm';
  plotscale=1e6;
  datalim=datalim/plotscale;
elseif datalim >= 1e5
  plotscale=1e3;
  datalim=datalim/plotscale;
  if measval==0
    valunit='\mum';   
  elseif measval==1
    valunit='\mum/s';    
  else
    valunit='\mum/s^2';    
  end
end

% Go through each of the SAC files (in order!) and make our plot
plotcount=0;
components={'Z';'Y';'X'};
axeshdl=[];
seisplot=figure();
if fileornot==0
  header=sacdata{4};
end
for c=1:3
  if isempty(sacdata{c})
    continue;
  else
    component=components{c};
    if fileornot==1
      sacfile=sacdata{c};
      [seisdata,header]=readsac(sacfile,0);
    else
      seisdata=sacdata{c};
    end
    seisdata=seisdata/plotscale;
    % Figure out x axis range and limits
    startx=(header.NZMIN)*60+header.NZSEC+(header.NZMSEC/100);
    xrange=[startx:header.DELTA:round(header.E,2)+startx];
    startlim=startx;
    endlim=header.E+startx;
    subplot(numexist,1,plotcount+1)
    plot(xrange,seisdata)
    hold on
    % Axis limits
    xlim([startlim endlim])
    ylim([-datalim datalim])
    % Add current axes to axes array
    nowaxes=gca;
    axeshdl=[axeshdl; nowaxes];
    % Adjust and label vertical axes 
    nowaxes.YTickMode='manual';
    tickval=datalim*(3/4);
    if tickval>100
      tickval=round(tickval,-2);
    else
      tickval=round(tickval,-1);
    end
    nowaxes.YTick=[-1*tickval; 0; tickval];
    tickvalstr=sprintf('%d',tickval);
    nowaxes.YTickLabelMode='manual';
    nowaxes.YTickLabel={sprintf('-%s',tickvalstr);'0';tickvalstr};
    ylabel(sprintf('%s (%s)',component,valunit))
    % Make plot horizontally wider
    shrink(nowaxes,0.9,1)       
    if plotcount==0
      % Only have the x label for the last/bottom component, unless 
      % this one is the ONLY component
      if (plotcount+1)~=sum(numexist)
        nolabels(nowaxes,1)
      end
      % Frequency
      [bh,th]=label(nowaxes,'lr',7,0,0,1.4,21);
      th.String=sprintf('Freq [%s %s %s %s] Hz',freqstr1,freqstr2,...
          freqstr3,freqstr4);
      th.FontWeight='bold';
      % Period
      [bh,th]=label(nowaxes,'ur',7,0,0,1.4,21);
      th.String=sprintf('Pd [%s %s %s %s] s',pdstr4,pdstr3,...
          pdstr2,pdstr1);
      th.FontWeight='bold';
      % Magnitude and Distance, if needed
      if evtornot==1
        deltastr=strcat('\Delta',char(176));
        % Title
        titlestr1=sprintf('Event ID %s (First Arrival %s, JD %s)',...
            evtidstr,arryrstr,arrjdstr);
        titlestr2=sprintf('Magnitude %.1f; %s=%.1f; Depth=%.1f km',...
            magnitude,deltastr,distance,depth);
        titlestr3=sprintf('%s Recorded at Guyot Hall, Princeton University',...
            vallabel);
        title({titlestr1;titlestr2;titlestr3});      
      else
        titlestr1=sprintf('Ground %s on %s JD %s %s:00:00',...
          vallabel,yrstr,jdstr,hrstr);
        titlestr2='Recorded at Guyot Hall, Princeton University';
        title({titlestr1;titlestr2}); 
      end
    end
    % Plot arrival time, if requested
    if evtornot==1
      arrindex=intstart*100+1;
      line([xrange(arrindex) xrange(arrindex)],ylim,'LineStyle',...
        '--','Color','r')
    end
    % With the last component, add the x axis label and legend
    if (plotcount+1)==sum(numexist)
      % X axis label
      xlabel(sprintf('Time (s) Since %s:00:00 GMT',...
          datenum2str(header.NZHOUR,0)))
      if evtornot==1
        legend(vallabelmini,'Arrival','Location','southwest')
      end
      % Adjust position of subplots 
      serre(axeshdl,1,'down')
      hold off;
    end
    if (plotcount+1~=sum(numexist)) && (plotcount~=0)
      nolabels(nowaxes,1)  
    end
  end  
  plotcount=plotcount+1;
end
% Save plot
if saveplot==1
  if evtornot==1
    figname=sprintf('EVTID%s%s.ARR%sJD%s.%ss.FREQ%s%s%s%s.eps',evtidstr,...
      upper(vallabelmini),arryrstr,arrjdstr,inttotal,freqstr1,freqstr2,...
      freqstr3,freqstr4);
    figname2=sprintf('EVTID%s%s.ARR%sJD%s.%ss.FREQ%s%s%s%s.jpg',evtidstr,...
      upper(vallabelmini),arryrstr,arrjdstr,inttotal,freqstr1,freqstr2,...
      freqstr3,freqstr4);
  else
    figname=sprintf('%sJD%s.%s.FREQS%s%s%s%s.eps',yrstr,jdstr,...
      upper(vallabelmini),freqstr1,freqstr2,freqstr3,freqstr4);
    figname2=sprintf('%sJD%s.%s.FREQS%s%s%s%s.jpg',yrstr,jdstr,...
      upper(vallabelmini),freqstr1,freqstr2,freqstr3,freqstr4);
  end
  figname=figdisp(figname,[],[],1,[],'epstopdf');
  print(seisplot,figname2,'-djpeg')
  fignameeps=fullfile(epsdir,figname);
  if ~isempty(savedir)
    [status,cmdout]=system(sprintf('mv %s %s',fignameeps,savedir));
    [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
    figname=fullfile(savedir,figname);
    figname2=fullfile(savedir,figname2);
  else
    figname=fignameeps;
  end
else
  figname='notsaved';
  figname2='notsaved';
end

