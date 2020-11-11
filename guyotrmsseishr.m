function [outputtbl,csvfile,probtimes,mmstimes,msctimes,mdtimes]=guyotrmsseishr(measval,...
    starttime,finaltime,frequency,rmoutlier,timezone,tzlabel)
%
% Function that computes the average root mean squared (rms) displacement, 
% velocity, or acceleration recorded by the Meridian Compact PH1 0248
% seismometer stationed at Guyot Hall (Princeton University) for 
% every hour in a specified time span. 
% These values will be saved in csv files, to avoid repeating lengthy 
% processes in the future.
% 
% For inputted hours 01:00:00-23:00:00, over days 1-31 of January 2020, 
% for example, the function returns the rms 
% displacement/velocity/acceleration of every hour over the entire month.
% (This function is a higher-resolution version of guyotrmsseisday.m).
% This function will be useful in finding cycles with periods exceeding 
% 24 hours. 
% 
% INPUTS
% measval : Displacement, velocity, or acceleration?
%           0 - Displacement (default)
%           1 - Velocity
%           2 - Acceleration
% starttime : The time at which we begin our time series, entered as 
%             a whole numbered hour. 
%             Enter in the time zone in which we want to format our 
%             time series! 
% finaltime : The time at which we end our time series, entered as a 
%             whole numbered hour. The time series will include this final
%             hour. 
%             Enter in the time zone in which we want to format our 
%             time series! 
% timezone : The timezone in which we want to process our data
% tzlabel : How we should label our time zone in our resulting CSV file 
%           name
% frequency : The frequencies through which the seismometer data will be 
%             filtered
%             Default: [0.5 1.0 20.0 40.0] Hz
% rmoutlier :  If we want to remove outliers, how do we want to do it?
%              0 - Enter a percentage limit. For every hour of seismic
%                  data, we remove signals that are at or above this
%                  percentile. To remove outliers this way, enter a two 
%                  number vector, with 0 as the first element and the 
%                  percentile limit as the second, like this:
%                  [0 95] - remove the top 5% of signals per hour
% 
%              1 - Alternatively, we remove outliers that are more than X
%                  median standard deviations (MAD) away from the median. 
%                  Enter a 2 number vector, with 1 as the first element 
%                  and the # of MADs as the second, like this:
%                  [1 3] - remove signals at least 3 MADs away from the
%                          median for every hour 
% 
%              Input an empty array if we don't want to cut out any signals
%              (Default!)
%
% NOTE: 
% The csv file outputted by our code will have the times listed in 
% local time. Furthermore,the hour 00:00:00, for example, has the 
% RMS corresponding to 00:00:00-00:59:59
% 
% NOTE 2:
% starttime and finaltime should be in the same year
%
% OUTPUTS
% outputtbl : A table containing the rms values for each hour and 
%             component (X, Y, H, and Z), over the specified time span
%             The first column denotes a local time, while each
%             subsequent column is a directional component. From left to 
%             right, the components are:
%             X : X (East-West) component
%             Y : Y (North-South) component
%             H : Horizonal component
%             Z : Vertical 
% csvfile : The name of the CSV file, stored in the present working 
%           directory, that contains the data in outputtbl
% probtimes : A list of times for which the miniseed files convert to 
%             tens of SAC files, due to GPS connection issues. This list
%             contains the times in UTC and is a CSV file
% mmstimes : A list of times for which the miniseed files do not exist.
%            This list contains the times in UTC and is a CSV file
% msctimes : A list of times for which the miniseed files exist, but 
%            the corresponding SAC files do not. This list contains the
%            times in UTC and is a CSV file.
% mdtimes : A list of times for which the returned SAC file is incomplete 
%          (i.e. missing data from that hour). This list contains the times
%          in UTC and is a CSV file
% 
% Note: There are a few days for which data do not exist. If data for 
% none of the hours surveyed exist, then the rms returned will be -1, 
% to serve as an indicator.
%            
% References
% Code to convert from a .miniseed file to a .SAC file and
% apply instrument response correction from
% mcms2mat.m, in csdms-contrib/slepian_oscar
% Uses defval.m, in csdms-contrib/slepian_alpha 
% Uses jul2dat.m, dat2jul.m in csdms-contrib/slepian_oscar
% Checking whether a file is in the current directory is a neat trick I 
% found from the mathworks MATLAB forum!
%
% The seismic data are recorded by Nanometrics Meridian PH-120 seismometer,
% situated in the basement of Guyot Hall.
%
% This routine is inspired by SeismoRMS, by Thomas Lecocq et. al.,
% https://github.com/ThomasLecocq/SeismoRMS, as well as 
% Lecocq et al., (2020), DOI: 10.1126/science.abd2438
% 
% Last Modified by Yuri Tamama, 11/6/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default values
defval('measval',0);
defval('frequency',[0.5 1.0 20.0 40.0]);

% Do we want displacement, velocity, or acceleration?
vallabelms={'disp';'vel';'acc'};
vallabelmini=vallabelms{measval+1};
valtypes={'none';'vel';'acc'};
valtype=valtypes{measval+1};

% Adjust format and time zone of our inputted times
starttime.Format='eeee dd-MMM-uuuu HH:mm:ss';
starttime.TimeZone=timezone;
finaltime.Format='eeee dd-MMM-uuuu HH:mm:ss';
finaltime.TimeZone=timezone;

% Now, convert start and endtime to UTC, for the sake of processing
% out files
starttimeutc=starttime;
starttimeutc.TimeZone='UTC';
finaltimeutc=finaltime;
finaltimeutc.TimeZone='UTC';

% Total number of hours, inclusive of start and end
hrstotal=hours(finaltimeutc-starttimeutc)+1;

% Initialize the matrix that will contain the rms values in X, Y, H, Z
% If nothing is added to the matrix, it will have a value of -1 
outputmat=-1*ones(hrstotal,4);
% The vector containing the times over which the rms values were found
outputtimes=[];

% Specify directories:
% Store instrument corrected, hourly SAC files
corrdir=fullfile(getenv('MC'),'/nonevtsacpieces/');
% Store non-instrument corrected, hourly SAC files
sacdir=fullfile(getenv('MC'),'/%s/%s/%s');
% Get response files
respdir=getenv('RESP');

% File naming formats
uncorrfmt='PP.S0001.%s.HH%s.%s.%s.%s0000.freqs%s%s%s%s.uncorr.SAC';
corrfmt='PP.S0001.%s.HH%s.%s.%s.%s0000.freqs%s%s%s%s.corr.SAC';
% Strings needed for file names
freqstr1=num2str(frequency(1));
freqstr2=num2str(frequency(2));
freqstr3=num2str(frequency(3));
freqstr4=num2str(frequency(4));

% Component arrays for times with issues or missing SAC files
% in UTC time
probcomps={};
probtvec=[];
mmscomps={};
mmstvec=[];
msccomps={};
msctvec=[];
mdcomps={};
mdtvec=[];

% Iterate through each directional component for each requested day, 
% to find the RMS at every hour
% Again, iterate in UTC!
components={'X';'Y';'Z'};
hourcount=0;
nowtime=starttimeutc;
% Iterate through each hour
while finaltimeutc>=nowtime
  % # of hours we're processing
  hourcount=hourcount+1;
  
  % Add the current hour, in local time, to the vector containing the times
  nowtimetz=nowtime;
  nowtimetz.TimeZone=timezone;
  outputtimes=[outputtimes; nowtimetz];
  
  % Iterate through each component
  xdata=ones(360000,1)*NaN;
  ydata=ones(360000,1)*NaN;

  % Hours before and after the current hour
  utcbefore=nowtime;
  utcbefore.Hour=utcbefore.Hour-1;
  utcafter=nowtime;
  utcafter.Hour=utcafter.Hour+1;

  for c=1:3
    component=components{c};
    
    % Track whether or not we want to "count" a particular value at a
    % particular index in our average 
    counter=zeros(360000,1);    
    
    % Check if the data for the hour before and after exist, or not
    istaper=0;
    % Note: some miniseed files convert to lots of SAC files as opposed to
    % one. In those cases, use the one with the most data
    [sacbef,mdatab,probtimeb,mmstimeb,msctimeb,mdtimeb]=makesac(utcbefore,component);
    [sacnow,mdatan,probtimen,mmstimen,msctimen,mdtimen]=makesac(nowtime,component);
    [sacaft,mdataa,probtimea,mmstimea,msctimea,mdtimea]=makesac(utcafter,component);
    % Add times to problem or missing times array if necessary
    if ~isempty(probtimeb)
      probtvec=[probtvec; probtimeb];
      probcomps=vertcat(probcomps,component);
    end
    if ~isempty(mmstimeb)
      mmstvec=[mmstvec; mmstimeb];
      mmscomps=vertcat(mmscomps,component);
    end
    if ~isempty(msctimeb)
      msctvec=[msctvec; msctimeb];
      msccomps=vertcat(msccomps,component);
    end
    if ~isempty(mdtimeb)
      mdtvec=[mdtvec; mdtimeb];
      mdcomps=vertcat(mdcomps,component);
    end
    %
    if ~isempty(probtimen)
      probtvec=[probtvec; probtimen];
      probcomps=vertcat(probcomps,component);
    end
    if ~isempty(mmstimen)
      mmstvec=[mmstvec; mmstimen];
      mmscomps=vertcat(mmscomps,component);
    end
    if ~isempty(msctimen)
      msctvec=[msctvec; msctimen];
      msccomps=vertcat(msccomps,component);
    end
    if ~isempty(mdtimen)
      mdtvec=[mdtvec; mdtimen];
      mdcomps=vertcat(mdcomps,component);
    end
    %
    if ~isempty(probtimea)
      probtvec=[probtvec; probtimea];
      probcomps=vertcat(probcomps,component);
    end
    if ~isempty(mmstimea)
      mmstvec=[mmstvec; mmstimea];
      mmscomps=vertcat(mmscomps,component);
    end  
    if ~isempty(msctimea)
      msctvec=[msctvec; msctimea];
      msccomps=vertcat(msccomps,component);
    end
    if ~isempty(mdtimea)
      mdtvec=[mdtvec; mdtimea];
      mdcomps=vertcat(mdcomps,component);
    end

    % Do we have data for the present hour?
    if exist(sacnow)==2
      % Do SAC files exist for the hour before and after?
      if (exist(sacbef)==2) && (exist(sacaft)==2)
        % However: if data are missing from the hour before or after
        if mdatab==1 
          % Usable if we have at least 200s and leads continuously into
          % the present hour
          [tdatab,thdrb]=readsac(sacbef,0);
          % Check that we are missing data
          if thdrb.NPTS==360000
            keyboard
          end
          sthr=(thdrb.NZHOUR==utcbefore.Hour);
          sttime=(thdrb.NZMIN*60+thdrb.NZSEC+(thdrb.NZMSEC/1000)<=3400);
          flen=(thdrb.NPTS>=20000);
          ftime=thdrb.NPTS/100;
          % breakpt
          toend=((thdrb.NZMIN*60)+thdrb.NZSEC+(thdrb.NZMSEC/1000)+ftime==3600);
          % If "usable criteria" are not met
          if (sthr+sttime+flen+toend)<4
            istaper=1;
            keyboard
          end
        end
        if mdataa==1
          % Usable if it starts at the hour and has at least 200s of data
          % and starts at the beginning of its hour
          [tdataa,thdra]=readsac(sacaft,0);  
          % Check that we are missing data
          if thdra.NPTS==360000
            keyboard
          end
          sthr=(thdra.NZHOUR==utcafter.Hour);
          stmin=(thdra.NZMIN==0);
          stsec=(thdra.NZSEC==0);
          stmsec=(thdra.NZMSEC)==0;
          flen=(thdra.NPTS>=20000);
          % If "usable criteria" are not met
          % breakpt
          if (sthr+stmin+stsec+stmsec+flen)<5
            istaper=1;
            keyboard
          end
        end
      else
        istaper=1;
      end  
      
      % Note: if data are missing from the present hour, then we really
      % can't add data on either side... 
      if mdatan==1
        istaper=1;
        % Check that we are actually missing data
        [tdatan,thdrn]=readsac(sacnow,0);
        if thdrn.NPTS==360000
          keyboard
        end
      end

    % No
    else
      fprintf('The hourly SAC file in the %s component does not exist.',...
        component)
      fprintf('Moving on!\n')
      % Remove sacbef and sacaft if they exist, so they don't create
      % duplicate SAC files later on
      if exist(fullfile(pwd,sacbef))==2
        [status,cmdout]=system(sprintf('rmm %s',sacbef));
        if status~=0
          keyboard
        end
      end
      if exist(fullfile(pwd,sacaft))==2
        [status,cmdout]=system(sprintf('rmm %s',sacaft));
        if status~=0
          keyboard
        end
      end
      % Move onto the next component
      continue
    end    
    
    % Check if we already have a instrument corrected, filtered SAC file
    % for this hour! If so, skip creating it
    nowyrstr=datenum2str(nowtime.Year,0);
    nowjd=dat2jul(nowtime.Month,nowtime.Day,nowtime.Year);
    nowjdstr=datenum2str(nowjd,1);
    nowhrstr=datenum2str(nowtime.Hour,0);
    % Corrected SAC file name
    corrsac=sprintf(corrfmt,vallabelmini,component,nowyrstr,...
      nowjdstr,nowhrstr,freqstr1,freqstr2,freqstr3,freqstr4); 
    % Uncorrected SAC file name
    uncorrsac=sprintf(uncorrfmt,vallabelmini,component,nowyrstr,...
      nowjdstr,nowhrstr,freqstr1,freqstr2,freqstr3,freqstr4);
    % We can use taper buffers
    % We want 0.05% of the data on either side to act as a buffer
    if istaper==0
      % Specify where to cut the merged SAC file
      if mdatab==1   
        bindex=length(tdatab)-19999;
        bufferstart=(bindex-1)/100;
        bufferend=(length(tdatab)+360000+20000-1)/100;  
        sacstart=bufferstart+200;
        sacend=bufferend-200;
      else
        bufferstart=3400;
        bufferend=7399.99;
        sacstart=3600;
        sacend=7199.99;
      end
        
      % Concatenate the SAC files!
      mergecmd=sprintf(...
        'echo "r %s %s %s ; chnhdr KCMPNM HH%s ; merge ; w %s ; q" | /usr/local/sac/bin/sac',...
         sacbef,sacnow,sacaft,component,uncorrsac);
      [status,cmdout]=system(mergecmd);
      if status~=0
        keyboard
      end
      % Cut the file at the taper buffers and deconvolve signal from 
      % instrument response
      respfile=sprintf('PP.S0001.00.HH%s.resp',component);
      respfile=fullfile(respdir,respfile);
      transfer=sprintf(...
        'transfer from evalresp fname %s to %s freqlimits %g %g %g %g prewhitening on',...
        respfile,valtype,frequency(1),frequency(2),frequency(3),...
        frequency(4));
      corrcmd=sprintf(...
        'echo "r %s ; cut %g %g ; read ; rtr ; rmean ; taper type ; %s ; w %s ; q" | /usr/local/sac/bin/sac',...
        uncorrsac,bufferstart,bufferend,transfer,corrsac);
      [status,cmdout]=system(corrcmd);
      if status~=0
        keyboard
      end
      % Chop off the taper buffer to get our present hour
      cutcmd=sprintf(...
        'echo "r %s ; cut %g %g ; read ; chnhdr B 0 E 3599.99 NZHOUR %d NZJDAY %d  ; w %s ; q" | /usr/local/sac/bin/sac',...
        corrsac,sacstart,sacend,nowtime.Hour,nowjd,corrsac);
      [status,cmdout]=system(cutcmd);
      if status~=0
        keyboard
      end
    
    % Only the data for the current hour are usable
    else
      % Instrument correction
      respfile=sprintf('PP.S0001.00.HH%s.resp',component);
      respfile=fullfile(respdir,respfile);
      transfer=sprintf(...
        'transfer from evalresp fname %s to %s freqlimits %g %g %g %g prewhitening on',...
        respfile,valtype,frequency(1),frequency(2),frequency(3),...
        frequency(4));
      corrcmd=sprintf(...
        'echo "r %s ; rtr ; rmean ; taper type ; %s ; w %s ; q" | /usr/local/sac/bin/sac',...
        sacnow,transfer,corrsac);
      [status,cmdout]=system(corrcmd);
      if status~=0
        keyboard
      end
    end
    % Remove the uncorrected SAC file
    if exist(uncorrsac)==2
      [status,cmdout]=system(sprintf('rmm %s',uncorrsac)); 
      if status~=0
        keyboard
      end
      pause(0.1)
    end
    
    % Variable to check whether we have usable corrected data
    corrsacexist=1;
    % Read the data and compute the RMS
    if exist(corrsac)~=2
      keyboard
    end
    [seisdata,seishdr]=readsac(corrsac,0);
    
    % If there is no taper:
    if istaper==0
      % Check that we have the data for the full hour
      if length(seisdata)<360000
        keyboard
        % Set corrsacxist=0 if necessary
      else
        if c==1
          xdata=seisdata;
        elseif c==2
          ydata=seisdata;
        end
        
        % Check for unaccounted NaN's in the data
        if sum(isnan(seisdata))>0
          keyboard
        end
        
        % Cut out the outliers for that hour
        if length(rmoutlier)>1
          if rmoutlier(1)==0
            prclimit=rmoutlier(2);
            topprc=prctile(abs(seisdata),prclimit);
            % At or above the inputted percentile
            seisdata(abs(seisdata)>=topprc)=NaN;
          else
            seismad=mad(seisdata,1);
            % More than # MADs from the median 
            lowlim=median(seisdata)-seismad*rmoutlier(2);
            highlim=median(seisdata)+seismad*rmoutlier(2);
            seisdata(seisdata<lowlim)=NaN;
            seisdata(seisdata>highlim)=NaN;
          end
        end
        notnan=~isnan(seisdata);
        counter(notnan)=counter(notnan)+1;
        % Square each data point of seismic data, but exclude the
        % signals now corresponding to NaN
        seisdata=seisdata(notnan);
        squareddata=seisdata.^2;
      end
      
    % If there is a taper - data don't necessarily have to be 360000 pts
    % long
    else
      % Cut out the tapered signals, spanning 5% the length of the data
      % at the beginning and end
      taperlen=ceil(0.05*length(seisdata));
      % Redefine counter
      counter=zeros(length(seisdata),1);
      counter=counter(taperlen+1:length(seisdata)-taperlen);
      seisdatanew=seisdata(taperlen+1:length(seisdata)-taperlen);
      % Index to begin X or Y data for computing H
      xyind=(floor(seishdr.NZMIN)*60+floor(seishdr.NZSEC))*100+...
        (floor(seishdr.NZMSEC)/10)+1;
      if xyind-floor(xyind)>0
        keyboard
      end
      if c==1
        xdata(xyind+taperlen:xyind+length(seisdata)-taperlen-1)=seisdatanew;
      elseif c==2
        ydata(xyind+taperlen:xyind+length(seisdata)-taperlen-1)=seisdatanew;
      end
      seisdata=seisdatanew;

      % Cut out the outliers
      if length(rmoutlier)>1
        if rmoutlier(1)==0
          prclimit=rmoutlier(2);
          topprc=prctile(abs(seisdata),prclimit);
          % At or above the inputted percentile
          seisdata(abs(seisdata)>=topprc)=NaN;
        else
          seismad=mad(seisdata,1);
          % More than # MADs from the median (doesn't cut out 
          % signals at +/- # MADs from the median)
          lowlim=median(seisdata)-seismad*rmoutlier(2);
          highlim=median(seisdata)+seismad*rmoutlier(2);
          seisdata(seisdata<lowlim)=NaN;
          seisdata(seisdata>highlim)=NaN;
        end
      end
      notnan=~isnan(seisdata);
      % Do not add 'NaN' values into our average! 
      counter(notnan)=counter(notnan)+1;
      % Square each data point of seismic data, but exclude the
      % signals now corresponding to NaN
      seisdata=seisdata(notnan);
      squareddata=seisdata.^2;
    end
    
    % Compute the horizontal component!
    if c==2
      % Set the values of xdata and ydata equal to NaN but whose 
      % corresponding values in ydata or xdata are not NaN, equal to 0
      xdata(isnan(xdata) & ~isnan(ydata))=0;
      ydata(isnan(ydata) & ~isnan(xdata))=0;
      hdata=sqrt(xdata.^2 + ydata.^2);    
      counterh=zeros(360000,1);   
      % Remove outliers!
      if length(rmoutlier)>1
        if rmoutlier(1)==0
          prclimit=rmoutlier(2);
          topprc=prctile(abs(hdata(~isnan(hdata))),prclimit);
          % At or above the inputted percentile
          hdata(abs(hdata(~isnan(hdata)))>=topprc)=NaN;
        else
          hmad=mad(hdata(~isnan(hdata)),1);
          % More than # MADs from the median (doesn't cut out 
          % signals at +/- 2 MADs from the median)
          lowlimh=median(hdata(~isnan(hdata)))-hmad*rmoutlier(2);
          highlimh=median(hdata(~isnan(hdata)))+hmad*rmoutlier(2);
          hdata(hdata<lowlimh)=NaN;
          hdata(hdata>highlimh)=NaN;
        end
      end
      notnanh=~isnan(hdata);
      if length(notnanh)>length(counterh)
        keyboard
      end
      % Do not add 'NaN' values into our average! 
      counterh(notnanh)=counterh(notnanh)+1;
      % Square each data point of seismic data, but exclude the NaNs
      hdata=hdata(notnanh);
      squaredh=hdata.^2;
    end
        
    % Now: Compute the RMS values of the data for the present hour, if 
    % we have the data
    if corrsacexist==1
      % Only add to the RMS vector if we have values to add
      if sum(counter)>0
        if c<3
          outputmat(hourcount,c)=sqrt(mean(squareddata(~isnan(squareddata))));
        else
          outputmat(hourcount,c+1)=sqrt(mean(squareddata(~isnan(squareddata))));
        end   
      end
    % But if we don't have corrected data to average...
    else
      fprintf('We do not have corrected data for %s UTC\n',...
        datestr(nowtime))
    end
    
    % Compute the RMS horizontal values!
    if c==2
      % If we didn't have usable data in X or Y
      if sum(isnan(hdata))==length(hdata)
      % Otherwise 
      else
        if sum(counterh)>0
          outputmat(hourcount,3)=sqrt(mean(squaredh(~isnan(squaredh))));
        end    
      end
    end
    
    
    % Remove the hourly, uncorrected SAC files
    if exist(fullfile(pwd,sacbef))==2
      [status,cmdout]=system(sprintf('rmm %s',sacbef));
      if status~=0
        keyboard
      end
    end
    if exist(fullfile(pwd,sacnow))==2
      [status,cmdout]=system(sprintf('rmm %s',sacnow));
      if status~=0
        keyboard
      end
    end
    if exist(fullfile(pwd,sacaft))==2
      [status,cmdout]=system(sprintf('rmm %s',sacaft));
      if status~=0
        keyboard
      end
    end 
    % Store away the corrected SAC file!
    [status,cmdout]=system(sprintf('mv %s %s',corrsac,corrdir));  
    if status~=0
      keyboard
    end

  end
  
  % Move onto the next hour
  nowtime.Hour=nowtime.Hour+1;
end


% Now, the output matrix and time vector is complete! 
% Write their values to a table
rmsx=outputmat(:,1);
rmsy=outputmat(:,2);
rmsh=outputmat(:,3);
rmsz=outputmat(:,4);
outputtbl=table(outputtimes,rmsx,rmsy,rmsh,rmsz);
% Construct the file name, in local time
yearstr=num2str(starttime.Year);
startjd=dat2jul(starttime.Month,starttime.Day,starttime.Year);
startjdstr=datenum2str(startjd,1);
finaljd=dat2jul(finaltime.Month,finaltime.Day,finaltime.Year);
finaljdstr=datenum2str(finaljd,1);
% The date we make the CSV file, in local time
todaytime=datetime('now');
todaytime.TimeZone='America/New_York';
todayymd=sprintf('%d%s%s',todaytime.Year,datenum2str(...
  todaytime.Month,0),datenum2str(todaytime.Day,0));
csvfile=sprintf(...
  'RMS%sinNM_HR%sJD%sto%s_%s_F%s%s%s%s_%s',...
  upper(vallabelmini(1)),yearstr,startjdstr,finaljdstr,tzlabel,...
  freqstr1,freqstr2,freqstr3,freqstr4,todayymd);
if length(rmoutlier)>1
  if rmoutlier(1)==0
    csvfile=strcat(csvfile,sprintf('_BTM%d.csv',prclimit));
  else
    csvfile=strcat(csvfile,sprintf('_rmMAD%.2f+.csv',rmoutlier(2)));  
  end    
else
  csvfile=strcat(csvfile,'.csv');
end
% Write to text file
try
  writetable(outputtbl,csvfile);  
  if ~isempty(probtvec) && ~isempty(probcomps)
    probttbl=table(probtvec,probcomps);
    probttbl=unique(probttbl);
    probtimes=sprintf('ProblemMS2SACTimes_%sJD%sto%s_%s.csv',yearstr,...
      startjdstr,finaljdstr,todayymd);
    writetable(probttbl,probtimes);
  else
    probtimes='';
  end
  if ~isempty(mmstvec) && ~isempty(mmscomps)
    missttbl=table(mmstvec,mmscomps);
    missttbl=unique(missttbl);
    mmstimes=sprintf('MissingMSTimes_%sJD%sto%s_%s.csv',yearstr,...
      startjdstr,finaljdstr,todayymd);
    writetable(missttbl,mmstimes);
  else
    mmstimes='';
  end
  if ~isempty(msctvec) && ~isempty(msccomps)
    mscttbl=table(msctvec,msccomps);
    mscttbl=unique(mscttbl);
    msctimes=sprintf('MissingSACnotMSEEDTimes_%sJD%sto%s_%s.csv',yearstr,...
      startjdstr,finaljdstr,todayymd);
    writetable(mscttbl,msctimes);
  else
    msctimes='';
  end
  if ~isempty(mdtvec) && ~isempty(mdcomps)
    mdttbl=table(mdtvec,mdcomps);
    mdttbl=unique(mdttbl);
    mdtimes=sprintf('MissingSACDataTimes_%sJD%sto%s_%s.csv',yearstr,...
      startjdstr,finaljdstr,todayymd);
    writetable(mdttbl,mdtimes);
  else
    mdtimes='';
  end
catch
  keyboard
end


