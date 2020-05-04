function magnitudedepth(filename, year)
% 
% For an IRIS catalog of earthquakes within a given year, divides the 
% earthquakes into categories based on depth: shallow (0 km-70 km),
% intermediate (70 km-300 km), and very deep (300+ km)
% The program then creates and saves side-by-side boxplots of earthquake 
% magnitude for each category
% 
% Inputs
% filename - File listing the earthquakes recorded in the IRIS data base
% for a given year
% year - The year corresponding to filename
%
% Output
% Boxplots showing the distributions of earthquake magnitudes across the
% three depth categories
% 
% Last Modified: May 4, 2020 by Yuri Tamama
% 
% References: 
% Earthquake Depth categories from "The Nature of Deep-Focus
% Earthquakes" by Cliff Frohlich (1989)
% Earthquake catalog information from IRIS's fdsnws-event service
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load data
yearstr=num2str(year);
% Insert directory where data are stored
filename=fullfile(getenv(''),filename);
data=load(filename);
depths=data(:,5);
magnitudes=data(:,6);


% Divide depth data into categories!
numpoints=length(depths);
depth_cat=cell(numpoints,1);

for i = 1:numpoints
    if depths(i) < 70
        depth_cat{i}='Shallow';
    elseif depths(i) < 300
        depth_cat{i}='Intermediate';
    else
        depth_cat{i}='Deep';
    end
end

datatable=table(depth_cat, magnitudes);
datatable.Properties.VariableNames = {'Depth' 'Magnitude'};

% Plot boxplots of the magnitude distributions!
figure()
boxplot(datatable.(2), datatable.(1))
xlabel('Depth')
ylabel('Magnitude')
title(sprintf('Earthquake Magnitude Distribution with Depth in %s',...
    yearstr))


% Save boxplot
% Insert directory where this will be stored
savestr=strcat(yearstr,'magnitudevsdepth');
saveplot=strcat(savestr,'boxplot');
saveplot=fullfile(getenv(''),saveplot);
print('-depsc',saveplot);  



end