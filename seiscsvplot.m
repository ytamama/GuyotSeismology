function figurehdls=seiscsvplot(csvfile,timeinfo,startstr,avgmode,...
  measval,frequency,tzlabel,saveplot,savedir)
%
% Function to plot the percent changes of mean root mean squared (RMS)
% ground motion, recorded in the CSV file created in seiscsv.m. 
% 
% This function makes 1 or 3 figures:
% 3 Figure case (avgmode=0):
% 1 : Showing the percent changes over the nights, mornings, 
%     afternoons, and evenings, without regard to weekday-weekend
%     distinctions
% 2 : Showing the percent changes over the weekday nights, mornings, 
%     afternoons, and evenings
% 3 : Showing the percent changes over the weekend nights, mornings, 
%     afternoons, and evenings
%
% 1 Figure case (avgmode=1):
% 1 : Shows the percent changes of RMS ground motion over the nights, 
%     mornings, afternoons, and evenings over each weekday.
%
% Note
% Night : 00:00:00 - 05:59:59.99 Local Time
% Morning : 06:00:00 - 11:59:59 Local Time
% Afternoon : 12:00:00 - 17:59:59 Local Time
% Evening : 18:00:00 - 23:59:59 Local Time
% 
% INPUTS
% csvfile : CSV file of percent differences, as made in seiscsv.m. The 
%           columns, from left to right, are:
%           The name of the month corresponding to the CSV file + 
%           directional component (Z or H); percent change overall;
%           percent change over weekdays; weekends;
%           nights overall; weekday nights; weekend nights; 
%           mornings overall; weekday mornings; weekend mornings;
%           afternoons overall; weekday afternoons; weekend afternoons; 
%           evenings overall; weekday evenings; weekend evenings
% timeinfo : How did we compute the entered percent changes?
%            1 : We compare the RMS ground motion in one month to that of
%                the other months in the same year
%            2 : We compare the RMS ground motion in some months of a year
%                to those of the corresponding months in another year
%
% startstr : A string indicating with respect to what time (e.g. month or
%            year) the percent values were computed. Examples: 
%            '2018'; 'February 2018'
%            Enter a month + year for timeinfo = 1
%            Enter a year for timeinfo = 2
% avgmode : How should we compute the means?
%           0 : By using the categories specified above (i.e. weekday 
%               morning, weekend afternoon, etc.)
%           1 : By averaging the "time of day" categories over each 
%               weekday
% measval : What are these CSV files measuring?
%           0 : Displacement (nm; Default)
%           1 : Velocity (nm/s)
%           2 : Acceleration (nm/s^2)
% frequency : Through what frequencies were the seismic data filtered? 
%             Enter as a four element vector!
% tzlabel : The label characterizing the time zone of the times plotted
% saveplots : Do we wish to save them?
%             0 : No
%             1 : Yes
% savedir : If saving graphics, where do we wish to save them?
%           Enter nothing for the default, the current working directory
%
% OUTPUTS
% figurehdls : The figure handles of our figures created, in the order in
%              which they were created
%
% References
% Uses defval.m, figdisp.m, adrc.m, longticks.m in 
% csdms-contrib/slepian_alpha 
% Working with subplot background colors, colorbars, and colormap is 
% something I learned from MATLAB documentation and online forums.
% Consulted http://www.ece.northwestern.edu/local-apps/matlabhelp/techdoc/
% ref/caxis.html for help with caxis
% These time-based categories are based off of those used in 
% Groos and Ritter (2009).
% This routine is inspired by 
% Lecocq et al., (2020), DOI: 10.1126/science.abd2438
% and
% SeismoRMS, by Thomas Lecocq et. al.,
% https://github.com/ThomasLecocq/SeismoRMS
%
% See guyotrmsseishr.m, seiscsv.m
% 
% Last Modified by Yuri Tamama, 12/27/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('measval',0)
defval('savedir',pwd)

% Load the percent changes from the CSV file
prcdata=readtable(csvfile,'Delimiter',',');
% Separate the data by component
ztbl=prcdata(contains(prcdata.csvlblsprc,'_Z'),:);
htbl=prcdata(contains(prcdata.csvlblsprc,'_H'),:);

% Strings needed for figure titles and names
vallbls={'Displacement';'Velocity';'Acceleration'};
freqstr2=sprintf('%.2f',frequency(2));
freqstr3=sprintf('%.2f',frequency(3));
% Today's date
todaytime=datetime('now');
todaytime.TimeZone='America/New_York';
todayymd=sprintf('%d%s%s',todaytime.Year,datenum2str(...
  todaytime.Month,0),datenum2str(todaytime.Day,0));

figurehdls=[];
% Plot the 1 figure case or the first figure of the 3 figure case
figure1=figure();
figure1.Units='normalized';
figure1.Position(1)=0.2;
figure1.Position(2)=0.15;
figure1.Position(3)=0.85;
numrows=size(prcdata);
numrows=numrows(1);
nummon=numrows/2;  
% Axes labels
if avgmode==0
  haxlbls={'Overall';{'Night';sprintf('00:00 - 06:00 %s',tzlabel)};...
    {'Morning';sprintf('06:00 - 12:00 %s',tzlabel)};...
    {'Afternoon';sprintf('12:00 - 18:00 %s',tzlabel)};...
    {'Evening';sprintf('18:00 - 24:00 %s',tzlabel)}};
else
  haxlbls={'Monday';'Tuesday';'Wednesday';'Thursday';'Friday';...
    'Saturday';'Sunday'};
end

% Set up a colormap
cmapred=[ones(1,75);linspace(1,0,75);linspace(1,0,75)].';
cmapblue=[linspace(0,1,75);linspace(0,1,75);ones(1,75)].';
cmapblue=cmapblue(1:74,:);
cmapnow=vertcat(cmapblue,cmapred);
colormap(cmapnow);
caxis([-.75 .75])


% Plot the percent changes!
if avgmode==0
  for t=1:5 
    prcvecz=zeros(nummon,1);
    prcvech=zeros(nummon,1);
    prclblsz={};
    prclblsh={};
    if t==1
      yticklblz={};
      yticklblh={};
    end
    for c=1:nummon
      % Get the percent changes for that month, in the Z and H components,
      % in order
      vertrow=ztbl(c,:);
      horzrow=htbl(c,:);
      % Normalize with respect to -1 to 1
      prcvecz(c)=(1/100)*vertrow.(3*(t-1)+2);
      prcvech(c)=(1/100)*horzrow.(3*(t-1)+2); 
      % Also collect the actual but rounded percentages, for labeling
      prclblsz=vertcat(prclblsz,...
        sprintf(' %s%%',num2str(round(vertrow.(3*(t-1)+2)))));
      prclblsh=vertcat(prclblsh,...
        sprintf(' %s%%',num2str(round(horzrow.(3*(t-1)+2)))));
      % Get month labels!
      if t==1
        datestrsz=vertrow.(1);
        datestrsz=datestrsz{1};
        datestrsz=strsplit(datestrsz,'_');
        yticklblz=vertcat(yticklblz,sprintf('%s %s',datestrsz{2},'Z'));
        nowyr=datestrsz{1};
        %
        datestrsh=horzrow.(1);
        datestrsh=datestrsh{1};
        datestrsh=strsplit(datestrsh,'_');
        yticklblh=vertcat(yticklblh,sprintf('%s %s',datestrsh{2},'H'));
        
        if c==1
          startmy=strcat(datestrsz{2},datestrsz{1});
        end
        if c==nummon
          finmy=strcat(datestrsz{2},datestrsz{1});
        end
      end
    end
    
    % Make a colormap with pcolor
    % Z
    subplot(2,5,t)
    pcolor(adrc(prcvecz))
    colormap(cmapnow);
    zax=gca;
    zax.Position(2)=zax.Position(2)*.975;
    zax.Position(3)=.12;
    if t>1
      zax.Position(1)=zax.Position(1)+.04;
    else
      zax.Position(1)=zax.Position(1)+.0125; 
    end
    caxis([-.75 .75])
    % Fix the ordering
    axis ij
    nolabels(zax,2)
    nolabels(zax,1)
    % Y Ticks on the left to indicate the months, if this is the leftmost plot
    if t==1
      yyaxis left
      zax.YTick=linspace(zax.YLim(1)+(zax.YLim(2)-zax.YLim(1))/(nummon*2),...
        zax.YLim(2)-(zax.YLim(2)-zax.YLim(1))/(nummon*2),nummon);
      zax.YTickLabel=yticklblz;
      % Y axis is reversed! 
    end
    % Y Ticks on the right to plot rounded percent changes
    yyaxis right
    zaxrt=gca;
    zaxrt.YTick=linspace(zaxrt.YLim(1)+(zaxrt.YLim(2)-zaxrt.YLim(1))/(nummon*2),...
      zaxrt.YLim(2)-(zaxrt.YLim(2)-zaxrt.YLim(1))/(nummon*2),nummon);
    zaxrt.YTickLabel=flip(prclblsz);
    zaxrt.YColor=[0 0 0];
    % X Label to indicate the time of day
    zax.XLabel.String=haxlbls{t};
    % Plot title on the 2nd subplot
    if t==2
      if timeinfo==1
        titlestr1=sprintf('Percent Change in Ground %s with respect to %s',...
          vallbls{measval+1},startstr);
      else
        titlestr1=sprintf('Percent Change in Ground %s in %s with respect to %s',...
          vallbls{measval+1},nowyr,startstr);
      end
      titlestr2=sprintf('Filtered between %s and %s Hz',freqstr2,freqstr3);
      zax.Title.String={titlestr1;titlestr2};
      zax.Title.Position(1)=2.5;
      zax.Title.Position(2)=.95;
      zax.Title.FontSize=8.4;
    end
    % Cosmetics
    shading flat
    zax.Box='on';
    zax.LineWidth=1.5;
    
    % H
    subplot(2,5,t+5)
    pcolor(adrc(prcvech))
    colormap(cmapnow);
    hax=gca;
    hax.Position(3)=zax.Position(3);
    hax.Position(1)=zax.Position(1);
    caxis([-.75 .75])  
    % Fix the ordering
    axis ij
    nolabels(hax,2)
    nolabels(hax,1)
    % Y Ticks on the left to indicate the months, if this is the leftmost plot
    if t==1
      yyaxis left
      hax.YTick=linspace(hax.YLim(1)+(hax.YLim(2)-hax.YLim(1))/(nummon*2),...
        hax.YLim(2)-(hax.YLim(2)-hax.YLim(1))/(nummon*2),nummon);
      hax.YTickLabel=yticklblh;
    end
    % Y Ticks on the right to plot rounded percent changes
    yyaxis right
    haxrt=gca;
    haxrt.YTick=linspace(haxrt.YLim(1)+(haxrt.YLim(2)-haxrt.YLim(1))/(nummon*2),...
      haxrt.YLim(2)-(haxrt.YLim(2)-haxrt.YLim(1))/(nummon*2),nummon);
    haxrt.YTickLabel=flip(prclblsh);
    haxrt.YColor=[0 0 0];
    
    % X Label to indicate the time of day
    hax.XLabel.String=haxlbls{t};
    % Cosmetics
    shading flat
    hax.Box='on';
    hax.LineWidth=1.5;
  end
  
else
  for d=1:7
    % Matrix to store our color coded percentiles for each day
    prcvecz=zeros(nummon,4);
    prcvech=zeros(nummon,4);
    prclblsz={};
    prclblsh={};
    if d==1
      yticklblz={};
      yticklblh={};
    end
    for c=1:nummon    
      % Get the data for that month, in the Z and H components
      vertrow=ztbl(c,:);
      horzrow=htbl(c,:);
      for t=1:4
        % Populate each row of the matrix
        prcvecz(c,t)=(1/100)*vertrow.(4*(d-1)+t+1);
        prcvech(c,t)=(1/100)*horzrow.(4*(d-1)+t+1);
        % Also collect the actual but rounded percentages, for labeling
        prclblsz=vertcat(prclblsz,...
          sprintf(' %s%%',num2str(round(vertrow.(4*(d-1)+t+1)))));
        prclblsh=vertcat(prclblsh,...
          sprintf(' %s%%',num2str(round(horzrow.(4*(d-1)+t+1)))));
      end
      % Tick Labels to indicate the month
      if d==1
        datestrsz=vertrow.(1);
        datestrsz=datestrsz{1};
        datestrsz=strsplit(datestrsz,'_');
        yticklblz=vertcat(yticklblz,sprintf('%s %s',datestrsz{2},'Z'));
        nowyr=datestrsz{1};
        %
        datestrsh=horzrow.(1);
        datestrsh=datestrsh{1};
        datestrsh=strsplit(datestrsh,'_');
        yticklblh=vertcat(yticklblh,sprintf('%s %s',datestrsh{2},'H'));
        
        if c==1
          startmy=strcat(datestrsz{2},datestrsz{1});
        end
        if c==nummon
          finmy=strcat(datestrsz{2},datestrsz{1});
        end
      end
    end  
    
    % Make a colormap with pcolor
    % Z
    subplot(2,7,d)
    pcolor(adrc(prcvecz))
    colormap(cmapnow);
    zax=gca;
    zax.Position(2)=zax.Position(2)*.975;
    caxis([-.75 .75])
    % Fix the ordering
    axis ij
    nolabels(zax,2)
    % Y Ticks to indicate the months, if this is the leftmost plot
    if d==1
      yyaxis left
      zax.YTick=linspace(zax.YLim(1)+(zax.YLim(2)-zax.YLim(1))/(nummon*2),...
        zax.YLim(2)-(zax.YLim(2)-zax.YLim(1))/(nummon*2),nummon);
      zax.YTickLabel=yticklblz;
    end
    % Y Ticks on the right to plot rounded percent changes
    yyaxis right
    zaxrt=gca;
    zaxrt.YTick=linspace(zaxrt.YLim(1)+(zaxrt.YLim(2)-zaxrt.YLim(1))/(nummon*2),...
      zaxrt.YLim(2)-(zaxrt.YLim(2)-zaxrt.YLim(1))/(nummon*2),nummon);
    zaxrt.YTickLabel=flip(prclblsz);
    zaxrt.YColor=[0 0 0];
    % X Label to indicate the weekday
    zax.XLabel.String=haxlbls{d};
    % X Ticks to indicate time of day
    zax.XTick=linspace(zax.XLim(1)+(zax.XLim(2)-zax.XLim(1))/8,...
      zax.XLim(2)-(zax.XLim(2)-zax.XLim(1))/8,4);
    zax.XTickLabel={'N';'M';'A';'E'};
    % Plot title on the middle subplot
    if d==4
      if timeinfo==1
        titlestr1=sprintf('Percent Change in Ground %s with respect to %s',...
          vallbls{measval+1},startstr);
      else
        titlestr1=sprintf('Percent Change in Ground %s in %s with respect to %s',...
          vallbls{measval+1},nowyr,startstr);
      end
      titlestr2=sprintf('Filtered between %s and %s Hz',freqstr2,freqstr3);
      zax.Title.String={titlestr1;titlestr2};
      zax.Title.Position(2)=.95;
      zax.Title.FontSize=8.4;
    end
    % Cosmetics
    shading flat
    zax.Box='on';
    zax.LineWidth=1.5;
    
    % H
    subplot(2,7,d+7)
    pcolor(adrc(prcvech))
    colormap(cmapnow);
    hax=gca;
    caxis([-.75 .75])  
    hax.Position(3)=zax.Position(3);
    % Fix the ordering
    axis ij
    nolabels(hax,2)
    % Y Ticks to indicate the months, if this is the leftmost plot
    if d==1
      yyaxis left
      hax.YTick=linspace(hax.YLim(1)+(hax.YLim(2)-hax.YLim(1))/(nummon*2),...
        hax.YLim(2)-(hax.YLim(2)-hax.YLim(1))/(nummon*2),nummon);
      hax.YTickLabel=yticklblh;
    end
    % Y Ticks on the right to plot rounded percent changes
    yyaxis right
    haxrt=gca;
    haxrt.YTick=linspace(haxrt.YLim(1)+(haxrt.YLim(2)-haxrt.YLim(1))/(nummon*2),...
      haxrt.YLim(2)-(haxrt.YLim(2)-haxrt.YLim(1))/(nummon*2),nummon);
    haxrt.YTickLabel=flip(prclblsh);
    haxrt.YColor=[0 0 0];
    % X Label to indicate the weekday
    hax.XLabel.String=haxlbls{d};
    % X Ticks to indicate time of day
    hax.XTick=linspace(hax.XLim(1)+(hax.XLim(2)-hax.XLim(1))/8,...
      hax.XLim(2)-(hax.XLim(2)-hax.XLim(1))/8,4);
    hax.XTickLabel={'N';'M';'A';'E'};
    % Cosmetics
    shading flat
    hax.Box='on';
    hax.LineWidth=1.5;
  end
end

% Include a colorbar! 
colormap(cmapnow);
caxis([-.75 .75])
cbar=colorbar;
cbar.Position(1)=0.05;
cbar.Position(2)=0.14;
cbar.Position(3)=0.0175;
cbar.Position(4)=0.75;
cbar.Ticks=[-.75 -.375 0 .375 .75];
cbar.TickLabels={'-75';'-37.5';'0';'37.5';'75'};
cbar.Label.String='Percent Change';
cbar.Label.FontSize=9;
cbar.Label.Position(1)=-1.65;
colormap(cmapnow);

figurehdls=[figurehdls; figure1];
% Save this plot
if saveplot==1
  vallblmini=vallbls{measval+1};
  vallblmini=vallblmini(1);
  freqstr1=sprintf('%.2f',frequency(1));
  freqstr4=sprintf('%.2f',frequency(4));
  if timeinfo==1
    if avgmode==0
      figname1=sprintf('RMS%sinNM_OvPrcChg_Mon_%sto%s_wrt%s_%s_%s_%s%s%s%s.eps',...
        vallblmini,startmy,finmy,replace(startstr,' ',''),todayymd,...
        tzlabel,freqstr1,freqstr2,freqstr3,freqstr4);
    else
      figname1=sprintf('RMS%sinNM_WklyPrcChg_Mon_%sto%s_wrt%s_%s_%s_%s%s%s%s.eps',...
        vallblmini,startmy,finmy,replace(startstr,' ',''),todayymd,...
        tzlabel,freqstr1,freqstr2,freqstr3,freqstr4);
    end
  else
    if avgmode==0
      figname1=sprintf('RMS%sinNM_OvPrcChg_Yr_%sto%s_wrt%s_%s_%s_%s%s%s%s.eps',...
        vallblmini,startmy,finmy,replace(startstr,' ',''),todayymd,...
        tzlabel,freqstr1,freqstr2,freqstr3,freqstr4);
    else
      figname1=sprintf('RMS%sinNM_WklyPrcChg_Yr_%sto%s_wrt%s_%s_%s_%s%s%s%s.eps',...
        vallblmini,startmy,finmy,replace(startstr,' ',''),todayymd,...
        tzlabel,freqstr1,freqstr2,freqstr3,freqstr4);
    end
  end
  fignameb=figdisp(figname1,[],[],1,[],'epstopdf');
  pause(0.5)
  if ~strcmpi(savedir,pwd)
    [status,cmdout]=system(sprintf('mv %s %s',fignameb,savedir));
    figname1=fullfile(savedir,figname1);
    pause(0.25)
  end
  % Convert to PNG
  fignamepng=strcat(figname1(1:length(figname1)-3),'png');
  [status,cmdout]=system(sprintf('convert -density 250 %s %s',figname1,...
    fignamepng));
  pause(0.25)
end


% Make 2 more figures, for the weekends and weekdays, if requested
if avgmode==0
  colormap(cmapnow);
  caxis([-.75 .75])
  % 2 : Percent change over weekdays 
  figure2=figure();
  figure2.Units='normalized';
  figure2.Position(1)=0.2;
  figure2.Position(2)=0.15;
  figure2.Position(3)=0.85;
  for t=1:5 
    prcvecz=zeros(nummon,1);
    prcvech=zeros(nummon,1);
    prclblsz={};
    prclblsh={};
    if t==1
      yticklblz={};
      yticklblh={};
    end
    for c=1:nummon
      % Get the data for that month, in the Z and H components
      vertrow=ztbl(c,:);
      horzrow=htbl(c,:);
      % Populate each row of the matrix
      prcvecz(c)=(1/100)*vertrow.(3*(t-1)+3);
      prcvech(c)=(1/100)*horzrow.(3*(t-1)+3); 
      % Also collect the actual but rounded percentages, for labeling
      prclblsz=vertcat(prclblsz,...
        sprintf(' %s%%',num2str(round(vertrow.(3*(t-1)+3)))));
      prclblsh=vertcat(prclblsh,...
        sprintf(' %s%%',num2str(round(horzrow.(3*(t-1)+3)))));
      % Get month labels!
      if t==1
        datestrsz=vertrow.(1);
        datestrsz=datestrsz{1};
        datestrsz=strsplit(datestrsz,'_');
        yticklblz=vertcat(yticklblz,sprintf('%s %s',datestrsz{2},'Z'));
        nowyr=datestrsz{1};
        %
        datestrsh=horzrow.(1);
        datestrsh=datestrsh{1};
        datestrsh=strsplit(datestrsh,'_');
        yticklblh=vertcat(yticklblh,sprintf('%s %s',datestrsh{2},'H'));
        %
        if c==1
          startmy=strcat(datestrsz{2},datestrsz{1});
        end
        if c==nummon
          finmy=strcat(datestrsz{2},datestrsz{1});
        end
      end
    end
    
    % Make a colormap with pcolor
    % Z
    subplot(2,5,t)
    pcolor(adrc(prcvecz))
    colormap(cmapnow);
    zax=gca;
    zax.Position(2)=zax.Position(2)*.975;
    zax.Position(3)=.12;
    if t>1
      zax.Position(1)=zax.Position(1)+.04;
    else
      zax.Position(1)=zax.Position(1)+.0125; 
    end
    caxis([-.75 .75])
    % Fix the ordering
    axis ij
    nolabels(zax,2)
    nolabels(zax,1)
    % Y Ticks to indicate the months, if this is the leftmost plot
    if t==1
      yyaxis left
      zax.YTick=linspace(zax.YLim(1)+(zax.YLim(2)-zax.YLim(1))/(nummon*2),...
        zax.YLim(2)-(zax.YLim(2)-zax.YLim(1))/(nummon*2),nummon);
      zax.YTickLabel=yticklblz;
    end
    % Y Ticks on the right to plot rounded percent changes
    yyaxis right
    zaxrt=gca;
    zaxrt.YTick=linspace(zaxrt.YLim(1)+(zaxrt.YLim(2)-zaxrt.YLim(1))/(nummon*2),...
      zaxrt.YLim(2)-(zaxrt.YLim(2)-zaxrt.YLim(1))/(nummon*2),nummon);
    zaxrt.YTickLabel=flip(prclblsz);
    zaxrt.YColor=[0 0 0];
    % X Label to indicate the time of day
    zax.XLabel.String=haxlbls{t};
    % Plot title on the 2nd subplot
    if t==2
      if timeinfo==1
        titlestr1=sprintf('Percent Change in Weekday Ground %s with respect to %s',...
          vallbls{measval+1},startstr);
      else
        titlestr1=sprintf('Percent Change in Weekday Ground %s in %s with respect to %s',...
          vallbls{measval+1},nowyr,startstr);
      end
      titlestr2=sprintf('Filtered between %s and %s Hz',freqstr2,freqstr3);
      zax.Title.String={titlestr1;titlestr2};
      zax.Title.Position(1)=2.5;
      zax.Title.Position(2)=.95;
      zax.Title.FontSize=8.4;
    end
    % Cosmetics
    shading flat
    zax.Box='on';
    zax.LineWidth=1.5;
    
    % H
    subplot(2,5,t+5)
    pcolor(adrc(prcvech))
    colormap(cmapnow);
    hax=gca;
    caxis([-.75 .75])
    hax.Position(3)=zax.Position(3);
    hax.Position(1)=zax.Position(1);
    % Fix the ordering
    axis ij
    nolabels(hax,2)
    nolabels(hax,1)
    % Y Ticks to indicate the months, if this is the leftmost plot
    if t==1
      yyaxis left
      hax.YTick=linspace(hax.YLim(1)+(hax.YLim(2)-hax.YLim(1))/(nummon*2),...
        hax.YLim(2)-(hax.YLim(2)-hax.YLim(1))/(nummon*2),nummon);
      hax.YTickLabel=yticklblh;
    end
    % Y Ticks on the right to plot rounded percent changes
    yyaxis right
    haxrt=gca;
    haxrt.YTick=linspace(haxrt.YLim(1)+(haxrt.YLim(2)-haxrt.YLim(1))/(nummon*2),...
      haxrt.YLim(2)-(haxrt.YLim(2)-haxrt.YLim(1))/(nummon*2),nummon);
    haxrt.YTickLabel=flip(prclblsh);
    haxrt.YColor=[0 0 0];
    % X Label to indicate the time of day
    hax.XLabel.String=haxlbls{t};
    % Cosmetics
    shading flat
    hax.Box='on';
    hax.LineWidth=1.5;
  end
  
  % Add a colorbar
  colormap(cmapnow);
  cbar=colorbar;
  cbar.Position(1)=0.05;
  cbar.Position(2)=0.14;
  cbar.Position(3)=0.0175;
  cbar.Position(4)=0.75;
  cbar.Ticks=[-.75 -.375 0 .375 .75];
  cbar.TickLabels={'-75';'-37.5';'0';'37.5';'75'};
  cbar.Label.String='Percent Change';
  cbar.Label.FontSize=9;
  cbar.Label.Position(1)=-1.65;
  colormap(cmapnow);
  
  figurehdls=[figurehdls; figure2];
  % Save this plot
  if saveplot==1
    vallblmini=vallbls{measval+1};
    vallblmini=vallblmini(1);
    freqstr1=sprintf('%.2f',frequency(1));
    freqstr4=sprintf('%.2f',frequency(4));
    if timeinfo==1
      figname2=sprintf('RMS%sinNM_WkdayPrcChg_Mon_%sto%s_wrt%s_%s_%s_%s%s%s%s.eps',...
        vallblmini,startmy,finmy,replace(startstr,' ',''),todayymd,...
        tzlabel,freqstr1,freqstr2,freqstr3,freqstr4);
    else
      figname2=sprintf('RMS%sinNM_WkdayPrcChg_Yr_%sto%s_wrt%s_%s_%s_%s%s%s%s.eps',...
        vallblmini,startmy,finmy,replace(startstr,' ',''),todayymd,...
        tzlabel,freqstr1,freqstr2,freqstr3,freqstr4);
    end
    fignameb=figdisp(figname2,[],[],1,[],'epstopdf');
    pause(0.25)
    if ~strcmpi(savedir,pwd)
      [status,cmdout]=system(sprintf('mv %s %s',fignameb,savedir));
      figname2=fullfile(savedir,figname2);
      pause(0.25)
    end
    % Convert to PNG
    fignamepng=strcat(figname2(1:length(figname2)-3),'png');
    [status,cmdout]=system(sprintf('convert -density 250 %s %s',...
      figname2,fignamepng));
    pause(0.25)
  end
  
  
  % 3 : Percent change over weekends 
  colormap(cmapnow);
  caxis([-.75 .75])
  figure3=figure();
  figure3.Units='normalized';
  figure3.Position(1)=0.2;
  figure3.Position(2)=0.15;
  figure3.Position(3)=0.85;
  
  for t=1:5 
    prcvecz=zeros(nummon,1);
    prcvech=zeros(nummon,1);
    prclblsz={};
    prclblsh={};
    if t==1
      yticklblz={};
      yticklblh={};
    end
    for c=1:nummon
      % Get the data for that month, in the Z and H components
      vertrow=ztbl(c,:);
      horzrow=htbl(c,:);
      % Populate each row of the matrix
      prcvecz(c)=(1/100)*vertrow.(3*(t-1)+4);
      prcvech(c)=(1/100)*horzrow.(3*(t-1)+4); 
      % Also collect the actual but rounded percentages, for labeling
      prclblsz=vertcat(prclblsz,...
        sprintf(' %s%%',num2str(round(vertrow.(3*(t-1)+4)))));
      prclblsh=vertcat(prclblsh,...
        sprintf(' %s%%',num2str(round(horzrow.(3*(t-1)+4)))));
      % Get month labels!
      if t==1
        datestrsz=vertrow.(1);
        datestrsz=datestrsz{1};
        datestrsz=strsplit(datestrsz,'_');
        yticklblz=vertcat(yticklblz,sprintf('%s %s',datestrsz{2},'Z'));
        nowyr=datestrsz{1};
        %
        datestrsh=horzrow.(1);
        datestrsh=datestrsh{1};
        datestrsh=strsplit(datestrsh,'_');
        yticklblh=vertcat(yticklblh,sprintf('%s %s',datestrsh{2},'H'));
        %
        if c==1
          startmy=strcat(datestrsz{2},datestrsz{1});
        end
        if c==nummon
          finmy=strcat(datestrsz{2},datestrsz{1});
        end
      end
    end
    
    % Make a colormap with pcolor
    % Z
    subplot(2,5,t)
    pcolor(adrc(prcvecz))
    colormap(cmapnow);
    zax=gca;
    zax.Position(2)=zax.Position(2)*.975;
    zax.Position(3)=.12;
    if t>1
      zax.Position(1)=zax.Position(1)+.04;
    else
      zax.Position(1)=zax.Position(1)+.0125; 
    end
    caxis([-.75 .75])
    % Fix the ordering
    axis ij
    nolabels(zax,2)
    nolabels(zax,1)
    % Y Ticks to indicate the months, if this is the leftmost plot
    if t==1
      yyaxis left
      zax.YTick=linspace(zax.YLim(1)+(zax.YLim(2)-zax.YLim(1))/(nummon*2),...
        zax.YLim(2)-(zax.YLim(2)-zax.YLim(1))/(nummon*2),nummon);
      zax.YTickLabel=yticklblz;
    end
    % Y Ticks on the right to plot rounded percent changes
    yyaxis right
    zaxrt=gca;
    zaxrt.YTick=linspace(zaxrt.YLim(1)+(zaxrt.YLim(2)-zaxrt.YLim(1))/(nummon*2),...
      zaxrt.YLim(2)-(zaxrt.YLim(2)-zaxrt.YLim(1))/(nummon*2),nummon);
    zaxrt.YTickLabel=flip(prclblsz);
    zaxrt.YColor=[0 0 0];
    % X Label to indicate the time of day
    zax.XLabel.String=haxlbls{t};
    % Plot title on the 2nd subplot
    if t==2
      if timeinfo==1
        titlestr1=sprintf('Percent Change in Weekend Ground %s with respect to %s',...
          vallbls{measval+1},startstr);
      else
        titlestr1=sprintf('Percent Change in Weekend Ground %s in %s with respect to %s',...
          vallbls{measval+1},nowyr,startstr);
      end
      titlestr2=sprintf('Filtered between %s and %s Hz',freqstr2,freqstr3);
      zax.Title.String={titlestr1;titlestr2};
      zax.Title.Position(1)=2.5;
      zax.Title.Position(2)=.95;
      zax.Title.FontSize=8.4;
    end
    % Cosmetics
    shading flat
    zax.Box='on';
    zax.LineWidth=1.5;
    
    % H
    subplot(2,5,t+5)
    pcolor(adrc(prcvech))
    colormap(cmapnow);
    hax=gca;
    caxis([-.75 .75])    
    hax.Position(3)=zax.Position(3);
    hax.Position(1)=zax.Position(1);
    % Fix the ordering
    axis ij
    nolabels(hax,2)
    nolabels(hax,1)
    % Y Ticks to indicate the months, if this is the leftmost plot
    if t==1
      yyaxis left
      hax.YTick=linspace(hax.YLim(1)+(hax.YLim(2)-hax.YLim(1))/(nummon*2),...
        hax.YLim(2)-(hax.YLim(2)-hax.YLim(1))/(nummon*2),nummon);
      hax.YTickLabel=yticklblh;
    end
    % Y Ticks on the right to plot rounded percent changes
    yyaxis right
    haxrt=gca;
    haxrt.YTick=linspace(haxrt.YLim(1)+(haxrt.YLim(2)-haxrt.YLim(1))/(nummon*2),...
      haxrt.YLim(2)-(haxrt.YLim(2)-haxrt.YLim(1))/(nummon*2),nummon);
    haxrt.YTickLabel=flip(prclblsh);
    haxrt.YColor=[0 0 0];
    % X Label to indicate the time of day
    hax.XLabel.String=haxlbls{t};
    % Cosmetics
    shading flat
    hax.Box='on';
    hax.LineWidth=1.5;
  end
  
  % Add a colorbar
  colormap(cmapnow);
  cbar=colorbar;
  cbar.Position(1)=0.05;
  cbar.Position(2)=0.14;
  cbar.Position(3)=0.0175;
  cbar.Position(4)=0.75;
  cbar.Ticks=[-.75 -.375 0 .375 .75];
  cbar.TickLabels={'-75';'-37.5';'0';'37.5';'75'};
  cbar.Label.String='Percent Change';
  cbar.Label.FontSize=9;
  cbar.Label.Position(1)=-1.65;
  colormap(cmapnow);
  
  figurehdls=[figurehdls; figure3];
  % Save this plot
  if saveplot==1
    vallblmini=vallbls{measval+1};
    vallblmini=vallblmini(1);
    freqstr1=sprintf('%.2f',frequency(1));
    freqstr4=sprintf('%.2f',frequency(4));
    if timeinfo==1
      figname3=sprintf('RMS%sinNM_WkendPrcChg_Mon_%sto%s_wrt%s_%s_%s_%s%s%s%s.eps',...
        vallblmini,startmy,finmy,replace(startstr,' ',''),todayymd,...
        tzlabel,freqstr1,freqstr2,freqstr3,freqstr4);
    else
      figname3=sprintf('RMS%sinNM_WkendPrcChg_Yr_%sto%s_wrt%s_%s_%s_%s%s%s%s.eps',...
        vallblmini,startmy,finmy,replace(startstr,' ',''),todayymd,...
        tzlabel,freqstr1,freqstr2,freqstr3,freqstr4);
    end
    fignameb=figdisp(figname3,[],[],1,[],'epstopdf');
    pause(0.25)
    if ~strcmpi(savedir,pwd)
      [status,cmdout]=system(sprintf('mv %s %s',fignameb,savedir));
      figname3=fullfile(savedir,figname3);
      pause(0.25)
    end
    % Convert to PNG
    fignamepng=strcat(figname3(1:length(figname3)-3),'png');
    [status,cmdout]=system(sprintf('convert -density 250 %s %s',...
      figname3,fignamepng));
    pause(0.25)
  end
end

