function [cbtbl,cbfile]=cbston(maybehrs,measval,frequency,savetbl,savedir)
%
% Function to determine whether campus blasts took place in inputted
% hours, by virtue of computing a pseudo signal-to-noise ratio. 
% For each hour inputted, the program will retrieve an hour of 
% deconvolved and filtered (at the inputted frequencies) data. 
% Then, the program will determine where the signal amplitude is 
% maximized (in magnitude), and construct a 10 second window around it:
% 5 s before, 5 s after. Then, the program computes the 25th percentile
% of the signal in this interval, and compute the ratio of the max. signal
% to that value. This will be done for each directional component. 
% 
% Before we get to that, the program will do this same process for the 
% times when campus blasts are known to have occurred, and 
% average the resulting signal-to-noise for each component. This is so that 
% our tested signal-to-noise ratios can have something we can compare
% them to. If the tested values equal at least as big as the 
% smallest signal to noise ratio among the known blasts, then it is likely
% that our signal is also a campus blast.
% 
% For a signal to be a likely campus blast, this threshold must be met
% in all directional components. 
%
% For all the signals deemed "likely", the timestamps, signal-to-noise
% ratios, and signal-to-noise ratio ratio with respect to the 
% known averages for each component will be compiled into a table and 
% returned. Additionally, figures will be made for each of the 
% generated 3 component signals and outputted. 
% 
% INPUTS
% maybehrs : Vector of hours, from which we will generate one-hour time
%            series to test for campus blasts using the method above.
%            Enter as a datetime, in UTC! 
% measval : Displacement, velocity, or acceleration?
%           0 for displacement in nm (default if left empty)
%           1 for velocity in nm/s 
%           2 for acceleration in nm/(s^2)
% frequency : The frequencies at which we wish to filter the data
%             Enter as a four-element vector 
%             Default: [0.75 1.50 5.00 10.00] Hz
% savetbl : Do we want to save our table as a text file?
%           0 - No
%           1 - Yes
% savedir : Where do we want to save our text file? Input a directory!
%           Otherwise, this is saved in the current working directory.
% 
% OUTPUTS
% cbtbl : The output table of time stamps, signal-to-noise ratio, and
%         signal-to-noise ratio ratio for all the events deemed likely
%         campus blasts
% cbfile : The output table, saved as a text file 
% 
% See mstimes2sac.m, plotsacdata.m
% 
% References
% Uses defval.m in csdms-contrib/slepian_alpha 
% Campus blast information from Princeton University Facilities
% 
% Last Modified by Yuri Tamama, 09/21/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
defval('measval',0)
defval('frequency',[0.75 1.50 5.00 10.00])

% First: generate "signal-to-noise" ratio of known campus blasts:
% ~ 11:30 AM - 11:40 AM Eastern Time on 
% February 18, 2020; February 21, 2020; and March 4, 2020]
starttime1=datetime(2020,2,18,11,0,0);
starttime1.TimeZone='America/New_York';
starttime1.TimeZone='UTC';
finaltime1=starttime1;
finaltime1.Second=finaltime1.Second+3599.99;
[sacfiles1,~]=mstime2sac(measval,starttime1,finaltime1,...
  frequency,100,pwd,1,0,'');

% Compute the "signal to noise ratio"
interval=1801*100:1811*100-1;
datetimesz=[];
datetimesy=[];
datetimesx=[];
stonz=[];
stony=[];
stonx=[];
maxvalsz=[];
maxvalsy=[];
maxvalsx=[];
for c=1:3
  cbfile=sacfiles1{c};
  [sacdata,~]=readsac(cbfile,0);
  cutdata=sacdata(1801*100:1811*100-1);
  maxval=max(abs(cutdata));
  maxtimecb=interval(abs(cutdata)==maxval);
  cbdatetime=starttime1;
  cbdatetime.Second=cbdatetime.Second+(maxtimecb/100);
  noise=prctile(abs(cutdata),25);
  if c==1
    stonzcbm=maxval/noise;
    datetimesz=[datetimesz; cbdatetime];
    stonz=[stonz; stonzcbm];
    maxvalsz=[maxvalsz; maxval];
  elseif c==2
    stonycbm=maxval/noise;
    datetimesy=[datetimesy; cbdatetime];
    stony=[stony; stonycbm];
    maxvalsy=[maxvalsy; maxval];
  else
    stonxcbm=maxval/noise;
    datetimesx=[datetimesx; cbdatetime];
    stonx=[stonx; stonxcbm];
    maxvalsx=[maxvalsx; maxval];
  end
end

% Iterate through the hours, retrieve seismic data, compute the 
% "signal to noise"
for h=1:length(maybehrs)
  timevec=1:360000; % 1 to 3600s, spaced 0.01s apart
  starttime=maybehrs(h);
  finaltime=starttime;
  finaltime.Second=finaltime.Second+3599.99;
  [sacfiles,~]=mstime2sac(measval,starttime,finaltime,...
    frequency,100,pwd,0,0,'');
  sacdataz=readsac(sacfiles{1},0);
  sacdatay=readsac(sacfiles{2},0);
  sacdatax=readsac(sacfiles{3},0);
  
  % Find what might be a campus blast!
  % The known blasts were strongest in X, so narrow down the data to a 
  % short interval around max X and find the corresponding times for 
  % Y and Z
  maxvalx=max(abs(sacdatax));
  maxtimex=timevec(abs(sacdatax)==maxvalx);
  maxtimex=maxtimex(1);
  % Check if we ***can*** make a 10 second interval... otherwise, extend
  % the length of the time series
  if maxtimex<501 || maxtimex>359501
    starttimenew=starttime;
    finaltimenew=finaltime;
    % Add 15 minutes to the time series! 
    if maxtimex<501
      starttimenew.Second=starttimenew.Second-900;
    end
    if maxtimex>359501
      finaltimenew.Second=finaltimenew.Second+900;
    end
    [sacfiles,~]=mstime2sac(measval,starttimenew,finaltimenew,...
      frequency,100,pwd,0,0,'');
    % Retrieve new, extended data
    sacdataz=readsac(sacfiles{1},0);
    sacdatay=readsac(sacfiles{2},0);
    sacdatax=readsac(sacfiles{3},0);
    % Compute the maxima again
    maxvalx=max(abs(sacdatax));
    timevec=1:450000;
    maxtimex=timevec(abs(sacdatax)==maxvalx);
    starttime=starttimenew;
  end
  
  % Construct a 10 second interval
  interval=maxtimex-500:maxtimex+499; 
  cutdataz=sacdataz(interval);
  maxvalz=max(abs(cutdataz));
  maxtimez=interval(abs(cutdataz)==maxvalz);
  cutdatay=sacdatay(interval);
  maxvaly=max(abs(cutdatay));
  maxtimey=interval(abs(cutdatay)==maxvaly);
  cutdatax=sacdatax(interval);

  % Compute "signal to noise"
  % Compare to averaged known value
  noisez=prctile(abs(cutdataz),25);
  stonzval=maxvalz/noisez;
  zpass=(stonzval>=stonzcbm);
  % Y
  noisey=prctile(abs(cutdatay),25);
  stonyval=maxvaly/noisey;
  ypass=(stonyval>=stonycbm);
  % X
  noisex=prctile(abs(cutdatax),25);
  stonxval=maxvalx/noisex;
  xpass=(stonxval>=stonxcbm);
  
  % If all 3 components pass, add the times to the vector! 
  if (xpass+ypass+zpass)==3
    stonz=[stonz; stonzval];
    stony=[stony; stonyval];
    stonx=[stonx; stonxval];
    maxvalsz=[maxvalsz; maxvalz];
    maxvalsy=[maxvalsy; maxvaly];
    maxvalsx=[maxvalsx; maxvalx];
    
    % Times of the "blasts" (aka maximum values)
    datetimez=starttime;
    datetimez.Second=datetimez.Second+(maxtimez/100);
    datetimesz=[datetimesz; datetimez];
    datetimey=starttime;
    datetimey.Second=datetimey.Second+(maxtimey/100);
    datetimesy=[datetimesy; datetimey];
    datetimex=starttime;
    datetimex.Second=datetimex.Second+(maxtimex/100);
    datetimesx=[datetimesx; datetimex];
    
    % Also plot the SAC data! 
    figure();
    [seisplot,~,~]=plotsacdata(1,sacfiles,[1 2 3],3,measval,frequency,...
      [],[],[],100,100,1,0,0,'',2);
  end
end
    
% Make the table
cbtbl=table(datetimesz,stonz,maxvalsz,datetimesy,stony,maxvalsy,...
  datetimesx,stonx,maxvalsx);
    
if savetbl==1
  vallabels={'disp';'vel';'acc'};
  freqstr1=sprintf('%.2f',frequency(1));
  freqstr2=sprintf('%.2f',frequency(2));
  freqstr3=sprintf('%.2f',frequency(3));
  freqstr4=sprintf('%.2f',frequency(4)); 
  monthnames={'Jan';'Feb';'Mar';'Apr';'May';'Jun';'Jul';'Aug';'Sep';...
    'Oct';'Nov';'Dec'};
  time1=maybehrs(1);
  datestr1=sprintf('%s%s%s',monthnames{time1.Month},...
    datenum2str(time1.Day,0),datenum2str(time1.Year,0));
  timeend=maybehrs(length(maybehrs));
  datestrend=sprintf('%s%s%s',monthnames{timeend.Month},...
    datenum2str(timeend.Day,0),datenum2str(timeend.Year,0));

  cbfile=sprintf('CB.StoNtest.%s.%s.to.%s.%s%s%s%s.csv',...
    vallabels{measval+1},datestr1,datestrend,freqstr1,freqstr2,...
    freqstr3,freqstr4);
  % Write to text file
  writetable(cbtbl,cbfile); 
  
  % Move the text file if requested
  if ~isempty(savedir)
    [status,cmdout]=system(sprintf('mv %s %s',cbfile,savedir));
    cbfile=fullfile(savedir,cbfile);
  end
else
  cbfile='';
end
