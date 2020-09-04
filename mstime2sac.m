function [sacfiles,figurehdl]=mstime2sac(measval,starttime,finaltime,...
  frequency,makeplot,saveplot,savedir)
% 
% Function to generate SAC files, one per directional component, of 
% seismic data spanning a time interval (from starttime to finaltime).
% The SAC files will contain seismic data from the Meridian Compact PH1
% seismometer, a broadband nanometrics three component seismometer, 
% situated in the basement of Guyot Hall in Princeton University. 
% The data will be deconvolved from the instrument response and filtered
% at the requested frequency range.
%
% INPUTS
% measval : What do we want for the signal?
%           0 for displacement in nm (default if left empty)
%           1 for velocity in nm/s 
%           2 for acceleration in nm/(s^2)
% starttime : What time, in UTC, do we wish to start our signal?
% finaltime : What time, in UTC, do we wish to end our signal?
% frequency : The frequencies at which we wish to filter the data
%             Enter as a four-element vector 
%             Default: [0.01 0.02 10.00 20.00] Hz
% savedir : Where do you want to save your SAC files?
%           Default: in your 'MC' directory!
% makeplot : Make a plot of the selected interval?
%            0 for no (default if left empty)
%            1 for yes
% saveplot : Do we want to save our plot?
%            0 - No (default)
%            1 - Yes 
% plotdir : Where do we save our plot? By default, it will be saved in 
%           your 'EPS' directory!
% 
% OUTPUTS
% sacfiles : A cell array of the SAC files outputted
% figurehdl : If plotting, the figure handle of the resulting plot
% 
% References:
% Code to access SAC commands from MATLAB from mcms2mat.m,
% in csdms-contrib/slepian_oscar
%
% Uses dat2jul.m, in csdms-contrib/slepian_oscar
%
% Uses defval.m in csdms-contrib/slepian_alpha 
% 
% Consulted the SAC manual, from http://ds.iris.edu/files/sac-manual/
% 
% Last Modified by Yuri Tamama, 09/02/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('measval',0);
defval('frequency',[0.01 0.02 10.00 20.00]);
defval('makeplot',0);
defval('saveplot',0);

% Initialize cell array to save the names of the resulting SAC files
sacfiles={};

% What will our SAC files measure?
if measval==1
  valtype='vel';
  valtype2='vel';
elseif measval==2
  valtype='acc';
  valtype2='acc';
else
  valtype='none';  
  valtype2='disp';
end

% Directories - Insert your own!
sacdir=getenv('');
% Place to save the final corrected SAC piece
if isempty(savedir)
  savedir=sacdir;
end
% Uncorrected SAC pieces
intdir=fullfile(sacdir,'');
% Response files
respfmt='PP.S0001.00.HH%s.resp';
respfmt=fullfile(getenv(''),respfmt);

% Note how long our time series should be, and add a buffer to either side!
% This buffer will be affected by the taper during instrument correction, 
% and can be removed so the taper does not affect the data
totaltime=seconds(finaltime-starttime);
totaltimestr=num2str(round(totaltime,0));
% Buffer start time
buffertime=ceil((1/15)*(totaltime)); 
prebuffer=starttime;
prebuffer.Second=prebuffer.Second-buffertime;
% Buffer end time
postbuffer=finaltime;
postbuffer.Second=postbuffer.Second+buffertime;

% Strings for naming SAC files
% Start time
yearstr=num2str(starttime.Year);
hrstr=datenum2str(starttime.Hour,0);   
minstr=datenum2str(starttime.Minute,0);     
secstr=datenum2str(floor(starttime.Second),0);   
jdstr=datenum2str(dat2jul(starttime.Month,starttime.Day,starttime.Year),1);
% Frequencies
freqstr1=num2str(frequency(1));
freqstr2=num2str(frequency(2));
freqstr3=num2str(frequency(3));
freqstr4=num2str(frequency(4));

% Iterate through each component to generate SAC files
components={'Z';'Y';'X'};
nextcomp=0;
for c=1:3
  component=components{c};
  % File names to use later
  uncorrpiece=sprintf(...
    'PP.S0001.%s.%ss.HH%s.%s.%s.%s%s%s.%s%s%s%s.uc.SAC',...
    valtype2,totaltimestr,component,yearstr,jdstr,hrstr,minstr,...
    secstr,freqstr1,freqstr2,freqstr3,freqstr4);
  corrpiece=sprintf(...
    'PP.S0001.%s.%ss.HH%s.%s.%s.%s%s%s.%s%s%s%s.cr.SAC',...
    valtype2,totaltimestr,component,yearstr,jdstr,hrstr,minstr,...
    secstr,freqstr1,freqstr2,freqstr3,freqstr4);
  
  % Do we need 1 hourly miniseed/SAC or more?
  hrspassed1=ceil(hours(postbuffer-prebuffer));
  hrspassed2=postbuffer.Hour-prebuffer.Hour;
  if (postbuffer.Hour==0)&&(prebuffer.Hour==23)
    hrspassed2=1;  
  end
  hrspassed=max(hrspassed1,hrspassed2);
  if (postbuffer.Hour==prebuffer.Hour) && floor(hours(postbuffer-prebuffer))==0
    hrspassed=0;
  end
  % Need these to put away hourly SAC files, later
  hrsacfiles=cell(hrspassed+1,1);
  sacsavedirs=cell(hrspassed+1,1);
  % 1 hour
  if hrspassed<1
    % Place to save the SAC files, excluding the resulting pieces
    sacfilesave=fullfile(sacdir,...
      datestr(datenum(starttime.Year,starttime.Month,...
      starttime.Day),'yyyy/mm/dd'));
    % Create the hourly SAC file
    sacname=makesac(starttime,component);
    % If no SAC file was created, exit the function
    if isempty(sacname)
      timetext=sprintf('%s/%s/%s %s:00:00',yrstr,...
        datenum2str(starttime.Month,0),datenum2str(starttime.Day,0),hrstr);
      fprintf('A SAC file could not be created for %s in %s. ',...
        timetext,component)
      continue
    else      
      hrsacfiles{1}=sacname;
      sacsavedirs{1}=sacfilesave;
      % Find where to trim the SAC file
      bufferstart=(prebuffer.Minute*60)+prebuffer.Second;
      bufferend=(postbuffer.Minute*60)+postbuffer.Second;  
      uncorrpiece=sacname;
    end
  % More than 1 hourly miniseed/SAC  
  else
    % Iterate through each hour between the start of the taper 
    % buffer to the end of it, encompassing the interval
    mcdate=prebuffer;
    readcmd='r %s';
    for i=1:hrspassed+1
      % Generate hourly SAC file
      sacname=makesac(mcdate,component);
      % If no SAC file was created, exit the function
      timetext=sprintf('%s/%s/%s %s:00:00 %s',num2str(mcdate.Year),...
        datenum2str(mcdate.Month,0),datenum2str(mcdate.Day,0),...
        datenum2str(mcdate.Hour),component);
      if isempty(sacname)
        fprintf('A SAC file could not be created for %s in %s.',...
          timetext,component)
        break
      end      
      % Construct a SAC command to read those files
      readcmd=sprintf(readcmd,sacname);
      if i<(hrspassed+1)
        readcmd=strcat(readcmd,' %s');   
      end
      % Move onto the next hour
      mcdate.Hour=mcdate.Hour+1;
      sacfilesave=fullfile(sacdir,...
        datestr(datenum(mcdate.Year,mcdate.Month,mcdate.Day),...
          'yyyy/mm/dd'));
      sacsavedirs{i}=sacfilesave;
      hrsacfiles{i}=sacname;
    end
    if nextcomp==1
      nextcomp=0;
      continue
    end
    
    % Merge the SAC files!
    % Accessing SAC from MATLAB from mcms2mat.m
    mergecmd=sprintf(...
      'echo "%s ; merge ; w %s ; q" | /usr/local/sac/bin/sac',...
      readcmd,uncorrpiece);
    [status,cmdout]=system(mergecmd);
    % Where to cut merged file to taper buffers
    bufferstart=(prebuffer.Minute*60)+prebuffer.Second;
    bufferend=(postbuffer.Minute*60)+postbuffer.Second+3600*hrspassed;      
  end    
  
  % Cut the SAC file at the taper buffers, and instrument correct!
  respfile=sprintf(respfmt,component);
  transfer=sprintf(...
    'transfer from evalresp fname %s to %s freqlimits %g %g %g %g prewhitening on',...
    respfile,valtype,frequency(1),frequency(2),frequency(3),frequency(4));
  corrcmd=sprintf(...
    'echo "r %s ; cut %g %g ; read ; rtr ; rmean ; taper type ; %s ; w %s ; q" | /usr/local/sac/bin/sac',...
    uncorrpiece,bufferstart,bufferend,transfer,corrpiece);
  [status,cmdout]=system(corrcmd);
  
  % Cut off the taper buffers and adjust header
  startpt=bufferstart+seconds(starttime-prebuffer);
  endpt=startpt+totaltime;
  newend=endpt-startpt;
  cutcmd=sprintf(...
    'echo "r %s ; cut %g %g ; read ; chnhdr B 0 E %g ; w %s ; q" | /usr/local/sac/bin/sac',...
    corrpiece,startpt,endpt,newend,corrpiece);
  [status,cmdout]=system(cutcmd);
  % New header variables
  hdrsec=floor(starttime.Second/1);
  hdrmsec=round(mod(starttime.Second,1)*1000);
  hdrchange=sprintf(...
    'chnhdr NZJDAY %d NZHOUR %d NZMIN %d NZSEC %d NZMSEC %d',...
    dat2jul(starttime.Month,starttime.Day,starttime.Year),...
    starttime.Hour,starttime.Minute,hdrsec,hdrmsec);
  hdrcmd=sprintf(...
    'echo "r %s ; %s ; w %s ; q" | /usr/local/sac/bin/sac',...
    corrpiece,hdrchange,corrpiece);
  [status,cmdout]=system(hdrcmd);
  % Save the hourly SAC files, in their proper arrays
  for i=1:length(hrsacfiles)
    hourlysac=hrsacfiles{i};
    hourlydir=sacsavedirs{i};
    [status,cmdout]=system(sprintf('mv %s %s',hourlysac,hourlydir));
  end
  % Save the SAC pieces, corrected and uncorrected
  if hrspassed>=1
    [status,cmdout]=system(sprintf('mv %s %s',uncorrpiece,intdir));
  end
  [status,cmdout]=system(sprintf('mv %s %s',corrpiece,savedir));
  % Add the name of the final SAC piece to the cell array
  corrpiece=fullfile(savedir,corrpiece);
  sacfiles=vertcat(sacfiles,corrpiece); 
end    

% If we're making a plot
if makeplot==1
  % Plot from Z, Y, X
  plotorder=[1 2 3];
  % plotsacdata!
  [figurehdl,~,~]=plotsacdata(1,sacfiles,plotorder,3,measval,frequency,...
    [],'','',100,1,0,saveplot,savedir,0);
else
  figurehdl='';
end
