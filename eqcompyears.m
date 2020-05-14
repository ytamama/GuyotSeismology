function eqcompyears(filenames,parameter)
% Function that plots overlayed/side by side histograms of the
% distributions of a given parameter describing the earthquakes catalogued
% in the given files by IRIS, from 2017-2019
% 
% Inputs
% filenames : cell array containing the names of the files, which have the
% catalogued earthquake data
% Each file corresponds to one year's worth of data, so we will have 1 file
% for 2017, 1 for 2018, and 1 for 2019
% parameter : the parameter of which we want to plot the distributions
% 1 for depth; 2 for magnitude
% 
% Output(s)
% One figure displaying the histograms of the distributions of the given 
% parameter, with one histogram per year
% If plotting depths: another figure displaying the same results as the 
% first one, but zoomed in to only the first 150 km depth
% 
% Last Modified by Yuri Tamama, 05/10/2020
%
% Reference:
% Earthquake catalog information from IRIS's fdsnws-event service
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

years=[2017, 2018, 2019];
numyears=length(years);
if parameter == 1  % Depth
  % Prepare title and name to save plot
  titlestr=sprintf('Earthquake Depths in %d to %d',...
      years(1),years(numyears));  % title of histogram
  savestr=sprintf('%dto%d_depthhist',years(1),...
      years(numyears));  % for saving
  savestr2=strcat(savestr,'_to150km');

  % Plot the first figure
  for i = 1:numyears
    % Load data from applicable directory
    filename=fullfile(getenv(),filenames{i});
    data=load(filename);   
    var=data(:,5);   
    % New figure if this is the first histogram
    if i == 1
      figure();  
      hist=histogram(var);
      hist.NumBins=100;
      hist.FaceAlpha=0.35;
      hold on
    else
      hist=histogram(var);
      hist.NumBins=100;
      hist.FaceAlpha=0.35;
    end  
  end 
  legend('2017','2018','2019');
    
  % Title and save first histogram
  title(titlestr);
  saveplot=fullfile(getenv(),savestr);
  print('-depsc',saveplot);  
  
  % Create second figure
  for i = 1:numyears
    % Load data
    filename=fullfile(getenv(),filenames{i});
    data=load(filename);   
    var=data(:,5);   
    % New figure if this is the first histogram
    if i == 1
      figure();  
      hist=histogram(var);
      hist.NumBins=100;
      hist.FaceAlpha=0.35;
      hold on
    else
      hist=histogram(var);
      hist.NumBins=100;
      hist.FaceAlpha=0.35;
    end  
  end 
  xlim([0 150])   % Set x limits! 
  legend('2017','2018','2019');
  
  % Title and save
  title({titlestr;'First 150 km'});
  saveplot2=fullfile(getenv(),savestr2);
  print('-depsc',saveplot2); 

  
else   % Magnitude
  titlestr=sprintf('Earthquake Magnitudes in %d to %d',...
      years(1),years(numyears));      
  savestr=sprintf('%dto%d_magnitudehist',years(1),...
      years(numyears));   

  for i = 1:numyears
    % Load data
    filename=fullfile(getenv(),filenames{i});
    data=load(filename);   
    var=data(:,6);   
    % New figure if this is the first histogram
    if i == 1
      figure();  
      hist=histogram(var);
      hist.NumBins=75;
      hist.FaceAlpha=0.35;
      hold on
    else
      hist=histogram(var);
      hist.NumBins=75;
      hist.FaceAlpha=0.35;
    end  
  end 
  legend('2017','2018','2019');
  
  % Title and save first histogram
  title(titlestr);
  saveplot=fullfile(getenv(),savestr);
  print('-depsc',saveplot);

end    



end