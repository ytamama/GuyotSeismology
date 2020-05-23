function checkseisdata(yyyy,mm) 
%
% Program to comb through ground displacement data collected by the 
% seismometer at Guyot Hall for (a) given
% month(s) and check which hours and components are missing 
%
% INPUT:
% 
% yyyy: year - 2017, 2018, 2019, or 2020
% mm: month(s) 
%
% OUTPUT:
%
% Spreadsheets consisting of the time (yyyy/mm/dd HH:00:00 where 
% HH = hour) and component (X, Y, Z) of the files that are missing 
% (i.e. data have not been collected as miniseed files)
% 
%Last modified: April 17, 2020 by Yuri Tamama


%Set Parameters 
HH = 0:23;  %Hours of the data collected 
components = {'X','Y','Z'};  %components of the displacement data 
nummonths = length(mm);
numcomp = 3;
numhrs = 24;

%Set number of days
leap = isleap(yyyy,1);  %check if Leap Year (see Meeus repository)
%# days in each month
numdays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]; 
if nummonths > 1
    DD = zeros(nummonths,1);
    for m = 1:nummonths
        DD(m) = numdays(mm(m));
        if (leap == 1) && (mm(m) == 2)  %February and Leap Year
            DD(m) = DD(m) + 1;
        end
    end
else
    DD = numdays(mm);
    if (leap == 1) && (mm == 2)   %February and Leap Year
        DD = DD + 1;
    end
end

%Set how many total files we should have, if the seismometer successfully
%collected data in all 3 components during the given time period
totaldays = sum(DD);
totalfiles = totaldays*numhrs*numcomp; %# of days * # hours * # components


%Initialize arrays indicating which files are 'missing'
missing_comp = {};  %'X', 'Y', or 'Z'
missing_date = {};  %format: yyyy/mm/DD HH:00:00


%Iterate through the given time period
%Check if we have data files corresponding to each time and component

yearstr = sprintf('%d',yyyy);
%iterate through the months
for m = 1:nummonths
    month = mm(m);
    if month < 10
        monthstr = sprintf('0%d',month);
    else
        monthstr = sprintf('%d',month);
    end
    %iterate through days
    for d = 1:DD(m)
        day = d;
        if day < 10
            daystr = sprintf('0%d',day);
        else
            daystr = sprintf('%d',day);
        end
        
        %set full directory to look for files
        dir=getenv('MC0');
        searchdir = fullfile(dir,...
            datestr(datenum(yyyy,month,day),'yyyy/mm/dd'));
        
        %iterate through hours
        for h = 1:numhrs
            hour = HH(h);
            if hour < 10
                hourstr = sprintf('0%d',hour);
            else
                hourstr = sprintf('%d',hour);
            end
            %iterate through components
            for c = 1:numcomp
                component = components{c};  %pick component
                
                %structure name of the file and set full path to it
                %check for both possible file names
                filename=sprintf(...
                    'PP.S0001.00.HH%s_MC-PH1_0248_%s%s%s_%s0000.miniseed',...
                    component,yearstr,monthstr,daystr,hourstr);
                filename2=sprintf(...
                    'S0001.HH%s_MC-PH1_0248_%s%s%s_%s0000.miniseed',...
                    component,yearstr,monthstr,daystr,hourstr);
                filename=fullfile(searchdir,filename);
                filename2=fullfile(searchdir,filename2);
                
                %if the file does NOT exist 
                %add to the 'missing files=' arrays
                if (exist(filename) == 0) && (exist(filename2) == 0)
                    missing_comp{end+1} = component;
                    date = sprintf('%s-%s-%s %s:00:00',yearstr,...
                        monthstr,daystr,hourstr);
                    missing_date{end+1} = date;
                end
                
            end
        end
    end
end
missing_comp = transpose(missing_comp);
missing_date = transpose(missing_date); 
totalmissing = length(missing_date);


%By now we should have two arrays, whose contents tell
%which data files are 'missing', in other words, which times did
%the seismometer not collect data

%Now we should filter through those contents and see:
%For a given "missing time", are the data missing 1, 2, or all 3 
%displacement components?

unique_date = unique(missing_date);  %get unique dates
numunique = length(unique_date);
nummissing = zeros(numunique,1);
for u = 1:numunique
    testtime = unique_date{u};
    %check # of components missing
    isthere = strcmp(testtime,missing_date);  
    nummissing(u) = sum(isthere);
end

%how many dates have what # of components missing?
threecmp=sum(nummissing==3);
twocmp=sum(nummissing==2);
onecmp=sum(nummissing==1);

%divide missing date and component arrays based on # components missing
threecmp_date={};
threecmp_comp={};
twocmp_date={};
twocmp_comp={};
onecmp_date={};
onecmp_comp={};

%Iterate through all dates
for t = 1:totalmissing
    dateind = find(strcmp(missing_date{t},unique_date));
    numcomps = nummissing(dateind);
    
    if numcomps == 3
        threecmp_date{end+1} = missing_date{t};
        threecmp_comp{end+1} = missing_comp{t};
    elseif numcomps == 2
        twocmp_date{end+1} = missing_date{t};
        twocmp_comp{end+1} = missing_comp{t};
    else
        onecmp_date{end+1} = missing_date{t};
        onecmp_comp{end+1} = missing_comp{t};
    end
end


%Convert the date cell arrays to datetime
threecmp_date=datetime(threecmp_date,'InputFormat','yyyy-MM-dd HH:mm:ss');
twocmp_date=datetime(twocmp_date,'InputFormat','yyyy-MM-dd HH:mm:ss');
onecmp_date=datetime(onecmp_date,'InputFormat','yyyy-MM-dd HH:mm:ss');

%Transpose all arrays
threecmp_date = transpose(threecmp_date);
threecmp_comp = transpose(threecmp_comp);
twocmp_date = transpose(twocmp_date);
twocmp_comp = transpose(twocmp_comp);
onecmp_date = transpose(onecmp_date);
onecmp_comp = transpose(onecmp_comp);

%Let's save this information for future use
missing_table_three = table(threecmp_comp, threecmp_date);
missing_table_two = table(twocmp_comp, twocmp_date);
missing_table_one = table(onecmp_comp, onecmp_date);
missing_table_three.Properties.VariableNames = {'Component' 'Time'};
missing_table_two.Properties.VariableNames = {'Component' 'Time'};
missing_table_one.Properties.VariableNames = {'Component' 'Time'};

if nummonths > 1
    file_three = sprintf('3compmissing_%s_months%dto%d.csv',...
        yearstr,mm(1),mm(nummonths));
    file_two = sprintf('2compmissing_%s_months%dto%d.csv',...
        yearstr,mm(1),mm(nummonths));
    file_one = sprintf('1compmissing_%s_months%dto%d.csv',...
        yearstr,mm(1),mm(nummonths));
else
    file_three = sprintf('3compmissing_%s_month%d.csv',yearstr,mm);
    file_two = sprintf('2compmissing_%s_month%d.csv',yearstr,mm);
    file_one = sprintf('1compmissing_%s_month%d.csv',yearstr,mm);
end

%Save files
savefilethree=fullfile(getenv('HRS'),file_three);
savefiletwo=fullfile(getenv('HRS'),file_two);
savefileone=fullfile(getenv('HRS'),file_one);
writetable(missing_table_three,savefilethree, 'Delimiter', '\t');
writetable(missing_table_two,savefiletwo, 'Delimiter', '\t');
writetable(missing_table_one,savefileone, 'Delimiter', '\t');


