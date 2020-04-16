function avgdispdatadaily(yyyy,mm,dd)
%
%Consolidates ground displacement data recorded by the seismometer
%in Guyot Hall, Princeton University, over a given month, 
%and outputs a .csv file containing daily averages of the absolute 
%value (magnitude) of displacement
%
%INPUTS 
%yyyy - year of seismic data (e.g. 2020)
%mm - month of seismic data (e.g. 2)
%dd - range of days for which we want .mat files (e.g. 1:29)
%
%OUTPUT
%a .csv file containing average magnitude of displacement for each day
%of data we process
%
%last edited: April 16, 2020 by Yuri Tamama


%parameters
HH=0:23;
numdays=length(dd);
numhrs=length(HH);

%initialize the arrays that will then contain the averaged, daily values
%of the absolute value of ground displacement
timevec=cell(numdays,1);
sx_all=ones(numdays,1);
sy_all=ones(numdays,1);
sz_all=ones(numdays,1);


%iterate through selected days
for j = 1:length(dd)   
    
    %temporary arrays, to store displacement data corresponding to day j
    sx_temp=[];
    sy_temp=[];
    sz_temp=[];
    
    %full level directory where data for each day is stored
    filedir = fullfile(getenv('MC'),datestr(datenum(yyyy,mm,dd(j)),...
        'yyyy/mm/dd'));
    
    for h = 1:numhrs   %every hour of the day
        %load data for hour h, day j
        if HH(h) < 10
            if dd(j) < 10
                if mm < 10
                    matfile = fullfile(filedir,sprintf(...
                    'PP.S0001.00.HHA_MC-PH1_0248_20200%d0%d_0%d0000.mat',...
                    mm,dd(j),HH(h)));
                else %mm >= 10
                    matfile = fullfile(filedir,sprintf(...
                    'PP.S0001.00.HHA_MC-PH1_0248_2020%d0%d_0%d0000.mat',...
                    mm,dd(j),HH(h)));
                end
            else %dd(j) >= 10
                if mm < 10
                    matfile = fullfile(filedir,sprintf(...
                    'PP.S0001.00.HHA_MC-PH1_0248_20200%d%d_0%d0000.mat',...
                    mm,dd(j),HH(h)));
                else %mm >= 10
                    matfile = fullfile(filedir,sprintf(...
                    'PP.S0001.00.HHA_MC-PH1_0248_2020%d%d_0%d0000.mat',...
                    mm,dd(j),HH(h)));
                end
            end
        else     %HH(h) >= 10
            if dd(j) < 10
                if mm < 10
                   matfile = fullfile(filedir,sprintf(...
                   'PP.S0001.00.HHA_MC-PH1_0248_20200%d0%d_%d0000.mat',...
                   mm,dd(j),HH(h))); 
                else %mm >= 10
                   matfile = fullfile(filedir,sprintf(...
                   'PP.S0001.00.HHA_MC-PH1_0248_2020%d0%d_%d0000.mat',...
                   mm,dd(j),HH(h)));
                end
            else %dd(j) >= 10
                if mm < 10
                    matfile = fullfile(filedir,sprintf(...
                    'PP.S0001.00.HHA_MC-PH1_0248_20200%d%d_%d0000.mat',...
                    mm,dd(j),HH(h)));
                else %mm >= 10
                    matfile = fullfile(filedir,sprintf(...
                    'PP.S0001.00.HHA_MC-PH1_0248_2020%d%d_%d0000.mat',...
                    mm,dd(j),HH(h)));
                end
            end
        end
        
        %load file if it exists
        alpha=exist(matfile,'file');
        if alpha==2
            load(matfile);
            
            %append displacement data points to the temporary daily arrays
            %make sure I can vertically concatenate
            dimx = size(sx);
            dimy = size(sy);
            dimz = size(sz);
            if dimx(2) ~= 1
                sx = transpose(sx);
            end
            if dimy(2) ~= 1
                sy = transpose(sy);
            end
            if dimz(2) ~= 1
                sz = transpose(sz);
            end
                
            sx_temp=vertcat(sx_temp, sx);
            sy_temp=vertcat(sy_temp, sy);
            sz_temp=vertcat(sz_temp, sz);  
        end
        
    end
    %compute daily averages
    timevec{j}=sprintf('%d-%d-%d',yyyy,mm,dd(j));
    sx_all(j)=mean(abs(sx_temp));
    sy_all(j)=mean(abs(sy_temp));
    sz_all(j)=mean(abs(sz_temp));
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Once I have consolidated *ALL* of the data for the selected range

%1) Clean it up! There could be days where data was not collected at all...
%This would result in 'NaN' entries in my averaged displacement arrays, so
%let's get rid of those

%Figure out which indices of my displacement arrays do NOT have 'NaN's
notnandisp = ~isnan(sx_all);
numvalid=sum(notnandisp);
notnanind=transpose(1:numdays);
notnanind=notnanind(notnandisp == 1);  %indices without 'NaN' 

%Create new arrays with only the displacement and time of days
timevecnew=cell(numvalid,1);
for i = 1:numvalid
    timevecnew{i}=timevec{notnanind(i)};
end
sx_all=sx_all(notnandisp == 1);
sy_all=sy_all(notnandisp == 1);
sz_all=sz_all(notnandisp == 1);


%2) Convert timevec from string to datetime format
timevecnew=datetime(timevecnew,'InputFormat','yyyy-MM-dd');

%3) Save the data
%by now I should have 4 vectors:
%1 for average hourly magnitudes of ground motion in the x direction
%1 for y
%1 for z
%and 1 datetime vector, whose elements correspond to the time of each
%hourly ground motion 
%e.g.) 00:00:00 GMT = avg. motion from 00:00:00 - 00:59:59 GMT

%Consolidate vectors into a table
dtable = table(timevecnew,sx_all,sy_all,sz_all);
dtable.Properties.VariableNames = {'Date' 'Avg_Disp_Magnitude_X'...
    'Avg_Disp_Magnitude_Y' 'Avg_Disp_Magnitude_Z'};

%save the contents of the table into a csv file
if numdays > 1
    filename=sprintf('%d_%d_%dto%ddispdatadaily.csv',yyyy,...
        mm,dd(1),dd(numdays));
else
    filename=sprintf('%d_%d_%ddispdatadaily.csv',yyyy,mm,dd);
end
savefile=fullfile(getenv('MT'),filename);
writetable(dtable,savefile);


end







