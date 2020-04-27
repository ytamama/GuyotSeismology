function avgdispdatahr(yyyy,mm,dd)
%
%Consolidates ground displacement data recorded by the seismometer
%in Guyot Hall, Princeton University, over a month, to output a .csv 
%file containing hourly averages of the absolute value (magnitude) of 
%displacement
%
%INPUTS
%yyyy - year of seismic data
%mm - month of seismic data (e.g. 2)
%dd - range of days for which we want .mat files (e.g. 1:5)
%
%OUTPUT
%a .csv file containing the average magnitude of displacement of each
%hourly .mat file we process
%
%last edited: April 27, 2020 by Yuri Tamama


%parameters
HH=0:23;
MM=00;
SS=00;
numdays=length(dd);
numhrs=length(HH);

%Initialize the arrays that will then contain the averaged, hourly values
%of the absolute value of ground displacement
%If data for a particular hour is missing, then the value corresponding 
%to that hour in the displacement arrays will equal -1, giving us an 
%indicator when cleaning up our data arrays!
totalpoints=numdays*numhrs;
timevec=cell(totalpoints,1);
sx_all=ones(totalpoints,1)*-1;
sy_all=ones(totalpoints,1)*-1;
sz_all=ones(totalpoints,1)*-1;


%iterate through selected days
for j = 1:length(dd)      
    
    %full level directory where data for each day is stored
    filedir = fullfile(getenv('MC'),datestr(...
        datenum(yyyy,mm,dd(j)),'yyyy/mm/dd'));
    
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
        
        if j > 1
            timevec{(j-1)*numhrs + h}=sprintf('%d-%d-%d %d:%d:%d',...
                yyyy,mm,dd(j),HH(h),MM,SS);
        else
            timevec{h}=sprintf('%d-%d-%d %d:%d:%d',yyyy,mm,dd(j),...
                HH(h),MM,SS);
        end
        
        %load file if it exists
        alpha=exist(matfile,'file');
        if alpha==2
            load(matfile);
            
            %compute mean absolute value (magnitude) of ground 
            %displacement for that hour and add
            %we are interested in knowing if the ground moved 
            %and by how much, on average... 
            if j > 1
                sx_all((j-1)*numhrs + h)=mean(abs(sx));
                sy_all((j-1)*numhrs + h)=mean(abs(sy));
                sz_all((j-1)*numhrs + h)=mean(abs(sz));
            else
                sx_all(h)=mean(abs(sx));
                sy_all(h)=mean(abs(sy));
                sz_all(h)=mean(abs(sz));                
            end
        end    
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Once I have consolidated *ALL* data for the selected range

%1) Clean it up! If displacement data do not exist for a particular
%hour, then the value we would see in the averaged displacement arrays
%corresponding to that hour would equal -1. Let's take those values out!
isminus=(sx_all == -1);
isminus=sum(isminus);  %number of times whose disp. = -1
timevec_new={};

for s = 1:totalpoints
    if(sx_all(s) ~= -1)  %if displacement data exists
        timevec_new{end+1}=timevec{s};
    end
end
sx_all(sx_all==-1)=[];
sy_all(sy_all==-1)=[];
sz_all(sz_all==-1)=[];


%2) Convert timevec from string to datetime format
timevec_new=transpose(timevec_new);
timevec_new=datetime(timevec_new,'InputFormat','yyyy-MM-dd HH:mm:ss');

%2) Save the data
%by now I should have 4 vectors:
%1 for average hourly magnitudes of ground motion in the x direction
%1 for y
%1 for z
%and 1 datetime vector, whose elements correspond to the time of each
%hourly ground motion 
%e.g.) 00:00:00 GMT = avg. motion from 00:00:00 - 00:59:59 GMT

%Consolidate vectors into a table
dtable = table(timevec_new,sx_all,sy_all,sz_all);
dtable.Properties.VariableNames = {'Date' 'Avg_Disp_Magnitude_X'...
    'Avg_Disp_Magnitude_Y' 'Avg_Disp_Magnitude_Z'};

%save the contents of the table into a .csv file
if numdays > 1
    filename=sprintf('%d_%d_%dto%ddispdatahourly.csv',yyyy,mm,dd(1),dd(numdays));
else
    filename=sprintf('%d_%d_%ddispdatahourly.csv',yyyy,mm,dd);
end

yeardir=strcat(num2str(yyyy),'longterm');
savefile=fullfile(getenv('MC'),num2str(yyyy),yeardir,filename);
writetable(dtable,savefile);


end