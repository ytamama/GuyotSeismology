function earthquakemap(filename,year,colorcode,maptype,manymaps)
% 
% Plots the earthquakes catalogued by IRIS for a given year (with catalog 
% information stored in filename) on a world map
% Color codes the earthquakes by magnitude or depth category
% 
% Inputs
% filename : name of file that stores IRIS catalog information
%            This file had been created using mcms2evt, in 
%            csdms-contrib/slepian_oscar
% year : year corresponding to the file
% colorcode : 1 to color code by magnitude; 2 by depth range
% maptype : plot earthquakes alongside 1, the outlines of continents, or 
% 2, the outlines of plate boundaries
% manymaps : plot individual maps for each of the magnitude/depth 
% categories -- 1 for yes, 2 for no 
% 
% Output
% A map with the locations of the earthquakes in filename on a world map
%
% Last Modified by Yuri Tamama, 11/04/2020
% 
% References
% I) Code and data to plot the continents and plate outlines on a world map
% from plotcont.m and plotplates.m, in csdms-contrib/slepian_alpha
% II) Earthquake depth ranges defined in The Nature of Deep Focus
% Earthquakes by Frohlich, 1989
% III) Earthquake magnitude ranges defined in Introduction to Seismology,
% 3rd Edition by Shearer, 2019 
% IV) Earthquake catalog information had been obtained using the
% facilities of IRIS Data Services, and specifically the IRIS Data 
% Management Center. IRIS Data Services are funded through the
% Seismological Facilities for the Advancement of Geoscience (SAGE) 
% Award of the National Science Foundation under Cooperative Support 
% Agreement EAR-1851048.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load data
yearstr=num2str(year);
yeardir=strcat(yearstr,'longterm');
filename=fullfile(getenv('MC0'),filename);
data=load(filename);
eqlat=data(:,3);
eqlon=data(:,4);
if colorcode == 1
  codevar=data(:,6);  %Magnitude
else
  codevar=data(:,5);  %Depth
end


% Prepare the latitudes and longitudes of the earthquakes so they are ready
% to plot
% Convert the longitudes from a -180 to 180 scale to a 0 to 360 scale
numpoints=length(eqlon);
for l=1:numpoints
  if eqlon(l) < 0
      eqlon(l)=eqlon(l)+360;
  end    
end

% Categorize the earthquakes!
category=cell(numpoints,1);
if colorcode == 1  % by magnitude
    plotstr='Magnitude';
    cat1='Small';
    exp1='Magnitude < 6';
    cat2='Medium';
    exp2='Magnitude [6,8]'; 
    cat3='Large';
    exp3='Magnitude > 8';
    for m = 1:numpoints
      if codevar(m) < 6
        category{m}='Small';
      elseif codevar(m) <= 8
        category{m}='Medium';
      else
        category{m}='Large';
      end
    end    
else % by depth
    plotstr='Depth';
    cat1='Shallow';
    exp1='Depth < 70 km';
    cat2='Intermediate';
    exp2='Depth [70,300) km';
    cat3='Deep';
    exp3='Depth >= 300 km';
    for d = 1:numpoints
      if codevar(d) < 70
        category{d}='Shallow';
      elseif codevar(d) < 300
        category{d}='Intermediate';
      else
        category{d}='Deep';
      end
    end    
end    

% Organize the earthquakes by their category
ind1=strcmp(category,cat1);
lat1=eqlat(ind1);
lon1=eqlon(ind1);
ind2=strcmp(category,cat2);
lat2=eqlat(ind2);
lon2=eqlon(ind2);
ind3=strcmp(category,cat3);
lat3=eqlat(ind3);
lon3=eqlon(ind3);


% Plot a blank world map using either plotcont.m or plotplates.m
% Use their default settings!
if maptype == 1
  mapstr='Continents';
else
  mapstr='Plates';
end    

if manymaps == 1      % Plot each category on a separate map
  for i = 1:3
     if maptype == 1
       plotcont();
     else
       plotplates();
     end
     hold on;
     
     % Plot each category! 
     if i == 1
       plot(lon1,lat1,'bo'); 
       title({sprintf('Earthquakes with %s %s in %s',cat1,plotstr,...
           yearstr);exp1});
       savestr=strcat(yearstr,sprintf('%s%s%smap',lower(cat1),...
         lower(plotstr),lower(mapstr)));
     elseif i == 2
       plot(lon2,lat2,'md');
       title({sprintf('Earthquakes with %s %s in %s',cat2,plotstr,...
           yearstr);exp2});
       savestr=strcat(yearstr,sprintf('%s%s%smap',lower(cat2),...
         lower(plotstr),lower(mapstr)));
     else
       plot(lon3,lat3,'r*');
       title({sprintf('Earthquakes with %s %s in %s',cat3,plotstr,...
           yearstr);exp3});
       savestr=strcat(yearstr,sprintf('%s%s%smap',lower(cat3),...
         lower(plotstr),lower(mapstr)));
     end
     
     % Save it!
     saveplot=fullfile(getenv('MC'),yearstr,yeardir,savestr);
     print('-depsc',saveplot); 
 
  end 
else  % Plot everything on only one map
  if maptype == 1
    plotcont();
  else
    plotplates();
  end
  hold on;

  % Plot the earthquakes on the world map
  plot(lon1,lat1,'bo');
  plot(lon2,lat2,'md');
  plot(lon3,lat3,'r*');
  legend(mapstr,cat1,cat2,cat3,'Location','bestoutside');
  title({'Distribution of Earthquakes';sprintf(...
      'Categorized by %s in %s',plotstr,yearstr)});
  
  % Save it!
  savestr=strcat(yearstr,sprintf('%s%smap',lower(plotstr),...
    lower(mapstr)));
  saveplot=fullfile(getenv('MC'),yearstr,yeardir,savestr);
  print('-depsc',saveplot); 
     
end

