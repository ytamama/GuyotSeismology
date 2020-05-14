function earthquakeqq(filename1, filename2, year1, year2, parameter) 
%
% Returns a quantile-quantile plot comparing the distributions of a given 
% parameter, recorded in two files
% The parameter is a characteristic about the earthquakes present in the 
% IRIS database
% Each file corresponds to a particular year's worth of earthquake data
% extracted from the IRIS data base
% 
% Inputs
% filename1, filename2 - The names of the files whose data we want to 
% compare. Each file corresponds to a different year
% year1, year2 - The years corresponding to the files
% parameter - The parameter whose distribution we want to compare 
% between the two datasets
% 1 for depth (km), 2 for magnitude, and 3 for distance to Guyot Hall 
% (degrees)
% 
% Output
% a qq plot, whose linearity tells us how similarly is the parameter 
% distributed between the two files/years
% 
% Last Modified by Yuri Tamama, 05/08/2020
% 
% Reference:
% Earthquake catalog information from IRIS's fdsnws-event service
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load the data from the two files
% Insert applicable directory!
yearstr1=num2str(year1);
yearstr2=num2str(year2);
filename1=fullfile(getenv(),filename1);
filename2=fullfile(getenv(),filename2);
data1=load(filename1);
data2=load(filename2);
if parameter == 1      %Depth
    var1=data1(:,5);
    var2=data2(:,5);
    savestr=strcat(yearstr1,yearstr2);
    savestr=strcat(savestr,'_depth');  %for saving 
    titlestr=sprintf('Earthquake Depths in %d to %d',year1,year2);
elseif parameter == 2  %Magnitude
    var1=data1(:,6);
    var2=data2(:,6);
    savestr=strcat(yearstr1,yearstr2);
    savestr=strcat(savestr,'magnitude');
    titlestr=sprintf('Earthquake Magnitudes in %d to %d',year1,year2);
else   %Distance to Guyot Hall
    var1=data1(:,7);
    var2=data2(:,7);
    savestr=strcat(yearstr1,yearstr2);
    savestr=strcat(savestr,'distance');
    titlestr=sprintf('Earthquake Distances to Guyot Hall in %d to %d',...
        year1,year2);
end


% Plot a qq plot of the data!
figure()
qqplot(var1,var2);
title(titlestr);
xlabel(sprintf('Quantiles in %d',year1));
ylabel(sprintf('Quantiles in %d',year2));

% Save the qq plot in applicable directory
saveplot=strcat(savestr,'_qqplot');
saveplot=fullfile(getenv(),saveplot);
print('-depsc',saveplot);  


end


