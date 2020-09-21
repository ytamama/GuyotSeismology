function cbmotion(plotcb,numdim,maybehrs,measval,frequency,saveplot,...
  savedir)
% 
% Function to plot the particle motions of signals that might 
% be campus blasts, and compare those graphs to those of known 
% campus blasts!
%
% The data are collected from the Meridian Compact PH1 seismometer, a
% broadband Nanometrics three-component seismometer in the basement of 
% Guyot Hall, Princeton University. 
% 
% Inputted are the datetimes of hours, in UTC, that might contain a 
% blast signal (e.g. 11 UTC : 11 - 11:59:59 UTC). Because the known 
% campus blasts have highest signal amplitude in X, the program then 
% looks for the maximum signal in the X component of that inputted
% hour. Then, the program collects a 6 second interval surrounding that
% time in all components, and plots the seismometer's motion in the
% X-Y, Y-Z, and X-Z planes. Note that X is East-West, Y is North-South, 
% and Z is vertical. 
% 
% The same is done for the actual campus blast signals that are known, 
% as a basis of comparison. 
%
% INPUTS
% plotcb : Do we want to make the particle motion plots of the known 
%          campus blasts, or do we already have them saved?
%          0 - No, we have them
%          1 - Yes, let's make and save them!
% numdim : Are we making 2D or 3D particle motion plots?
%          2 - 2D (Default)
%          3 - 3D 
% maybehrs : Vector of hours, from which we will generate one-hour time
%            series to test for campus blasts using the method above.
%            Enter as a datetime, in UTC! 
% measval : Displacement, velocity, or acceleration?
%           0 for displacement in nm (default if left empty)
%           1 for velocity in nm/s 
%           2 for acceleration in nm/(s^2)
% frequency : The frequencies at which we wish to filter the data
%             Enter as a four-element vector 
%             Default: [0.75 1.50 5.00 10.00] Hz
% saveplots : Do we wish to save our plots?
%             0 - No
%             1 - Yes
% savedir : Where should we save our plots? Enter your own directory
%           or enter an empty string for the default option!
% 
% OUTPUTS
% The particle motion plots produced for each tested hour, as well
% as the known campus blasts. The plots will be 1 figure per event, 
% with subplots showing motion in the X-Y, X-Z, and Y-Z directions
% 
% See mstimes2sac.m, getcbtimes.m
%
% References
% Uses dat2jul.m, in csdms-contrib/slepian_oscar
% Uses defval.m in csdms-contrib/slepian_alpha 
% Campus blast information from Princeton University Facilities
% 
% Last Modified by Yuri Tamama, 09/19/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
defval('numdim',2)
defval('measval',0)
defval('frequency',[0.75 1.50 5.00 10.00])

if measval==0
  valunit='nm';
  vallabel='Displacement';
elseif measval==1
  valunit='nm/s';
  vallabel='Velocity';
else
  valunit='nm/s^2';
  vallabel='Acceleration';
end
% Frequencies
freqstr1=sprintf('%.2f',frequency(1));
freqstr2=sprintf('%.2f',frequency(2));
freqstr3=sprintf('%.2f',frequency(3));
freqstr4=sprintf('%.2f',frequency(4)); 
% Periods
pdstr1=sprintf('%.2f',1/frequency(1));
pdstr2=sprintf('%.2f',1/frequency(2));
pdstr3=sprintf('%.2f',1/frequency(3));
pdstr4=sprintf('%.2f',1/frequency(4));


% Make the particle motion plots for the known campus blasts!
% Then, move onto the events we want to test.

% Adjust this to condense the code, since we're repeating a LOT
cbtimes=getcbtimes('spr');
cbtimes.TimeZone='UTC';
cbtimes=vertcat(cbtimes,maybehrs);

for h=1:length(cbtimes)
  % Skip plotting the known campus blasts if needed
  if plotcb==0
    if h<4
      continue;
    end
  end
  
  timevec=1:360000;
  % Generate data of the hour during which the campus blast occurs
  starttime=cbtimes(h);
  starttime.Minute=0;
  finaltime=starttime;
  finaltime.Second=starttime.Second+3599.99;
  [cbsacfiles,~]=mstime2sac(measval,starttime,finaltime,...
    frequency,100,pwd,0,0,'');
  % Load the data for each component
  [zdata,~]=readsac(cbsacfiles{1},0);
  [ydata,~]=readsac(cbsacfiles{2},0);
  [xdata,~]=readsac(cbsacfiles{3},0);
    
  % Locate the blasts!
  % Known blasts: 
  if h<4
    % Cut to a 6 second interval around the blast
    newst=[1803*100; 2562*100; 2404*100];
    newend=[1809*100-1;2568*100-1;2410*100-1];
    inttime=starttime;
    % Time of start of interval
    inttime.Second=inttime.Second+(newst(h)/100);
    znew=zdata(newst(h):newend(h));
    ynew=ydata(newst(h):newend(h));
    xnew=xdata(newst(h):newend(h));
  % Signals to test
  else
    % Find the signals that might be the campus blasts! 
    % The campus blast signals are strongest in the X direction, so 
    % let's center our time interval there
    maxvalx=max(abs(xdata));
    maxtimex=timevec(abs(xdata)==maxvalx);
    maxtimex=maxtimex(1);
      
    % Check if we ***can*** make a 6 second interval... otherwise, extend
    % the length of the time series
    if maxtimex<301 || maxtimex>359701
      starttimenew=starttime;
      finaltimenew=finaltime;
      % Add 15 minutes to the time series! 
      if maxtimex<301
        starttimenew.Second=starttimenew.Second-900;
      end
      if maxtimex>359701
        finaltimenew.Second=finaltimenew.Second+900;
      end
      timevec=1:450000;
      [sacfiles,~]=mstime2sac(measval,starttimenew,finaltimenew,...
        frequency,100,pwd,0,0,'');
      % Retrieve new, extended data
      zdata=readsac(sacfiles{1},0);
      ydata=readsac(sacfiles{2},0);
      xdata=readsac(sacfiles{3},0);
      % Compute the maxima again
      maxvalx=max(abs(xdata));
      maxtimex=timevec(abs(xdata)==maxvalx);
      starttime=starttimenew;
    end  
      
    % Construct a 6 second interval around the maximum in X
    interval=maxtimex-300:maxtimex+299; 
    inttime=starttime;
    % Time when interval starts
    inttime.Second=inttime.Second+(interval(1))/100;
    % Time of maximum
    maxtime=starttime;
    maxtime.Second=maxtime.Second+(maxtimex/100);
    znew=zdata(interval);
    ynew=ydata(interval);
    xnew=xdata(interval);
  end
  
  % Plot the particle motions!! 
  % Figure out plot title
  monthnames={'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';...
    'Oct';'Nov';'Dec'};
  titlestr1=sprintf('%s Particle Motion',vallabel);
  titlestr2=sprintf(' %s %d %d, %s:%s:%s',...
    monthnames{inttime.Month},inttime.Day,inttime.Year,...
    datenum2str(inttime.Hour,0),datenum2str(inttime.Minute,0),...
    datenum2str(round(inttime.Second,2),0));
  if h<4
    titlestr2=strcat('Campus Blast from ',titlestr2);
  end
  titlestr3='Recorded at Guyot Hall, Princeton University (PP S0001)';
  freqtitle=['[',freqstr1,' {\color{magenta}',freqstr2,...
    ' \color{magenta}',freqstr3,'} ',freqstr4,'] Hz'];
  pdtitle=['[',pdstr4,' {\color{magenta}',pdstr3,' \color{magenta}',...
    pdstr2,'} ',pdstr1,'] s'];
  titlestr4=[freqtitle,'  ',pdtitle];  
  
  % Plot figure
  cbplot=figure();
  cbplot.Units='normalized';
  cmap=colormap(jet(length(znew)));
  % 2D Plot
  if numdim==2
    cbplot.OuterPosition(3)=0.95;
    cbplot.OuterPosition(4)=0.8;
    % Set up the axes and plot!
    hlbls={sprintf('X (%s)',valunit);sprintf('Y (%s)',valunit);...
      sprintf('X (%s)',valunit)};
    vlbls={sprintf('Z (%s)',valunit);sprintf('Z (%s)',valunit);...
      sprintf('Y (%s)',valunit)};
    for c=1:3
      ax=subplot(1,3,c);
      % X-Z
      if c==1
        ax.Position(1)=0.05;
        hdata=xnew;
        vdata=znew;
      % Y-Z
      elseif c==2
        ax.Position(1)=.36;
        hdata=ynew;
        vdata=znew;
      % X-Y
      else
        ax.Position(1)=.67;
        hdata=xnew;
        vdata=ynew;
      end
      ax.Position(3)=.25;
      ax.Position(4)=.68;
      ax.XLabel.FontSize=9;
      ax.YLabel.FontSize=9;
    
      % Plot a time varying plot!
      plot(hdata(1),vdata(1),'*-','MarkerEdgeColor',cmap(1,:),...
        'Color',cmap(1,:))
      hold on
      for i=1:length(vdata)
        if i<length(vdata)
          plot(hdata(i:i+1),vdata(i:i+1),'*-','MarkerEdgeColor',cmap(i,:),...
            'Color',cmap(i,:))
        else
          plot(hdata(i),vdata(i),'*-','MarkerEdgeColor',cmap(i,:),...
            'Color',cmap(i,:))
        end
        pause(0.005)
      end
      % Label axes
      xlabel(hlbls{c})
      ylabel(vlbls{c})
    
      % Add plot title
      if c==2
        ax.Title.String={titlestr1;titlestr2;titlestr3;titlestr4;' '};
        ax.Title.FontSize=9;
      end
      
      % Set axis limits
      xlim([-max(abs(hdata)) max(abs(hdata))])
      ylim([-max(abs(vdata)) max(abs(vdata))])
      % Plot vertical and horizontal lines at 0
      line([0 0],ylim,'Color',[.55 .55 .55]);
      line(xlim,[0 0],'Color',[.55 .55 .55]);
    end 
    
  % 3D Plot
  else
    plot3(xnew(1),ynew(1),znew(1),'*-','MarkerEdgeColor',cmap(1,:),...
      'Color',cmap(1,:))
    hold on
    for i=1:length(znew)
      if i<length(znew)
        plot3(xnew(i:i+1),ynew(i:i+1),znew(i:i+1),'*-',...
          'MarkerEdgeColor',cmap(i,:),'Color',cmap(i,:))
      else
        plot3(xnew(i),ynew(i),znew(i),'*-',...
          'MarkerEdgeColor',cmap(i,:),'Color',cmap(i,:))
      end
      pause(0.005)
    end
    line([0 0],[0 0],zlim,'Color',[.55 .55 .55]);
    line(xlim,[0 0],[0 0],'Color',[.55 .55 .55]);
    line([0 0],ylim,[0 0],'Color',[.55 .55 .55]);
    
    % Label axes
    xlabel(sprintf('X (%s)',valunit))
    ylabel(sprintf('Y (%s)',valunit))
    zlabel(sprintf('Z (%s)',valunit))
    % Set axis limits
    xlim([-max(abs(xnew)) max(abs(xnew))])
    ylim([-max(abs(ynew)) max(abs(ynew))])
    zlim([-max(abs(znew)) max(abs(znew))])
    % Add plot title
    ax=gca;
    ax.Title.String={titlestr1;titlestr2;titlestr3;titlestr4;' '};
    ax.Title.FontSize=9;
    % Adjust the plot axis size
    ax.Position(3)=.7;
  end
  cbar=colorbar;
  if numdim==2
    cbar.Position(1)=.95;
  else
    cbar.Position(1)=.88;
  end
  cbar.Ticks=[0:100:600]*(1/600);
  cbar.TickLabelsMode='manual';
  cbar.TickLabels={'0';'1';'2';'3';'4';'5';'6'};
  cbar.Label.String=sprintf('Time (s) since %s:%s:%s GMT',...
    datenum2str(inttime.Hour,0),datenum2str(inttime.Minute,0),...
    datenum2str(inttime.Second,0));
  hold off
  
  % Save plot
  if saveplot==1
    jdstr=datenum2str(dat2jul(inttime.Month,inttime.Day,inttime.Year),1);
    figname=sprintf('.%d.%s.%s%s%s.%s.%s%s%s%s.eps',inttime.Year,jdstr,...
      datenum2str(inttime.Hour,0),datenum2str(inttime.Minute,0),...
      datenum2str(round(inttime.Second),0),lower(vallabel(1:4)),freqstr1,...
      freqstr2,freqstr3,freqstr4);
    if h<4
      if numdim==2
        figname=strcat('CBMotion.2D',figname);
      else
        figname=strcat('CBMotion.3D',figname);
      end
    else
      if numdim==2
        figname=strcat('CBMtest.2D',figname);
      else
        figname=strcat('CBMtest.3D',figname);
      end
    end
    figname2=figdisp(figname,[],[],1,[],'epstopdf');
    if ~isempty(savedir)
      [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
      figname=fullfile(savedir,figname);
    else
      figname=figname2;
    end
    pause(1)
    % Also have a PNG copy
    fignamepng=figname;
    fignamepng(length(figname)-2:length(figname))='png';
    pngcmd=sprintf('convert -density 250 %s %s',figname,fignamepng);
    [status,cmdout]=system(pngcmd);
    pause(1)
  end
end

