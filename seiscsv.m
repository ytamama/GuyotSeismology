function [seistbls,seiscsvs]=seiscsv(csvfiles,timeinfo,avgmode,measval,...
  frequency,xyh,tzone,tzlabel,makeplots,saveplot,savedir)
% 
% Function that takes in CSV files, each containing 1 month of hourly
% averaged root mean squared (RMS) ground motion data, compiled in 
% from guyotrmsseishr.m. The function then averages these values using
% one of two methods, for the sake of comparisons between months or years
%
% If averaging by the first method, the function computes these averages:
%
% 1 - Mean RMS Ground motion
% 2 - Mean RMS Ground motion, averaged over the weekdays
% 3 - Mean RMS Ground motion, averaged over the weekends
% 4 - Mean RMS Ground motion, averaged over 00:00:00 - 05:59:59.99 local 
%     time [night]
% 5 - Mean RMS Ground motion, averaged over weekdays, 00:00:00 - 
%     05:59:59.99 local time [night]
% 6 - Mean RMS Ground motion, averaged over weekends, 00:00:00 - 
%     05:59:59.99 local time [night]
% 7 - Mean RMS Ground motion, averaged over 06:00:00 - 11:59:59.99 local 
%     time [morning]
% 8 - Mean RMS Ground motion, averaged over weekdays, 06:00:00 - 
%     11:59:59.99 local time [morning]
% 9 - Mean RMS Ground motion, averaged over weekends, 06:00:00 - 
%     11:59:59.99 local time [morning]
% 10 - Mean RMS Ground motion, averaged over 12:00:00 - 17:59:59.99 local 
%      time [afternoon]
% 11 - Mean RMS Ground motion, averaged over weekdays, 12:00:00 - 
%      17:59:59.99 local time [afternoon]
% 12 - Mean RMS Ground motion, averaged over weekends, 12:00:00 - 
%      17:59:59.99 local time [afternoon]
% 13 - Mean RMS Ground motion, averaged over 18:00:00 - 23:59:59.99 local 
%      time [afternoon]
% 14 - Mean RMS Ground motion, averaged over weekdays, 18:00:00 - 
%      23:59:59.99 local time [evenings]
% 15 - Mean RMS Ground motion, averaged over weekends, 18:00:00 - 
%      23:59:59.99 local time [evenings]
%
% If averaging by the second method, the function computes the average
% value of a particular "time-of-day" category of a particular weekday
% (e.g. Wednesday afternoons). 
%
% These values are computed for the Z (vertical) and H (Horizontal) 
% components
% 
% If at least 2 CSV files (or 2 months' worth of data) are entered, the 
% function also computes the percent change of the RMS ground motion of 
% all files entered after the first one, compared to the first file, 
% in the different categories over which the RMS values were averaged.
%
% INPUTS
%
% timeinfo : If entering multiple CSV files, the percent changes can be 
%            computed in 1 of 2 ways:
%            1 : We compare the RMS ground motion in one month to that of
%                the other months in the same year
%            2 : We compare the RMS ground motion in some months of a year
%                to those of the corresponding months in another year
%
%            Enter 1 or 2, for each option, or an empty vector if inputting
%            only 1 CSV file
%
% csvfiles : A cell array containing the names of 1 or more CSV files, from
%            which we will read the data and compute the mean RMS values.
%            Each CSV file should span an entire month (which can be
%            specified using guyorrmsseishr.m), and contain the times of 
%            the data in local time. 
%
%            If inputting under timeinfo = 1, input the CSV file of the 
%            "reference month" first, followed by those of the subsequent
%            months. 
% 
%            If inputting under timeinfo = 2, enter the names of the RMS 
%            hourly ground motion CSV by month! For example, when comparing
%            February-May of 2018-2019, input February 2018 and February
%            2019 first, then March 2018 and 2019, and so on... 
%
% avgmode : How should we compute the means?
%           0 : By using the categories specified above (i.e. weekday 
%               morning, weekend afternoon, etc.)
%           1 : By averaging every hour of every weekday over an entire
%               month
% measval : What are these CSV files measuring?
%           0 : Displacement (nm; Default)
%           1 : Velocity (nm/s)
%           2 : Acceleration (nm/s^2)
% frequency : Through what frequencies were the seismic data filtered? 
%             Enter as a four element vector!
% xyh : How should we generate the H (horizontal) component?
%       0 : Use the RMS H vector, generated in guyotrmsseishr.m
%           [Default]
%       1 : Combine the pre-existing X and Y RMS vectors
% tzone : The MATLAB specified time zone of the times in the CSV files
%         Example: 'America/New_York'
% tzlabel : The label characterizing the time zone of the times plotted
% makeplots : If inputting more than 1 CSV file, do we want to make 
%             graphics illustrating the percent changes?
%             0 : No
%             1 : Yes
% saveplots : If making graphics, do we wish to save them?
%             0 : No
%             1 : Yes
% savedir : If saving graphics, where do we wish to save them?
%           Enter nothing for the default, the current working directory
% 
% OUTPUTS
% seistbls : If 1 CSV file is entered:
%            Returns 1 table. The leftmost column tells us the name of CSV
%            file, given by its alias, and its component. The subsequent
%            columns tell us the mean RMS values for each of the 15
%            categories. 
% 
%            If at least 2 CSV files are entered:
%            Returns 2 tables. The first table is identical to the one
%            for the 1 csv file case. The second table tells us the
%            percent changes of each subsequent CSV file from the first
%
% seiscsvs : The names of the CSV file(s), containing the tabular data
% 
% References
% Uses defval.m, figdisp.m in csdms-contrib/slepian_alpha 
% These time-based categories are based off of those used in 
% Groos and Ritter (2009).
%
% See guyotrmsseishr.m, seiscsvplot.m
% 
% Last Modified by Yuri Tamama, 10/26/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Default values
defval('measval',0)
defval('xyh',0)
defval('savedir',pwd)

% Set up the vectors to store our data
csvlblsz=cell(length(csvfiles),1);
csvlblsh=cell(length(csvfiles),1);
if length(csvfiles)>1
  if timeinfo==1
    prclen=length(csvfiles)-1;
  else
    prclen=length(csvfiles)/2;
  end
  csvlblsprcz=cell(prclen,1);    
  csvlblsprch=cell(prclen,1);  
end
if avgmode==0
  % Z
  ovvecz=zeros(length(csvfiles),1);
  wdayvecz=zeros(length(csvfiles),1);
  wendvecz=zeros(length(csvfiles),1);
  nightovz=zeros(length(csvfiles),1);
  nightwdayz=zeros(length(csvfiles),1);
  nightwendz=zeros(length(csvfiles),1);
  morovz=zeros(length(csvfiles),1);
  morwdayz=zeros(length(csvfiles),1);
  morwendz=zeros(length(csvfiles),1);
  aftovz=zeros(length(csvfiles),1);
  aftwdayz=zeros(length(csvfiles),1);
  aftwendz=zeros(length(csvfiles),1);
  eveovz=zeros(length(csvfiles),1);
  evewdayz=zeros(length(csvfiles),1);
  evewendz=zeros(length(csvfiles),1);
  % 
  % H
  ovvech=zeros(length(csvfiles),1);
  wdayvech=zeros(length(csvfiles),1);
  wendvech=zeros(length(csvfiles),1);
  nightovh=zeros(length(csvfiles),1);
  nightwdayh=zeros(length(csvfiles),1);
  nightwendh=zeros(length(csvfiles),1);
  morovh=zeros(length(csvfiles),1);
  morwdayh=zeros(length(csvfiles),1);
  morwendh=zeros(length(csvfiles),1);
  aftovh=zeros(length(csvfiles),1);
  aftwdayh=zeros(length(csvfiles),1);
  aftwendh=zeros(length(csvfiles),1);
  eveovh=zeros(length(csvfiles),1);
  evewdayh=zeros(length(csvfiles),1);
  evewendh=zeros(length(csvfiles),1);
  % Vectors for percent changes if necessary
  if length(csvfiles)>1
    % Z
    ovprz=zeros((prclen),1);
    wdayprz=zeros((prclen),1);
    wendprz=zeros((prclen),1);
    novprz=zeros((prclen),1);
    nwdayprz=zeros((prclen),1);
    nwendprz=zeros((prclen),1);
    moovprz=zeros((prclen),1);
    mowdayprz=zeros((prclen),1);
    mowendprz=zeros((prclen),1);
    afovprz=zeros((prclen),1);
    afwdayprz=zeros((prclen),1);
    afwendprz=zeros((prclen),1);
    evovprz=zeros((prclen),1);
    evwdayprz=zeros((prclen),1);
    evwendprz=zeros((prclen),1);
    % 
    % H
    ovprh=zeros((prclen),1);
    wdayprh=zeros((prclen),1);
    wendprh=zeros((prclen),1);
    novprh=zeros((prclen),1);
    nwdayprh=zeros((prclen),1);
    nwendprh=zeros((prclen),1);
    moovprh=zeros((prclen),1);
    mowdayprh=zeros((prclen),1);
    mowendprh=zeros((prclen),1);
    afovprh=zeros((prclen),1);
    afwdayprh=zeros((prclen),1);
    afwendprh=zeros((prclen),1);
    evovprh=zeros((prclen),1);
    evwdayprh=zeros((prclen),1);
    evwendprh=zeros((prclen),1);
  end
else
  % Z
  monnightz=zeros(length(csvfiles),1);
  monmornz=zeros(length(csvfiles),1);
  monaftz=zeros(length(csvfiles),1);
  monevez=zeros(length(csvfiles),1);
  tuenightz=zeros(length(csvfiles),1);
  tuemornz=zeros(length(csvfiles),1);
  tueaftz=zeros(length(csvfiles),1);
  tueevez=zeros(length(csvfiles),1);
  wednightz=zeros(length(csvfiles),1);
  wedmornz=zeros(length(csvfiles),1);
  wedaftz=zeros(length(csvfiles),1);
  wedevez=zeros(length(csvfiles),1);
  thrnightz=zeros(length(csvfiles),1);
  thrmornz=zeros(length(csvfiles),1);
  thraftz=zeros(length(csvfiles),1);
  threvez=zeros(length(csvfiles),1);
  frinightz=zeros(length(csvfiles),1);
  frimornz=zeros(length(csvfiles),1);
  friaftz=zeros(length(csvfiles),1);
  frievez=zeros(length(csvfiles),1);
  satnightz=zeros(length(csvfiles),1);
  satmornz=zeros(length(csvfiles),1);
  sataftz=zeros(length(csvfiles),1);
  satevez=zeros(length(csvfiles),1);
  sunnightz=zeros(length(csvfiles),1);
  sunmornz=zeros(length(csvfiles),1);
  sunaftz=zeros(length(csvfiles),1);
  sunevez=zeros(length(csvfiles),1);
  % 
  % H
  monnighth=zeros(length(csvfiles),1);
  monmornh=zeros(length(csvfiles),1);
  monafth=zeros(length(csvfiles),1);
  moneveh=zeros(length(csvfiles),1);
  tuenighth=zeros(length(csvfiles),1);
  tuemornh=zeros(length(csvfiles),1);
  tueafth=zeros(length(csvfiles),1);
  tueeveh=zeros(length(csvfiles),1);
  wednighth=zeros(length(csvfiles),1);
  wedmornh=zeros(length(csvfiles),1);
  wedafth=zeros(length(csvfiles),1);
  wedeveh=zeros(length(csvfiles),1);
  thrnighth=zeros(length(csvfiles),1);
  thrmornh=zeros(length(csvfiles),1);
  thrafth=zeros(length(csvfiles),1);
  threveh=zeros(length(csvfiles),1);
  frinighth=zeros(length(csvfiles),1);
  frimornh=zeros(length(csvfiles),1);
  friafth=zeros(length(csvfiles),1);
  frieveh=zeros(length(csvfiles),1);
  satnighth=zeros(length(csvfiles),1);
  satmornh=zeros(length(csvfiles),1);
  satafth=zeros(length(csvfiles),1);
  sateveh=zeros(length(csvfiles),1);
  sunnighth=zeros(length(csvfiles),1);
  sunmornh=zeros(length(csvfiles),1);
  sunafth=zeros(length(csvfiles),1);
  suneveh=zeros(length(csvfiles),1);
  
  % Vectors for percent change, if necessary
  if length(csvfiles)>1
    % Z
    moniprcz=zeros((prclen),1);
    momoprcz=zeros((prclen),1);
    moafprcz=zeros((prclen),1);
    moevprcz=zeros((prclen),1);
    tuniprcz=zeros((prclen),1);
    tumoprcz=zeros((prclen),1);
    tuafprcz=zeros((prclen),1);
    tuevprcz=zeros((prclen),1);
    weniprcz=zeros((prclen),1);
    wemoprcz=zeros((prclen),1);
    weafprcz=zeros((prclen),1);
    weevprcz=zeros((prclen),1);
    thniprcz=zeros((prclen),1);
    thmoprcz=zeros((prclen),1);
    thafprcz=zeros((prclen),1);
    thevprcz=zeros((prclen),1);
    frniprcz=zeros((prclen),1);
    frmoprcz=zeros((prclen),1);
    frafprcz=zeros((prclen),1);
    frevprcz=zeros((prclen),1);
    saniprcz=zeros((prclen),1);
    samoprcz=zeros((prclen),1);
    saafprcz=zeros((prclen),1);
    saevprcz=zeros((prclen),1);
    suniprcz=zeros((prclen),1);
    sumoprcz=zeros((prclen),1);
    suafprcz=zeros((prclen),1);
    suevprcz=zeros((prclen),1);
    % 
    % H
    moniprch=zeros((prclen),1);
    momoprch=zeros((prclen),1);
    moafprch=zeros((prclen),1);
    moevprch=zeros((prclen),1);
    tuniprch=zeros((prclen),1);
    tumoprch=zeros((prclen),1);
    tuafprch=zeros((prclen),1);
    tuevprch=zeros((prclen),1);
    weniprch=zeros((prclen),1);
    wemoprch=zeros((prclen),1);
    weafprch=zeros((prclen),1);
    weevprch=zeros((prclen),1);
    thniprch=zeros((prclen),1);
    thmoprch=zeros((prclen),1);
    thafprch=zeros((prclen),1);
    thevprch=zeros((prclen),1);
    frniprch=zeros((prclen),1);
    frmoprch=zeros((prclen),1);
    frafprch=zeros((prclen),1);
    frevprch=zeros((prclen),1);
    saniprch=zeros((prclen),1);
    samoprch=zeros((prclen),1);
    saafprch=zeros((prclen),1);
    saevprch=zeros((prclen),1);
    suniprch=zeros((prclen),1);
    sumoprch=zeros((prclen),1);
    suafprch=zeros((prclen),1);
    suevprch=zeros((prclen),1);
  end  
end


% Load our CSV data and populate the vectors
firstind=1;
calcprc=0;
prcind=1;
for f=1:length(csvfiles)
  csvfile=csvfiles{f};
  data=readtable(csvfile,'Delimiter',',');
  timevec=data.outputtimes;
  timevec=datetime(timevec,'InputFormat','eeee dd-MMM-uuuu HH:mm:ss');
  timevec.TimeZone=tzone;
  % Get start and end time
  if f==1
    starttime=timevec(1);
  end
  if f==length(csvfiles)
    fintime=timevec(length(timevec));
  end
  % Get the name of this year
  testtime=timevec(1);
  yrstr=num2str(testtime.Year);
  % Get the name of this month
  if f>1
    % Save the name of the previously read month, for year to year
    % comparisons 
    prevmonth=monthname;
  end
  monthname=month(testtime,'name');
  monthname=monthname{1};
  % If this month is the "first" of its series (e.g. when comparing
  % February - May of 2018-2020, and we just went through the Februaries 
  % already), mark it!
  if timeinfo==2
    if f>1
      if ~strcmpi(monthname,prevmonth)
        firstind=f;
        calcprc=0;
      else
        calcprc=1;
      end
    end
  else
    if f>1
      calcprc=1;
    end
  end
  csvlblsz{f}=strcat(yrstr,'_',monthname,'_','Z');
  csvlblsh{f}=strcat(yrstr,'_',monthname,'_','H');
  % Enter the times as datetimes! 
  zvec=data.rmsz;
  zvec(zvec==-1)=NaN;
  % Horizontal
  if xyh==0
    hvec=data.rmsh;
    hvec(hvec==-1)=NaN;
  else
    xvec=data.rmsx;
    yvec=data.rmsy;
    % Only 'discard' where RMS values could not be found for X and Y
    xvec(xvec==-1 && yvec==-1)=NaN;
    xvec(xvec==-1)=0;
    yvec(xvec==-1 && yvec==-1)=NaN;
    yvec(yvec==-1)=0;
    hvec=sqrt(xvec.^2+yvec.^2); 
  end  

  % Compute the means!
  if avgmode==0
    % 1 - Overall mean
    ovvecz(f)=mean(zvec(~isnan(zvec)));
    ovvech(f)=mean(hvec(~isnan(hvec)));

    % Divide the noise into time categories
    % Weekdays vs Weekends 
    wkdayz=[];
    wkdayh=[];
    wkendz=[];
    wkendh=[];
    wkdaytimes=[];
    wkendtimes=[];
    for i=1:length(timevec)
      nowtime=timevec(i);
      nowwkday=getweekday(nowtime);
      if strcmpi('Saturday',nowwkday) || strcmpi('Sunday',nowwkday)
        wkendz=[wkendz; zvec(i)];
        wkendh=[wkendh; hvec(i)];
        wkendtimes=[wkendtimes; nowtime];
      else
        wkdayz=[wkdayz; zvec(i)];
        wkdayh=[wkdayh; hvec(i)];
        wkdaytimes=[wkdaytimes; nowtime];
      end
    end

    % Compute the means of the weekdays and weekends
    wdayvecz(f)=mean(wkdayz(~isnan(wkdayz)));
    wdayvech(f)=mean(wkdayh(~isnan(wkdayh)));
    wendvecz(f)=mean(wkendz(~isnan(wkendz)));
    wendvech(f)=mean(wkendh(~isnan(wkendh)));

    % Separate out the times by night, morning, afternoon, evening
    % 'Night' - 00:00:00 - 05:59:59.99 Local Time
    nightz=zvec(timevec.Hour>=0 & timevec.Hour<6);
    nighth=hvec(timevec.Hour>=0 & timevec.Hour<6);
    % 'Morning' - 06:00:00 - 11:59:59 Local Time
    mornz=zvec(timevec.Hour>=6 & timevec.Hour<12);
    mornh=hvec(timevec.Hour>=6 & timevec.Hour<12);
    % 'Afternoon' - 12:00:00 - 17:59:59 Local Time
    aftz=zvec(timevec.Hour>=12 & timevec.Hour<18);
    afth=hvec(timevec.Hour>=12 & timevec.Hour<18);
    % 'Evening' - 18:00:00 - 23:59:59 Local Time
    evz=zvec(timevec.Hour>=18 & timevec.Hour<24);
    evh=hvec(timevec.Hour>=18 & timevec.Hour<24);

    % Compute the means of those times
    nightovz(f)=mean(nightz(~isnan(nightz)));
    nightovh(f)=mean(nighth(~isnan(nighth)));
    morovz(f)=mean(mornz(~isnan(mornz)));
    morovh(f)=mean(mornh(~isnan(mornh)));
    aftovz(f)=mean(aftz(~isnan(aftz)));
    aftovh(f)=mean(afth(~isnan(afth)));
    eveovz(f)=mean(evz(~isnan(evz)));
    eveovh(f)=mean(evh(~isnan(evh)));
  
    % Now, separate out the times by weekday-weekend AND time of day
    % Night
    wkdayzn=wkdayz(wkdaytimes.Hour>=0 & wkdaytimes.Hour<6);
    wkdayhn=wkdayh(wkdaytimes.Hour>=0 & wkdaytimes.Hour<6);
    wkendzn=wkendz(wkendtimes.Hour>=0 & wkendtimes.Hour<6);
    wkendhn=wkendh(wkendtimes.Hour>=0 & wkendtimes.Hour<6);
    % Means
    nightwdayz(f)=mean(wkdayzn(~isnan(wkdayzn)));
    nightwdayh(f)=mean(wkdayhn(~isnan(wkdayhn)));
    nightwendz(f)=mean(wkendzn(~isnan(wkendzn)));
    nightwendh(f)=mean(wkendhn(~isnan(wkendhn)));
 
    % Morning
    wkdayzm=wkdayz(wkdaytimes.Hour>=6 & wkdaytimes.Hour<12);
    wkdayhm=wkdayh(wkdaytimes.Hour>=6 & wkdaytimes.Hour<12);
    wkendzm=wkendz(wkendtimes.Hour>=6 & wkendtimes.Hour<12);
    wkendhm=wkendh(wkendtimes.Hour>=6 & wkendtimes.Hour<12);
    % Means
    morwdayz(f)=mean(wkdayzm(~isnan(wkdayzm)));
    morwdayh(f)=mean(wkdayhm(~isnan(wkdayhm)));
    morwendz(f)=mean(wkendzm(~isnan(wkendzm)));
    morwendh(f)=mean(wkendhm(~isnan(wkendhm)));
  
    % Afternoon
    wkdayza=wkdayz(wkdaytimes.Hour>=12 & wkdaytimes.Hour<18);
    wkdayha=wkdayh(wkdaytimes.Hour>=12 & wkdaytimes.Hour<18);
    wkendza=wkendz(wkendtimes.Hour>=12 & wkendtimes.Hour<18);
    wkendha=wkendh(wkendtimes.Hour>=12 & wkendtimes.Hour<18);
    % Means
    aftwdayz(f)=mean(wkdayza(~isnan(wkdayza)));
    aftwdayh(f)=mean(wkdayha(~isnan(wkdayha)));
    aftwendz(f)=mean(wkendza(~isnan(wkendza)));
    aftwendh(f)=mean(wkendha(~isnan(wkendha)));
  
    % Evening
    wkdayze=wkdayz(wkdaytimes.Hour>=18 & wkdaytimes.Hour<24);
    wkdayhe=wkdayh(wkdaytimes.Hour>=18 & wkdaytimes.Hour<24);
    wkendze=wkendz(wkendtimes.Hour>=18 & wkendtimes.Hour<24);
    wkendhe=wkendh(wkendtimes.Hour>=18 & wkendtimes.Hour<24);
    % Means
    evewdayz(f)=mean(wkdayze(~isnan(wkdayze)));
    evewdayh(f)=mean(wkdayhe(~isnan(wkdayhe)));
    evewendz(f)=mean(wkendze(~isnan(wkendze)));
    evewendh(f)=mean(wkendhe(~isnan(wkendhe)));
  
  else
    % Separate the RMS values by weekday and time of day
    % Monday
    mnzvec=[];
    mmozvec=[];
    mafzvec=[];
    mevzvec=[];
    mnhvec=[];
    mmohvec=[];
    mafhvec=[];
    mevhvec=[];
    % Tuesday
    tnzvec=[];
    tmozvec=[];
    tafzvec=[];
    tevzvec=[];
    tnhvec=[];
    tmohvec=[];
    tafhvec=[];
    tevhvec=[];
    % Wednesday
    wnzvec=[];
    wmozvec=[];
    wafzvec=[];
    wevzvec=[];
    wnhvec=[];
    wmohvec=[];
    wafhvec=[];
    wevhvec=[];
    % Thursday
    thnzvec=[];
    thmozvec=[];
    thafzvec=[];
    thevzvec=[];
    thnhvec=[];
    thmohvec=[];
    thafhvec=[];
    thevhvec=[];
    % Friday
    fnzvec=[];
    fmozvec=[];
    fafzvec=[];
    fevzvec=[];
    fnhvec=[];
    fmohvec=[];
    fafhvec=[];
    fevhvec=[];
    % Saturday
    sanzvec=[];
    samozvec=[];
    saafzvec=[];
    saevzvec=[];
    sanhvec=[];
    samohvec=[];
    saafhvec=[];
    saevhvec=[];
    % Sunday
    sunzvec=[];
    sumozvec=[];
    suafzvec=[];
    suevzvec=[];
    sunhvec=[];
    sumohvec=[];
    suafhvec=[];
    suevhvec=[];
    % 
    for i=1:length(timevec)
      nowtime=timevec(i);
      nowwkday=getweekday(nowtime);
      if strcmpi('Monday',nowwkday) 
        if (nowtime.Hour>=0 && nowtime.Hour<6)
          mnzvec=[mnzvec; zvec(i)];    
          mnhvec=[mnhvec; hvec(i)];    
        elseif (nowtime.Hour>=6 && nowtime.Hour<12)
          mmozvec=[mmozvec; zvec(i)];
          mmohvec=[mmohvec; hvec(i)];
        elseif (nowtime.Hour>=12 && nowtime.Hour<18)
          mafzvec=[mafzvec; zvec(i)];    
          mafhvec=[mafhvec; hvec(i)];   
        else
          mevzvec=[mevzvec; zvec(i)];   
          mevhvec=[mevhvec; hvec(i)];  
        end
      elseif strcmpi('Tuesday',nowwkday)
        if (nowtime.Hour>=0 && nowtime.Hour<6)
          tnzvec=[tnzvec; zvec(i)];    
          tnhvec=[tnhvec; hvec(i)];    
        elseif (nowtime.Hour>=6 && nowtime.Hour<12)
          tmozvec=[tmozvec; zvec(i)];
          tmohvec=[tmohvec; hvec(i)];
        elseif (nowtime.Hour>=12 && nowtime.Hour<18)
          tafzvec=[tafzvec; zvec(i)];    
          tafhvec=[tafhvec; hvec(i)];   
        else
          tevzvec=[tevzvec; zvec(i)];   
          tevhvec=[tevhvec; hvec(i)];  
        end
      elseif strcmpi('Wednesday',nowwkday)
        if (nowtime.Hour>=0 && nowtime.Hour<6)
          wnzvec=[wnzvec; zvec(i)];    
          wnhvec=[wnhvec; hvec(i)];    
        elseif (nowtime.Hour>=6 && nowtime.Hour<12)
          wmozvec=[wmozvec; zvec(i)];
          wmohvec=[wmohvec; hvec(i)];
        elseif (nowtime.Hour>=12 && nowtime.Hour<18)
          wafzvec=[wafzvec; zvec(i)];    
          wafhvec=[wafhvec; hvec(i)];   
        else
          wevzvec=[wevzvec; zvec(i)];   
          wevhvec=[wevhvec; hvec(i)];  
        end    
      elseif strcmpi('Thursday',nowwkday)
        if (nowtime.Hour>=0 && nowtime.Hour<6)
          thnzvec=[thnzvec; zvec(i)];    
          thnhvec=[thnhvec; hvec(i)];    
        elseif (nowtime.Hour>=6 && nowtime.Hour<12)
          thmozvec=[thmozvec; zvec(i)];
          thmohvec=[thmohvec; hvec(i)];
        elseif (nowtime.Hour>=12 && nowtime.Hour<18)
          thafzvec=[thafzvec; zvec(i)];    
          thafhvec=[thafhvec; hvec(i)];   
        else
          thevzvec=[thevzvec; zvec(i)];   
          thevhvec=[thevhvec; hvec(i)];  
        end
      elseif strcmpi('Friday',nowwkday)
        if (nowtime.Hour>=0 && nowtime.Hour<6)
          fnzvec=[fnzvec; zvec(i)];    
          fnhvec=[fnhvec; hvec(i)];    
        elseif (nowtime.Hour>=6 && nowtime.Hour<12)
          fmozvec=[fmozvec; zvec(i)];
          fmohvec=[fmohvec; hvec(i)];
        elseif (nowtime.Hour>=12 && nowtime.Hour<18)
          fafzvec=[fafzvec; zvec(i)];    
          fafhvec=[fafhvec; hvec(i)];   
        else
          fevzvec=[fevzvec; zvec(i)];   
          fevhvec=[fevhvec; hvec(i)];  
        end
      elseif strcmpi('Saturday',nowwkday)
        if (nowtime.Hour>=0 && nowtime.Hour<6)
          sanzvec=[sanzvec; zvec(i)];    
          sanhvec=[sanhvec; hvec(i)];    
        elseif (nowtime.Hour>=6 && nowtime.Hour<12)
          samozvec=[samozvec; zvec(i)];
          samohvec=[samohvec; hvec(i)];
        elseif (nowtime.Hour>=12 && nowtime.Hour<18)
          saafzvec=[saafzvec; zvec(i)];    
          saafhvec=[saafhvec; hvec(i)];   
        else
          saevzvec=[saevzvec; zvec(i)];   
          saevhvec=[saevhvec; hvec(i)];  
        end
      elseif strcmpi('Sunday',nowwkday)
        if (nowtime.Hour>=0 && nowtime.Hour<6)
          sunzvec=[sunzvec; zvec(i)];    
          sunhvec=[sunhvec; hvec(i)];    
        elseif (nowtime.Hour>=6 && nowtime.Hour<12)
          sumozvec=[sumozvec; zvec(i)];
          sumohvec=[sumohvec; hvec(i)];
        elseif (nowtime.Hour>=12 && nowtime.Hour<18)
          suafzvec=[suafzvec; zvec(i)];    
          suafhvec=[suafhvec; hvec(i)];   
        else
          suevzvec=[suevzvec; zvec(i)];   
          suevhvec=[suevhvec; hvec(i)];  
        end
      end
    end
    
    % Compute the  means!
    % Monday
    % Z
    monnightz(f)=mean(mnzvec(~isnan(mnzvec)));
    monmornz(f)=mean(mmozvec(~isnan(mmozvec)));
    monaftz(f)=mean(mafzvec(~isnan(mafzvec)));
    monevez(f)=mean(mevzvec(~isnan(mevzvec)));
    % H
    monnighth(f)=mean(mnhvec(~isnan(mnhvec)));
    monmornh(f)=mean(mmohvec(~isnan(mmohvec)));
    monafth(f)=mean(mafhvec(~isnan(mafhvec)));
    moneveh(f)=mean(mevhvec(~isnan(mevhvec)));
    
    % Tuesday
    % Z
    tuenightz(f)=mean(tnzvec(~isnan(tnzvec)));
    tuemornz(f)=mean(tmozvec(~isnan(tmozvec)));
    tueaftz(f)=mean(tafzvec(~isnan(tafzvec)));
    tueevez(f)=mean(tevzvec(~isnan(tevzvec)));
    % H
    tuenighth(f)=mean(tnhvec(~isnan(tnhvec)));
    tuemornh(f)=mean(tmohvec(~isnan(tmohvec)));
    tueafth(f)=mean(tafhvec(~isnan(tafhvec)));
    tueeveh(f)=mean(tevhvec(~isnan(tevhvec)));
    
    % Wednesday
    % Z
    wednightz(f)=mean(wnzvec(~isnan(wnzvec)));
    wedmornz(f)=mean(wmozvec(~isnan(wmozvec)));
    wedaftz(f)=mean(wafzvec(~isnan(wafzvec)));
    wedevez(f)=mean(wevzvec(~isnan(wevzvec)));
    % H
    wednighth(f)=mean(wnhvec(~isnan(wnhvec)));
    wedmornh(f)=mean(wmohvec(~isnan(wmohvec)));
    wedafth(f)=mean(wafhvec(~isnan(wafhvec)));
    wedeveh(f)=mean(wevhvec(~isnan(wevhvec)));
    
    % Thursday
    % Z
    thrnightz(f)=mean(thnzvec(~isnan(thnzvec)));
    thrmornz(f)=mean(thmozvec(~isnan(thmozvec)));
    thraftz(f)=mean(thafzvec(~isnan(thafzvec)));
    threvez(f)=mean(thevzvec(~isnan(thevzvec)));
    % H
    thrnighth(f)=mean(thnhvec(~isnan(thnhvec)));
    thrmornh(f)=mean(thmohvec(~isnan(thmohvec)));
    thrafth(f)=mean(thafhvec(~isnan(thafhvec)));
    threveh(f)=mean(thevhvec(~isnan(thevhvec)));
      
    % Friday
    % Z
    frinightz(f)=mean(fnzvec(~isnan(fnzvec)));
    frimornz(f)=mean(fmozvec(~isnan(fmozvec)));
    friaftz(f)=mean(fafzvec(~isnan(fafzvec)));
    frievez(f)=mean(fevzvec(~isnan(fevzvec)));
    % H
    frinighth(f)=mean(fnhvec(~isnan(fnhvec)));
    frimornh(f)=mean(fmohvec(~isnan(fmohvec)));
    friafth(f)=mean(fafhvec(~isnan(fafhvec)));
    frieveh(f)=mean(fevhvec(~isnan(fevhvec)));
    
    % Saturday
    % Z
    satnightz(f)=mean(sanzvec(~isnan(sanzvec)));
    satmornz(f)=mean(samozvec(~isnan(samozvec)));
    sataftz(f)=mean(saafzvec(~isnan(saafzvec)));
    satevez(f)=mean(saevzvec(~isnan(saevzvec)));
    % H
    satnighth(f)=mean(sanhvec(~isnan(sanhvec)));
    satmornh(f)=mean(samohvec(~isnan(samohvec)));
    satafth(f)=mean(saafhvec(~isnan(saafhvec)));
    sateveh(f)=mean(saevhvec(~isnan(saevhvec)));
    
    % Sunday
    % Z
    sunnightz(f)=mean(sunzvec(~isnan(sunzvec)));
    sunmornz(f)=mean(sumozvec(~isnan(sumozvec)));
    sunaftz(f)=mean(suafzvec(~isnan(suafzvec)));
    sunevez(f)=mean(suevzvec(~isnan(suevzvec)));
    % H
    sunnighth(f)=mean(sunhvec(~isnan(sunhvec)));
    sunmornh(f)=mean(sumohvec(~isnan(sumohvec)));
    sunafth(f)=mean(suafhvec(~isnan(suafhvec)));
    suneveh(f)=mean(suevhvec(~isnan(suevhvec)));
  end
  
  %%%%%%%%%%%%%
  % Compute the percent changes, if processing more than 1 CSV file
  if f>1 && calcprc==1
    csvlblsprcz{prcind}=strcat(yrstr,'_',monthname,'_','Z');
    csvlblsprch{prcind}=strcat(yrstr,'_',monthname,'_','H');
    % How we want to compute the percent changes depends on whether we're 
    % computing month-by-month or year-by-year 
    if avgmode==0
      % Overall
      ovprz(prcind)=((ovvecz(f)-ovvecz(firstind))/ovvecz(firstind))*100;
      ovprh(prcind)=((ovvech(f)-ovvech(firstind))/ovvech(firstind))*100;
      % Weekday-weekend
      wdayprz(prcind)=((wdayvecz(f)-wdayvecz(firstind))/wdayvecz(firstind))*100;
      wdayprh(prcind)=((wdayvech(f)-wdayvech(firstind))/wdayvech(firstind))*100;
      wendprz(prcind)=((wendvecz(f)-wendvecz(firstind))/wendvecz(firstind))*100;
      wendprh(prcind)=((wendvech(f)-wendvech(firstind))/wendvech(firstind))*100;
      % Time of day
      novprz(prcind)=((nightovz(f)-nightovz(firstind))/nightovz(firstind))*100;
      novprh(prcind)=((nightovh(f)-nightovh(firstind))/nightovh(firstind))*100;
      moovprz(prcind)=((morovz(f)-morovz(firstind))/morovz(firstind))*100;
      moovprh(prcind)=((morovh(f)-morovh(firstind))/morovh(firstind))*100;
      afovprz(prcind)=((aftovz(f)-aftovz(firstind))/aftovz(firstind))*100;
      afovprh(prcind)=((aftovh(f)-aftovh(firstind))/aftovh(firstind))*100;
      evovprz(prcind)=((eveovz(f)-eveovz(firstind))/eveovz(firstind))*100;
      evovprh(prcind)=((eveovh(f)-eveovh(firstind))/eveovh(firstind))*100;
      % Weekday-weekend and time of day
      nwdayprz(prcind)=((nightwdayz(f)-nightwdayz(firstind))/nightwdayz(firstind))*100;
      nwdayprh(prcind)=((nightwdayh(f)-nightwdayh(firstind))/nightwdayh(firstind))*100;
      nwendprz(prcind)=((nightwendz(f)-nightwendz(firstind))/nightwendz(firstind))*100;
      nwendprh(prcind)=((nightwendh(f)-nightwendh(firstind))/nightwendh(firstind))*100;
      mowdayprz(prcind)=((morwdayz(f)-morwdayz(firstind))/morwdayz(firstind))*100;
      mowdayprh(prcind)=((morwdayh(f)-morwdayh(firstind))/morwdayh(firstind))*100;
      mowendprz(prcind)=((morwendz(f)-morwendz(firstind))/morwendz(firstind))*100;
      mowendprh(prcind)=((morwendh(f)-morwendh(firstind))/morwendh(firstind))*100;
      afwdayprz(prcind)=((aftwdayz(f)-aftwdayz(firstind))/aftwdayz(firstind))*100;
      afwdayprh(prcind)=((aftwdayh(f)-aftwdayh(firstind))/aftwdayh(firstind))*100;
      afwendprz(prcind)=((aftwendz(f)-aftwendz(firstind))/aftwendz(firstind))*100;
      afwendprh(prcind)=((aftwendh(f)-aftwendh(firstind))/aftwendh(firstind))*100;
      evwdayprz(prcind)=((evewdayz(f)-evewdayz(firstind))/evewdayz(firstind))*100;
      evwdayprh(prcind)=((evewdayh(f)-evewdayh(firstind))/evewdayh(firstind))*100;
      evwendprz(prcind)=((evewendz(f)-evewendz(firstind))/evewendz(firstind))*100;
      evwendprh(prcind)=((evewendh(f)-evewendh(firstind))/evewendh(firstind))*100;
    else
      % Monday
      % Z
      moniprcz(prcind)=((monnightz(f)-monnightz(firstind))/monnightz(firstind))*100;
      momoprcz(prcind)=((monmornz(f)-monmornz(firstind))/monmornz(firstind))*100;
      moafprcz(prcind)=((monaftz(f)-monaftz(firstind))/monaftz(firstind))*100;
      moevprcz(prcind)=((monevez(f)-monevez(firstind))/monevez(firstind))*100;
      % H
      moniprch(prcind)=((monnighth(f)-monnighth(firstind))/monnighth(firstind))*100;
      momoprch(prcind)=((monmornh(f)-monmornh(firstind))/monmornh(firstind))*100;
      moafprch(prcind)=((monafth(f)-monafth(firstind))/monafth(firstind))*100;
      moevprch(prcind)=((moneveh(f)-moneveh(firstind))/moneveh(firstind))*100;
      
      % Tuesday
      % Z
      tuniprcz(prcind)=((tuenightz(f)-tuenightz(firstind))/tuenightz(firstind))*100;
      tumoprcz(prcind)=((tuemornz(f)-tuemornz(firstind))/tuemornz(firstind))*100;
      tuafprcz(prcind)=((tueaftz(f)-tueaftz(firstind))/tueaftz(firstind))*100;
      tuevprcz(prcind)=((tueevez(f)-tueevez(firstind))/tueevez(firstind))*100;
      % H
      tuniprch(prcind)=((tuenighth(f)-tuenighth(firstind))/tuenighth(firstind))*100;
      tumoprch(prcind)=((tuemornh(f)-tuemornh(firstind))/tuemornh(firstind))*100;
      tuafprch(prcind)=((tueafth(f)-tueafth(firstind))/tueafth(firstind))*100;
      tuevprch(prcind)=((tueeveh(f)-tueeveh(firstind))/tueeveh(firstind))*100;
      
      % Wednesday
      % Z
      weniprcz(prcind)=((wednightz(f)-wednightz(firstind))/wednightz(firstind))*100;
      wemoprcz(prcind)=((wedmornz(f)-wedmornz(firstind))/wedmornz(firstind))*100;
      weafprcz(prcind)=((wedaftz(f)-wedaftz(firstind))/wedaftz(firstind))*100;
      weevprcz(prcind)=((wedevez(f)-wedevez(firstind))/wedevez(firstind))*100;
      % H
      weniprch(prcind)=((wednighth(f)-wednighth(firstind))/wednighth(firstind))*100;
      wemoprch(prcind)=((wedmornh(f)-wedmornh(firstind))/wedmornh(firstind))*100;
      weafprch(prcind)=((wedafth(f)-wedafth(firstind))/wedafth(firstind))*100;
      weevprch(prcind)=((wedeveh(f)-wedeveh(firstind))/wedeveh(firstind))*100;
      
      % Thursday
      % Z
      thniprcz(prcind)=((thrnightz(f)-thrnightz(firstind))/thrnightz(firstind))*100;
      thmoprcz(prcind)=((thrmornz(f)-thrmornz(firstind))/thrmornz(firstind))*100;
      thafprcz(prcind)=((thraftz(f)-thraftz(firstind))/thraftz(firstind))*100;
      thevprcz(prcind)=((threvez(f)-threvez(firstind))/threvez(firstind))*100;
      % H
      thniprch(prcind)=((thrnighth(f)-thrnighth(firstind))/thrnighth(firstind))*100;
      thmoprch(prcind)=((thrmornh(f)-thrmornh(firstind))/thrmornh(firstind))*100;
      thafprch(prcind)=((thrafth(f)-thrafth(firstind))/thrafth(firstind))*100;
      thevprch(prcind)=((threveh(f)-threveh(firstind))/threveh(firstind))*100;
      
      % Friday
      % Z
      frniprcz(prcind)=((frinightz(f)-frinightz(firstind))/frinightz(firstind))*100;
      frmoprcz(prcind)=((frimornz(f)-frimornz(firstind))/frimornz(firstind))*100;
      frafprcz(prcind)=((friaftz(f)-friaftz(firstind))/friaftz(firstind))*100;
      frevprcz(prcind)=((frievez(f)-frievez(firstind))/frievez(firstind))*100;
      % H
      frniprch(prcind)=((frinighth(f)-frinighth(firstind))/frinighth(firstind))*100;
      frmoprch(prcind)=((frimornh(f)-frimornh(firstind))/frimornh(firstind))*100;
      frafprch(prcind)=((friafth(f)-friafth(firstind))/friafth(firstind))*100;
      frevprch(prcind)=((frieveh(f)-frieveh(firstind))/frieveh(firstind))*100;
      
      % Saturday
      % Z
      saniprcz(prcind)=((satnightz(f)-satnightz(firstind))/satnightz(firstind))*100;
      samoprcz(prcind)=((satmornz(f)-satmornz(firstind))/satmornz(firstind))*100;
      saafprcz(prcind)=((sataftz(f)-sataftz(firstind))/sataftz(firstind))*100;
      saevprcz(prcind)=((satevez(f)-satevez(firstind))/satevez(firstind))*100;
      % H
      saniprch(prcind)=((satnighth(f)-satnighth(firstind))/satnighth(firstind))*100;
      samoprch(prcind)=((satmornh(f)-satmornh(firstind))/satmornh(firstind))*100;
      saafprch(prcind)=((satafth(f)-satafth(firstind))/satafth(firstind))*100;
      saevprch(prcind)=((sateveh(f)-sateveh(firstind))/sateveh(firstind))*100;
      
      % Sunday
      % Z
      suniprcz(prcind)=((sunnightz(f)-sunnightz(firstind))/sunnightz(firstind))*100;
      sumoprcz(prcind)=((sunmornz(f)-sunmornz(firstind))/sunmornz(firstind))*100;
      suafprcz(prcind)=((sunaftz(f)-sunaftz(firstind))/sunaftz(firstind))*100;
      suevprcz(prcind)=((sunevez(f)-sunevez(firstind))/sunevez(firstind))*100;
      % H
      suniprch(prcind)=((sunnighth(f)-sunnighth(firstind))/sunnighth(firstind))*100;
      sumoprch(prcind)=((sunmornh(f)-sunmornh(firstind))/sunmornh(firstind))*100;
      suafprch(prcind)=((sunafth(f)-sunafth(firstind))/sunafth(firstind))*100;
      suevprch(prcind)=((suneveh(f)-suneveh(firstind))/suneveh(firstind))*100;
    end
    prcind=prcind+1;
  end
end
 

% Make and save the table(s)
freqstr1=num2str(frequency(1));
freqstr2=num2str(frequency(2));
freqstr3=num2str(frequency(3));
freqstr4=num2str(frequency(4));
vallbls={'D';'V';'A'};
startymd=sprintf('%d%s%s',starttime.Year,datenum2str(starttime.Month,0),...
  datenum2str(starttime.Day,0));
finalymd=sprintf('%d%s%s',fintime.Year,datenum2str(fintime.Month,0),...
  datenum2str(fintime.Day,0));
% CSV file name(s)
if timeinfo==1
  compstr='moncomp';
else
  compstr='yrcomp';
end
seiscsv=sprintf('RMS%sinNM_Avg%d_%s_%sto%s_%s_%s%s%s%s.csv',...
  vallbls{measval+1},avgmode,compstr,startymd,finalymd,tzlabel,freqstr1,...
  freqstr2,freqstr3,freqstr4);
seiscsvprc=sprintf('RMS%sinNM_MeanPrcChg_Avg%d_%s_%sto%s_%s_%s%s%s%s.csv',...
  vallbls{measval+1},avgmode,compstr,startymd,finalymd,tzlabel,freqstr1,...
  freqstr2,freqstr3,freqstr4);

% Concatenate the Z and H data
csvlbls=vertcat(csvlblsz,csvlblsh);
if length(csvfiles)>1
  csvlblsprc=vertcat(csvlblsprcz,csvlblsprch);
end

if avgmode==0
  % Columns, from left to right:
  % Year/month, overall, weekdays, weekends, nights overall, weekday nights,
  % weekend nights, mornings overall, weekday mornings, weekend mornings,
  % afternoons overall, weekday afternoons, weekend afternoons, 
  % evenings overall, weekday evenings, weekend evenings
  try
    ovvec=vertcat(ovvecz,ovvech);
    wdayvec=vertcat(wdayvecz,wdayvech);
    wendvec=vertcat(wendvecz,wendvech);
    nightov=vertcat(nightovz,nightovh);
    nightwday=vertcat(nightwdayz,nightwdayh);
    nightwend=vertcat(nightwendz,nightwendh);
    morov=vertcat(morovz,morovh);
    morwday=vertcat(morwdayz,morwdayh);
    morwend=vertcat(morwendz,morwendh);
    aftov=vertcat(aftovz,aftovh);
    aftwday=vertcat(aftwdayz,aftwdayh);
    aftwend=vertcat(aftwendz,aftwendh);
    eveov=vertcat(eveovz,eveovh);
    evewday=vertcat(evewdayz,evewdayh);
    evewend=vertcat(evewendz,evewendh);
    seistbl=table(csvlbls,ovvec,wdayvec,wendvec,nightov,nightwday,...
      nightwend,morov,morwday,morwend,aftov,aftwday,aftwend,...
      eveov,evewday,evewend);
  catch
    keyboard
  end

  % Make the percent change table if necessary!
  if length(csvfiles)>1
    % Columns, from left to right:
    % Month, overall, weekdays, weekends, nights overall, weekday nights,
    % weekend nights, mornings overall, weekday mornings, weekend mornings,
    % afternoons overall, weekday afternoons, weekend afternoons, 
    % evenings overall, weekday evenings, weekend evenings
    try
      ovpr=vertcat(ovprz,ovprh);
      wdaypr=vertcat(wdayprz,wdayprh);
      wendpr=vertcat(wendprz,wendprh);
      novpr=vertcat(novprz,novprh);
      nwdaypr=vertcat(nwdayprz,nwdayprh);
      nwendpr=vertcat(nwendprz,nwendprh);
      moovpr=vertcat(moovprz,moovprh);
      mowdaypr=vertcat(mowdayprz,mowdayprh);
      mowendpr=vertcat(mowendprz,mowendprh);
      afovpr=vertcat(afovprz,afovprh);
      afwdaypr=vertcat(afwdayprz,afwdayprh);
      afwendpr=vertcat(afwendprz,afwendprh);
      evovpr=vertcat(evovprz,evovprh);
      evwdaypr=vertcat(evwdayprz,evwdayprh);
      evwendpr=vertcat(evwendprz,evwendprh);
      seistblprc=table(csvlblsprc,ovpr,wdaypr,wendpr,novpr,nwdaypr,...
        nwendpr,moovpr,mowdaypr,mowendpr,afovpr,afwdaypr,afwendpr,...
        evovpr,evwdaypr,evwendpr);
    catch
      keyboard
    end
  end
else
  % Columns, from left to right:
  % Month, Monday nights, Monday mornings, Monday afternoons, Monday 
  % evenings, Tuesday nights, Tuesday afternoons,... Friday evenings
  try
    monnight=vertcat(monnightz,monnighth);
    monmorn=vertcat(monmornz,monmornh);
    monaft=vertcat(monaftz,monafth);
    moneve=vertcat(monevez,moneveh);
    tuenight=vertcat(tuenightz,tuenighth);
    tuemorn=vertcat(tuemornz,tuemornh);
    tueaft=vertcat(tueaftz,tueafth);
    tueeve=vertcat(tueevez,tueeveh);
    wednight=vertcat(wednightz,wednighth);
    wedmorn=vertcat(wedmornz,wedmornh);
    wedaft=vertcat(wedaftz,wedafth);
    wedeve=vertcat(wedevez,wedeveh);
    thrnight=vertcat(thrnightz,thrnighth);
    thrmorn=vertcat(thrmornz,thrmornh);
    thraft=vertcat(thraftz,thrafth);
    threve=vertcat(threvez,threveh);
    frinight=vertcat(frinightz,frinighth);
    frimorn=vertcat(frimornz,frimornh);
    friaft=vertcat(friaftz,friafth);
    frieve=vertcat(frievez,frieveh);
    satnight=vertcat(satnightz,satnighth);
    satmorn=vertcat(satmornz,satmornh);
    sataft=vertcat(sataftz,satafth);
    sateve=vertcat(satevez,sateveh);
    sunnight=vertcat(sunnightz,sunnighth);
    sunmorn=vertcat(sunmornz,sunmornh);
    sunaft=vertcat(sunaftz,sunafth);
    suneve=vertcat(sunevez,suneveh);
    seistbl=table(csvlbls,monnight,monmorn,monaft,moneve,tuenight,...
      tuemorn,tueaft,tueeve,wednight,wedmorn,wedaft,wedeve,thrnight,...
      thrmorn,thraft,threve,frinight,frimorn,friaft,frieve,satnight,...
      satmorn,sataft,sateve,sunnight,sunmorn,sunaft,suneve);
  catch
    keyboard
  end
  
  % Percent change table
  if length(csvfiles)>1
    try
      moniprc=vertcat(moniprcz,moniprch);
      momoprc=vertcat(momoprcz,momoprch);
      moafprc=vertcat(moafprcz,moafprch);
      moevprc=vertcat(moevprcz,moevprch);
      tuniprc=vertcat(tuniprcz,tuniprch);
      tumoprc=vertcat(tumoprcz,tumoprch);
      tuafprc=vertcat(tuafprcz,tuafprch);
      tuevprc=vertcat(tuevprcz,tuevprch);
      weniprc=vertcat(weniprcz,weniprch);
      wemoprc=vertcat(wemoprcz,wemoprch);
      weafprc=vertcat(weafprcz,weafprch);
      weevprc=vertcat(weevprcz,weevprch);
      thniprc=vertcat(thniprcz,thniprch);
      thmoprc=vertcat(thmoprcz,thmoprch);
      thafprc=vertcat(thafprcz,thafprch);
      thevprc=vertcat(thevprcz,thevprch);
      frniprc=vertcat(frniprcz,frniprch);
      frmoprc=vertcat(frmoprcz,frmoprch);
      frafprc=vertcat(frafprcz,frafprch);
      frevprc=vertcat(frevprcz,frevprch);
      saniprc=vertcat(saniprcz,saniprch);
      samoprc=vertcat(samoprcz,samoprch);
      saafprc=vertcat(saafprcz,saafprch);
      saevprc=vertcat(saevprcz,saevprch);
      suniprc=vertcat(suniprcz,suniprch);
      sumoprc=vertcat(sumoprcz,sumoprch);
      suafprc=vertcat(suafprcz,suafprch);
      suevprc=vertcat(suevprcz,suevprch);
      seistblprc=table(csvlblsprc,moniprc,momoprc,moafprc,moevprc,...
        tuniprc,tumoprc,tuafprc,tuevprc,weniprc,wemoprc,weafprc,...
        weevprc,thniprc,thmoprc,thafprc,thevprc,frniprc,frmoprc,...
        frafprc,frevprc,saniprc,samoprc,saafprc,saevprc,suniprc,...
        sumoprc,suafprc,suevprc);
    catch
      keyboard
    end
  end
end

try
  writetable(seistbl,seiscsv)
  if length(csvfiles)>1
    writetable(seistblprc,seiscsvprc)
    seistbls={seistbl;seistblprc};
    seiscsvs={seiscsv;seiscsvprc};
  else
    seistbls=seistbl;
    seiscsvs=seiscsv;
  end
catch
  keyboard
end

% If we want to make graphics of the percent changes
if makeplots==1 && length(csvfiles)>1
  startstrs=csvlbls{1};
  startstrs=strsplit(startstrs,'_');
  if timeinfo==1
    startstr=sprintf('%s %s',startstrs{2},startstrs{1});
  else
    startstr=startstrs{1};
  end
  figurehdls=seiscsvplot(seiscsvprc,timeinfo,startstr,avgmode,...
    measval,frequency,tzlabel,saveplot,savedir);
end

