function avgdispdataplot(filename, yyyy, mm, type)
%
%Program to load and plot a time-series of the absolute value of 
%ground displacement data, contained in the .csv files created in 
%avgdispdatahr.m or avgdispdatadaily.m
%
%INPUTS
%filename - name(s) of .csv file created in avgdispdata.m, inputted as 
%string(s)in a cell array (e.g. {'filename1.csv'; 'filename2.csv'}, 
%{'filename.csv'}); assume each file resides in the same directory 
%and that each file contains data for only one month
%yyyy - year of data
%mm - month(s) of data (e.g. 2:3, 2)
%type - 1 if plotting hourly data; 2 if daily data
%
%OUTPUT
%time series plot of the data
%
%last edited April 27, 2020 by Yuri Tamama

%load the first (or only) .csv
numfiles = length(filename);
yeardir=strcat(num2str(yyyy),'longterm');
getfile=fullfile(getenv('MC'),num2str(yyyy),yeardir,filename{1});

avgdata = readtable(getfile);
date=avgdata.(1);
xdisp=avgdata.(2);
ydisp=avgdata.(3);
zdisp=avgdata.(4);
numpoints=zeros(numfiles,1);  %contain number of data points in each file
numpoints(1)=length(date);

%load more .csv's if applicable
if numfiles > 1
    for f = 2:numfiles
        newfile=fullfile(getenv('MC'),num2str(yyyy),yeardir,filename{f});
        
        %load csv
        newdata = readtable(newfile);  
        
        %append data
        date=vertcat(date, newdata.(1));
        xdisp=vertcat(xdisp, newdata.(2));
        ydisp=vertcat(ydisp, newdata.(3));
        zdisp=vertcat(zdisp, newdata.(4));
        
        %add to number of points array
        numpoints(f)=length(newdata.(1));
    end
end


%Calculate and the average of the average displacements in the csv
%files, for each month, to plot alongside the data
numpointstotal=sum(numpoints);
avgxdisp=ones(numpointstotal,1);
avgydisp=ones(numpointstotal,1);
avgzdisp=ones(numpointstotal,1);

if numfiles > 1   %more than 1 month to consider
    for n = 1:numfiles
        if n == 1   %1st file
            numpointshere=numpoints(1);
            avgxdisp(1:numpointshere)=mean(xdisp(1:numpointshere));
            avgydisp(1:numpointshere)=mean(ydisp(1:numpointshere));
            avgzdisp(1:numpointshere)=mean(zdisp(1:numpointshere));
        elseif n == numfiles   %last file
            uptolast=sum(numpoints(1:n-1));
            avgxdisp(uptolast+1:numpointstotal)=...
                mean(xdisp(uptolast+1:numpointstotal));
            avgydisp(uptolast+1:numpointstotal)=...
                mean(ydisp(uptolast+1:numpointstotal));
            avgzdisp(uptolast+1:numpointstotal)=...
                mean(zdisp(uptolast+1:numpointstotal)); 
        else  %any file in between
            pointsbefore=sum(numpoints(1:n-1));
            numpointshere=numpoints(n);
            avgxdisp(pointsbefore+1:pointsbefore+numpointshere)=...
                mean(xdisp(pointsbefore+1:pointsbefore+numpointshere));
            avgydisp(pointsbefore+1:pointsbefore+numpointshere)=...
                mean(ydisp(pointsbefore+1:pointsbefore+numpointshere));
            avgzdisp(pointsbefore+1:pointsbefore+numpointshere)=...
                mean(zdisp(pointsbefore+1:pointsbefore+numpointshere));    
        end
    end
else   %only 1 file (month) to consider
    avgxdisp(:) = mean(xdisp);
    avgydisp(:) = mean(ydisp);
    avgzdisp(:) = mean(zdisp);
end


%Plot the data!
%Figure out plot titles
monthnames={'Jan';'Feb';'Mar';'Apr';'May';'June';'July';'Aug';'Sept';...
    'Oct';'Nov';'Dec'};
if numfiles > 1
    monthstr=sprintf('%s-%s',monthnames{mm(1)},monthnames{mm(numfiles)});
    if type == 1  %Hourly data
        titlestr = sprintf(...
            'Avg. Hr. Magnitude of Displacement in %s/%d',monthstr,yyyy);
    else  %Daily data
        titlestr = sprintf(...
            'Avg. Daily Magnitude of Displacement in %s/%d',monthstr,yyyy);
    end
else
    monthstr=monthnames{mm};
    if type == 1
        titlestr = sprintf(...
            'Avg. Hr. Magnitude of Displacement in %s/%d',monthstr,yyyy);
    else
        titlestr = sprintf(...
            'Avg. Daily Magnitude of Displacement in %s/%d',monthstr,yyyy);
    end
end


figure(1)
subplot(3,1,1)  %x component
if type == 1   %plot hourly data differently, as it has more data points
    plot(date, xdisp,'-b')
    hold on
    plot(date, avgxdisp,'-r')
    legend('Hourly Avg.','Monthly Avg.','Location','best');
else
    plot(date, xdisp,'-ob')
    hold on
    plot(date, avgxdisp,'-r')
    legend('Daily Avg.','Monthly Avg.','Location','best');
end
title({titlestr;"Recorded at Guyot Hall at Princeton University"})
ylabel('X (nm)')
hold off
subplot(3,1,2)  %y component
if type == 1  
    plot(date, ydisp,'-b')
    hold on
    plot(date, avgydisp,'-r')
else
    plot(date, ydisp,'-ob')
    hold on
    plot(date, avgydisp,'-r')
end
ylabel('Y (nm)')
subplot(3,1,3)  %z component
if type == 1  
    plot(date, zdisp,'-b')
    hold on
    plot(date, avgzdisp,'-r')
else
    plot(date, zdisp,'-ob')
    hold on
    plot(date, avgzdisp,'-r')
end
ylabel('Z (nm)')
xlabel('Time (GMT)')

%save file
if numfiles > 1
    if type == 1
        savename=sprintf('%d_months%dto%davgdisphourly',yyyy,...
            mm(1),mm(numfiles));
    else
        savename=sprintf('%d_months%dto%davgdispdaily',yyyy,...
            mm(1),mm(numfiles));
    end
else
    if type == 1
        savename=sprintf('%d_month%davgdisphourly',yyyy,mm);
    else
        savename=sprintf('%d_month%davgdispdaily',yyyy,mm);
    end
end

savefile=fullfile(getenv('MC'),num2str(yyyy),yeardir,savename);
print('-depsc',savefile);  
print('-djpeg',savefile);


end
