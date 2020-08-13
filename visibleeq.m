function figurehdl=visibleeq(csvfile,measval,frequency,magrange,...
  saveplot,savedir,customtitle,customfigname)
%
% Function to plot a magnitude vs. epicentral scatterplot of earthquakes 
% catalogued by IRIS, each color-coded to indicate whether or not 
% the Meridian Compact seismometer at Guyot Hall, Princeton University
% can detect it. 
% 
% INPUTS
% csvfile : A CSV file containing the IRIS Event ID, magnitude, and 
%           distance of each earthquake, as well as whether or not we 
%           can see that earthquake on the Guyot Hall seismometer.
% measval : What is the seismometer measuring?
%           0 - Displacement (default)
%           1 - Velocity
%           2 - Acceleration
% frequency : To what frequency were the seismometer's data filtered?
%             Default: [0.01 0.02 10.0 20.0] Hz
% magrange : If plotting for a particular magnitude range, specify it!
%            Example) [7 10] for magnitudes above 7
%            Example) 6 for magnitude 6
%            Default: [], for plotting all magnitudes
% 
%            Note: The magnitudes are inclusive on both ends!
% saveplot : Do we wish to save our plot?
%            0 - No (default)
%            1 - Yes
% savedir : Where do we wish to save our plot? 
%           Default: Your directory for EPS files. Specify where!
% customtitle : A custom plot title, if requested
% customfigname : A custom name to save your figure, if requested
% 
% OUTPUT
% figurehdl : The figure handle of the plot generated
%
% References: 
% Uses defval.m in csdms-contrib/slepian_alpha 
%
% Use of colormap, including how to adjust for the number of colors in 
% the colormap, from MATLAB help forums
%
% Last Modified by Yuri Tamama, 08/03/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specify directory to get data - insert your own!
datadir=getenv('');

% Set default values
defval('measval',0);
defval('frequency',[0.01 0.02 10.0 20.0]);
defval('magrange',[]);
defval('saveplot',0);
defval('savedir','');

% Open the CSV file
vistbl=readtable(csvfile,'Delimiter',',','Format','%s%s%d%f%f');
evtids=vistbl.irisevtid;
if measval==0
  eqvisible=vistbl.Displacement;
elseif measval==1
  eqvisible=vistbl.Velocity;
else
  eqvisible=vistbl.Acceleration;
end

% Open the earthquakes table
file17=fullfile(datadir,'eq_2017');
file18=fullfile(datadir,'eq_2018');
file19=fullfile(datadir,'eq_2019');
data17=readtable(file17,'Format','%d%s%f%f%f%f%f%f%f');
data18=readtable(file18,'Format','%d%s%f%f%f%f%f%f%f');
data19=readtable(file19,'Format','%d%s%f%f%f%f%f%f%f');
alldata=vertcat(data17,data18);
alldata=vertcat(alldata,data19);

% Create a magnitude vs. distance earthquake visibility plot
figurehdl=figure();
% Set up a color bar for depth
cmap=colormap(jet(14));
cbar=colorbar;
cbar.Direction='reverse';
cbar.TicksMode='manual';
cbar.Ticks=[0:1/14:1];
cbar.TickLabelsMode='manual';
cbar.TickLabels={'0';'50';'100';'150';'200';'250';'300';'350';'400';...
'450';'500';'550';'600';'650';'700'};
cbar.Label.String='Depth (km)';
cbar.Location='eastoutside';
cbar.Label.Rotation=270;
cbar.Label.Position=(cbar.Label.Position).*[5/4 1 1];
% Plot each point!
hold on
% Counter variables to set up the legend later
firstfilled=0;
firstunfilled=0;
filledfirst=0;
% Note minimum and maximum magnitude
minmag=10;
maxmag=-5;
% How many are visible, and how many are not?
viscount=0;
notviscount=0;
for i=1:length(eqvisible)
  evtid=evtids(i);
  evtid=str2num(evtid{1});
  rowdata=alldata(alldata.Var1==evtid,:);
  depth=rowdata.Var5;  
  magnitude=rowdata.Var6;
  if magnitude<minmag
    minmag=magnitude;
  end
  if magnitude>maxmag
    maxmag=magnitude;
  end
  distdeg=rowdata.Var7;
  % Check that the magnitudes are correct
  if ~isempty(magrange)
    if length(magrange)==1
      if magnitude~=magrange
        fprintf('Check the magnitudes are correct for Event ID %d',...
          evtid)
        return
      end
    else
      if magnitude<magrange(1) || magnitude>magrange(2)
        fprintf('Check the magnitudes are correct for Event ID %d',...
          evtid)
        return
      end
    end
  end
  % Adjust magnitude to account for plot scale
  plotmag=(magnitude+2)*15;
  % Plot!
  plotpoint=plot(distdeg,plotmag,'o');
  plotcolor=pscolorcode(depth,2); 
  plotpoint.LineWidth=1.5;
  plotpoint.MarkerEdgeColor=plotcolor;
  plotpoint.MarkerSize=8;
  if strcmpi(eqvisible(i),'y')
    viscount=viscount+1;
    plotpoint.MarkerFaceColor=plotcolor;
    plotpoint.MarkerEdgeColor=[0 0 0];
    if firstfilled==0
      plotpoint.HandleVisibility='on';
      firstfilled=1;
      if firstunfilled==0
        filledfirst=1;
      else
        filledfirst=0;
      end
    else
      plotpoint.HandleVisibility='off';
    end
  else
    notviscount=notviscount+1;
    if firstunfilled==0
      plotpoint.HandleVisibility='on';
      firstunfilled=1;
    else
      plotpoint.HandleVisibility='off';
    end
  end
end
%
xlim([-5 185])
ylim([0 180])
nowaxes=gca;
% Adjust vertical axes
nowaxes.YTickMode='manual';
nowaxes.YTick=0:7.5:180;
nowaxes.YTickLabelMode='manual';
nowaxes.YTickLabel={'-2';' ';'-1';' ';'0';' ';'1';' ';'2';' ';'3';' ';...
  '4';' ';'5';' ';'6';' ';'7';' ';'8';' ';'9';' ';'10'};
% Adjust horizontal axes
nowaxes.XTickMode='manual';
nowaxes.XTick=0:15:180;
nowaxes.XTickLabelMode='manual';
nowaxes.XTickLabel={'0';' ';'30';' ';'60';' ';'90';' ';'120';' ';'150';...
   ' ';'180'};
% Make the plot square
axis square
% Vertical limits, zoomed into what we plotted
plotrange=maxmag-minmag;
ymin=(minmag+2)*15-15*0.075*plotrange;
ymax=(maxmag+2)*15+15*0.15*plotrange;
ylim([ymin ymax])

% Add legend
if filledfirst==1
  plotlegend=legend('Visible','Not Visible','Location','northwest');
  plotlegend.FontSize=6.5;
else
  plotlegend=legend('Not Visible','Visible','Location','northwest');
  plotlegend.FontSize=6.5;
end

% Add axis labels and title
xlabel('Epicentral Distance (degrees)')
ylabel('Magnitude')
% Displacement, velocity, or acceleration?
if measval==0
  vallabel='Displacement';
  vallabelmini='disp';
elseif measval==1
  vallabel='Velocity';
  vallabelmini='vel';
else
  vallabel='Acceleration';
  vallabelmini='acc';
end
% What magnitudes?
if ~isempty(magrange)
  if length(magrange)>1
    if magrange(2)>8.2
      magtitle=strcat('M','\geq',sprintf('%g',magrange(1)));
      magstr=sprintf('%g+',magrange(1));
    elseif magrange(1)<-1.69
      magtitle=strcat('M','\leq',sprintf('%g',magrange(2)));
      magstr=sprintf('%g-',magrange(2));
    else
      magtitle=strcat(sprintf('%g',magrange(1)),'\leq','M',...
        '\leq',sprintf('%g',magrange(2)));
      magstr=sprintf('%gto%g',magrange(1),magrange(2));
    end
  else
    magtitle=sprintf('M=%g',magrange(1));
    magstr=num2str(magrange(1));
  end
  titlestr1=sprintf('Earthquake %s Signals Detected (%s)',...
    vallabel,magtitle);
else
  magstr='allM';
  titlestr1=sprintf('Earthquake %s Signals Detected',vallabel);
end
titlestr2='by the Meridian Compact PH1 0248 Seismometer';
titlestr3='Stationed at Guyot Hall, Princeton University';
% Frequency and period
freqstr1=sprintf('%g',frequency(1));
freqstr2=sprintf('%g',frequency(2));
freqstr3=sprintf('%g',frequency(3));
freqstr4=sprintf('%g',frequency(4)); 
pdstr1=sprintf('%.2f',1/frequency(1));
pdstr2=sprintf('%.2f',1/frequency(2));
pdstr3=sprintf('%.2f',1/frequency(3));
pdstr4=sprintf('%.2f',1/frequency(4));
freqtitle=['[',freqstr1,' {\color{magenta}',freqstr2,...
  ' \color{magenta}',freqstr3,'} ',freqstr4,'] Hz'];
pdtitle=['[',pdstr4,' {\color{magenta}',pdstr3,' \color{magenta}',...
  pdstr2,'} ',pdstr1,'] s'];
titlestr4=[freqtitle,'  ',pdtitle];
if ~isempty(customtitle)
  plottitle=title(customtitle);
else
  plottitle=title({titlestr1;titlestr2;titlestr3;titlestr4},...
    'interpreter','tex'); 
end
plottitle.FontSize=9;

% Add a label showing how many earthquakes were plotted, how many
% are visible, etc.
vistext=annotation('textbox',[0.57 0.735 0.1619 0.1198]);
vistext.String={sprintf('%d plotted',length(eqvisible)),...
    sprintf('%d visible',viscount),sprintf('%d not visible',notviscount)};
vistext.FontSize=8;
vistext.FitBoxToText='on';

% If saving your plot
if saveplot==1
  if ~isempty(customfigname)
    figname=customfigname;
  else
    figname=sprintf('visibleearthquakeschart.%s.%s.%s%s%s%s.eps',...
      vallabelmini,magstr,freqstr1,freqstr2,freqstr3,freqstr4);
  end
  figname2=figdisp(figname,[],[],1,[],'epstopdf');
  if ~isempty(savedir)
    [status,cmdout]=system(sprintf('mv %s %s',figname2,savedir));
    figname=fullfile(savedir,figname);
  else
    figname=figname2;
  end
end

