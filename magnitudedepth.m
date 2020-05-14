function magnitudedepth(filenames, years, plottype)
% 
% For an IRIS catalog of earthquakes in (a) given year(s), makes one of
% two plot types to compare earthquake magnitude and depth:
% 1) Creates and saves a scatterplot of earthquake magnitude vs. depth
% 2) Divides the earthquakes into categories based on depth: shallow 
% (0 km-70 km), intermediate (70 km-300 km), and very deep (300+ km).
% The program then creates and saves side-by-side boxplots of earthquake 
% magnitude for each category
% 
% Inputs
% filenames - Cell aray containing the names of the file(s) listing 
% the earthquakes recorded in the IRIS data base; 1 file per year
% years - An array of year(s) listed in ascending order, 
% corresponding to the files in filenames
% The years considered will be any year from 2017-2019, any pair of years
% in that range, or all three years
% plottype - 1 for making 1 scatterplot per year; 2 for making one
% scatterplot displaying the data for all years, color-coded; 
% 3 for making boxplots
%
% Output
% The plot selected by plottype
% 
% Last Modified by Yuri Tamama, 05/13/2020
% 
% References: 
% Earthquake Depth categories from "The Nature of Deep-Focus
% Earthquakes" by Cliff Frohlich (1989)
% Earthquake catalog information from IRIS's fdsnws-event service
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Iteratively load data from each file from the
% applicable directory
numfiles=length(filenames);
for i = 1:numfiles
    
  % load the file
  yearstr=num2str(years(i));
  filename=fullfile(getenv(),filenames{i});
  data=load(filename);
  depths=data(:,5);
  magnitudes=data(:,6);
    
  % Which plot(s) do we want?
  % 1 scatterplot per year
  if plottype == 1
    % Plot!
    figure();
    plot(magnitudes,depths,'.');
    axes=gca;
    xvals=axes.XLim;
    si_y=[70 70];
    id_y=[300 300];
    si_line=line(xvals,si_y);
    si_line.LineStyle='--';
    id_line=line(xvals,id_y);
    id_line.LineStyle='-.';
    
    % Add legend, and labels
    axes.YDir='reverse';
    legend(yearstr,'shallow-int','int-deep','Location','best')
    ylabel('Depths (km)')
    xlabel('Magnitude')
    title(sprintf('Earthquake Depth vs. Magnitude in %s',yearstr))
        
    % Save plot
    savestr=strcat(yearstr,'magnitudevsdepth');
    savestr=strcat(savestr,'scatter');
    saveplot=fullfile(getenv(),savestr);
    print('-depsc',saveplot);  
      
  % Overlayed scatterplot   
  elseif plottype == 2
    % Plot!  
    if i == 1
      yearone=yearstr;  
      figure();
      plot(magnitudes,depths,'.');
      hold on
    else
      plot(magnitudes,depths,'.');   
    end
    
    % Add depth lines and legend; save plot
    if i == numfiles
      yearend=yearstr;    
      axes=gca;
      
      % Add depth lines
      xvals=axes.XLim;
      si_y=[70 70];
      id_y=[300 300];
      si_line=line(xvals,si_y);
      si_line.LineStyle='--';
      id_line=line(xvals,id_y);
      id_line.LineStyle='-.';
      
      % Orient axes
      axes.YDir='reverse';
      
      % Labels, title, legend
      ylabel('Depths (km)')
      xlabel('Magnitude')
      if numfiles == 1 
        title(sprintf('Earthquake Magnitude vs. Depth in %s',yearstr)) 
      else
        title(sprintf('Earthquake Magnitude vs. Depth in %s to %s',...
            yearone, yearend))
        if numfiles == 2
          legend(yearone,yearend,'shallow-int','int-deep',...
              'Location','best')  
        else
          legend(yearone,num2str(years(2)),yearend,'shallow-int',...
              'int-deep','Location','best')   
        end    
      end   
      hold off
      
    savestr='magnitudevsdepth';
    savestr=strcat(savestr,sprintf('%sto%s',yearone,yearend));
    saveplot=fullfile(getenv(),savestr);
    print('-depsc',saveplot); 
      
    end    
      
  % Categorical boxplots     
  else
    % Divide depth data into categories!
    numpoints=length(depths);
    depth_cat=cell(numpoints,1);    
    for j = 1:numpoints
      if depths(j) < 70
        depth_cat{j}='Shallow';
      elseif depths(j) < 300
        depth_cat{j}='Intermediate';
      else
        depth_cat{j}='Deep';
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
    savestr=strcat(yearstr,'magnitudevsdepth');
    savestr=strcat(savestr,'boxplot');
    saveplot=fullfile(getenv(),savestr);
    print('-depsc',saveplot); 
    
    % Return mininum, median, and maximum in each depth range
    smin=min(magnitudes(strcmp('Shallow',depth_cat)));
    smed=median(magnitudes(strcmp('Shallow',depth_cat)));
    smax=max(magnitudes(strcmp('Shallow',depth_cat)));
    intmin=min(magnitudes(strcmp('Intermediate',depth_cat)));
    intmed=median(magnitudes(strcmp('Intermediate',depth_cat)));
    intmax=max(magnitudes(strcmp('Intermediate',depth_cat)));
    dmin=min(magnitudes(strcmp('Deep',depth_cat)));
    dmed=median(magnitudes(strcmp('Deep',depth_cat)));
    dmax=max(magnitudes(strcmp('Deep',depth_cat)));
    
    disp(sprintf(...
        '%s shallow earthquake min, med, max magnitudes: %d, %d, %d',...
        yearstr, smin, smed, smax));
    disp(sprintf(...
      '%s intermediate earthquake min, med, max magnitudes: %d, %d, %d',...
      yearstr, intmin, intmed, intmax));
    disp(sprintf(...
        '%s deep earthquake min, med, max magnitudes: %d, %d, %d',...
        yearstr, dmin, dmed, dmax));
    
  end     

    
end    


end