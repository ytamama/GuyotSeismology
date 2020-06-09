function mcsummary(filename, year, parameter, plotting)
%
% Returns the summary statistics and histograms, if desired, of given 
% parameter among the earthquakes present in the IRIS database for a 
% given year, the times for which we have data in our Meridian Compact 
% S0001 seismometer at Guyot Hall, Princeton University
%
% Inputs
% filename - File listing the earthquakes catalogued in the IRIS data base
% for a given year 
% year - The year corresponding to filename
% parameter - 1 for depth (km), 2 for magnitude, 3 for distance to Guyot 
% (degrees)
% plotting - 1 for yes, 0 for no
% 
% Output(s)
% A table, saved as a .csv file, with the summary statistics of the 
% chosen parameter
% If chosen, histograms showing the distribution of the chosen parameter 
% among the earthquakes recorded in the year
% 
% Last Modified: 06/09/2020 by Yuri Tamama
% 
% Reference:
% Earthquake catalog information from IRIS's fdsnws-event service
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load data
% Insert applicable directory!
yearstr=num2str(year);
filename=fullfile(getenv(),filename);
data=load(filename);
if parameter == 1      %Depth
    plotvar=data(:,5);
    savestr=strcat(yearstr,'depth');  %for saving
    if plotting == 1
        varstr='Depth (km)';  
        titlestr=sprintf('Earthquake Depths in %s',yearstr);
    end
elseif parameter == 2  %Magnitude
    plotvar=data(:,6);
    savestr=strcat(yearstr,'magnitude');
    if plotting == 1
        varstr='Magnitude';
        titlestr=sprintf('Earthquake Magnitudes in %s',yearstr);
    end
else   %Distance to Guyot Hall
    plotvar=data(:,7);
    savestr=strcat(yearstr,'distance');
    if plotting == 1
        varstr='Distance (Degrees)';
        titlestr=sprintf('Earthquake Distances to Guyot Hall in %s',... 
            yearstr);
    end
end

% Find statistical values
% Dataset with outliers
minvar=min(plotvar);
maxvar=max(plotvar);
meanvar=round(mean(plotvar),2);
medvar=median(plotvar);
stdev=round(std(plotvar),2);
% Data without outliers
notoutlier=plotvar(~isoutlier(plotvar));
min_no=min(notoutlier);
max_no=max(notoutlier);
mean_no=round(mean(notoutlier),2);
med_no=median(notoutlier);
sd_no=round(std(notoutlier),2);

areoutliers={'Yes';'No'};
mins=vertcat(minvar, min_no);
maxes=vertcat(maxvar, max_no);
means=vertcat(meanvar, mean_no);
medians=vertcat(medvar, med_no);
sdevs=vertcat(stdev, sd_no);


% Organize summary statistics into a table and save
stattable=table(areoutliers,mins,maxes,means,medians,sdevs);
stattable.Properties.VariableNames = {'Outliers' 'Minimum' 'Maximum'...
    'Mean' 'Median' 'StandardDeviation'};
savetable=strcat(savestr,'stats.csv');
savetable=fullfile(getenv(),savetable);
writetable(stattable,savetable);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if plotting == 1
    % Plot histograms if desired
    % Plot histogram including outliers
    figure();
    hist=histogram(plotvar);
    hist.NumBins=floor(length(plotvar)/10000)*10;
    if parameter == 2
        hist.NumBins=floor(length(plotvar)/10000)*2;
    end
    xlabel(varstr);
    ylabel('Frequency');
    title(titlestr);
    hold on
    minline=line([minvar, minvar], ylim, 'Color',...
        'r','LineStyle','--');
    maxline=line([maxvar, maxvar], ylim, 'Color',...
        'b','LineStyle','--');
    meanline=line([meanvar, meanvar], ylim,...
        'Color', 'g','LineStyle','--');
    medline=line([medvar, medvar], ylim,'Color', ...
        'y','LineStyle','--');
    hold off
    histlegend=legend('Distribution','Min','Max','Mean','Median',...
        'Location','best');

    % Save this histogram
    saveplot=strcat(savestr,'histogram');
    saveplot=fullfile(getenv(),saveplot);
    print('-depsc',saveplot);  


    % Plot histogram without any outliers, defined by MATLAB's isoutlier()
    % function as values that are more than 3 median absolute deviations 
    % away from the median
    figure();
    hist_no=histogram(notoutlier);
    hist_no.NumBins=floor(length(notoutlier)/10000)*10;
    if parameter == 2
        hist_no.NumBins=floor(length(notoutlier)/10000)*2;
    end
    xlabel(varstr);
    ylabel('Frequency');
    title({titlestr;'No Outliers'});
    hold on
    minline_no=line([min_no, min_no], ylim, 'LineWidth', 0.5, ...
        'Color', 'r','LineStyle','--');
    maxline_no=line([max_no, max_no], ylim, 'LineWidth', 0.5, ...
        'Color', 'b','LineStyle','--');
    meanline_no=line([mean_no, mean_no], ylim, 'LineWidth', 0.5, ...
        'Color','g','LineStyle','--');
    medline_no=line([med_no, med_no], ylim, 'LineWidth', 0.5, 'Color', ...
        'y','LineStyle','--');
    hold off
    legend_no=legend('Distribution','Min','Max','Mean','Median',...
        'Location','best');

    % Save this histogram into applicable directory
    saveplot_no=strcat(savestr,'histogram_nooutliers');
    saveplot_no=fullfile(getenv(),saveplot_no);
    print('-depsc',saveplot_no);  

end

end

