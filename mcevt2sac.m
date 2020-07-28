function corrpieces=mcevt2sac(rowdata,measval,swortime,intend,frequency,...
    makeplot,saveplot,addphases)
%
% Function that takes in a row of IRIS catalog data, generated by 
% mcms2evt, and finds the .miniseed files that may contain the event, 
% recorded by the S0001 seismometer in the Guyot Hall network, PP.
% Then, the function converts that .miniseed file into a SAC file and 
% trims the SAC file into an interval ranging from the approximate 
% origin time of the event to a specified end time
%
% Note: This function uses the SAC command 'cut' to trim SAC files
% down to the desired interval. An alternate version of this function,
% mcevt2sac_mat.m, reads the SAC file into MATLAB and cuts the file 
% there. However, that alternate version is experiencing issues due 
% to rounding issues in MATLAB (SAC's header variables are 
% single-precision, but MATLAB tries to convert them to double-precision). 
% 
% INPUTS
% rowdata : One row of IRIS catalog data, created by mcms2evt
%           Columns (left to right): eventID, date of event (string),
%           event latitude, event longitude, depth, event magnitude,
%           geoid distance from station to event (degrees), Great Circle
%           distance from station to event (degrees), and the predicted 
%           travel time of one seismic phase to Guyot Hall (seconds)
% measval : What do we want for the signal?
%           0 for displacement in nm (default if left empty)
%           1 for velocity in nm/s 
%           2 for acceleration in nm/(s^2)
% swortime : Are we inputting a time, in seconds, or a surface wave speed
%            to define where we end our time interval?
%            1 - Time (Default)
%            2 - Surface wave speed 
% intend : Either:    
%          1) A time, in seconds, at which to end the SAC file 
%             Default: 7200 seconds
%          2) A "low threshold" for the surface wave speeds (km/s). The 
%             epicentral distance divided by this speed gives a benchmark
%             for how long the time-series should be. 
%             Default: 2.5 km/s  
% frequency : The frequencies to which the data will be filtered during
%             instrument correction
%             Default: [0.01 0.02 10.00 20.00] Hz
% makeplot : Make a plot of the selected interval?
%            0 for no (default if left empty)
%            1 for yes
% saveplot : Do we want to save our plot?
%            0 - No (default)
%            1 - Yes 
% addphases : Do we want to add seismic phases and their predicted
%             travel times to our plot?
%             0 - No (default)
%             1 - Yes 
% 
% OUTPUT(S)
% corrpieces : The instrument corrected SAC pieces, containing data 
%              for the chosen interval surrounding the event's approximate 
%              arrival time. Returns a cell array containing empty strings
%              if data are missing from the requested interval.
%              To be consistent with other programs using output from 
%              this program, the SAC files will be returned in the order:
%              {'Z';'Y';'X'}
%
% Also returns a plot of those SAC pieces, if requested
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
% Last Modified by Yuri Tamama, 07/28/2020
% 
% See makesac.m, plotsacdata.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('swortime',1);
if swortime==1
  defval('intend',7200);
else
  defval('intend',2.5);
end
defval('measval',0);
defval('frequency',[0.01 0.02 10.00 20.00]); 
defval('makeplot',0);
defval('saveplot',0);
defval('addphases',0);

% Initialize cell array to save the names of the instrument 
% corrected SAC pieces
corrpieces={};

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
sacpiecesave=fullfile(sacdir,'');
% Uncorrected SAC pieces
intdir=fullfile(sacdir,'');
% Response files
respfmt='PP.S0001.00.HH%s.resp';
respfmt=fullfile(getenv(''),respfmt);
% Save plot
plotdir=fullfile(sacdir,'');

% Compute the end time of our chosen interval
% Also add a buffer on either side of the interval. This buffer will 
% be affected by the taper during instrument correction, and can be 
% removed so the taper does not affect the data
% 
% Event origin time
evtdatestr=rowdata.Var2;
evtdatestr=evtdatestr{1};
evttime=datetime(evtdatestr,'InputFormat','yyyyMMddHHmmss');
evtyear=evttime.Year;
evtmon=evttime.Month;
evtday=evttime.Day;
evthr=evttime.Hour;
evtmin=evttime.Minute;
evtsec=evttime.Second;
evtjd=dat2jul(evtmon,evtday,evtyear);
% Convert origin times to strings, for naming files
yearstr=num2str(evtyear);
hrstr=datenum2str(evthr,0);   
minstr=datenum2str(evtmin,0);     
secstr=datenum2str(floor(evtsec),0);   
jdstr=datenum2str(evtjd,1);
% Figure out how long the time series should last
if swortime==2
  evlalo=[rowdata.Var3 rowdata.Var4];
  [~,~,~,distmtr]=irisazimuth(evlalo);
  distkm=distmtr/1000;
  totaltime=round(distkm/intend,2);
  totaltime=totaltime;
else
  totaltime=intend;
end
% Interval end time
posttime=evttime;
posttime.Second=posttime.Second+totaltime;
% Buffer start time
buffertime=ceil((1/15)*(totaltime)); 
prebuffer=evttime;
prebuffer.Second=evttime.Second-buffertime;
prebuffhr=prebuffer.Hour;
prebuffmin=prebuffer.Minute;
prebuffsec=prebuffer.Second;  
% Buffer end time
postbuffer=posttime;
postbuffer.Second=posttime.Second+buffertime;
postbuffhr=postbuffer.Hour;
postbuffmin=postbuffer.Minute;
postbuffsec=postbuffer.Second;
% Interval Lengths
inttotal2=num2str(seconds(postbuffer-prebuffer));
inttotalstr=num2str(totaltime);

% Other strings needed for naming files
% Frequencies
freqstr1=num2str(frequency(1));
freqstr2=num2str(frequency(2));
freqstr3=num2str(frequency(3));
freqstr4=num2str(frequency(4));
% Event ID
evtstr=num2str(rowdata.Var1); 
    
% Iterate through each component to generate SAC pieces
components={'Z';'Y';'X'};
nextcomp=0;
for c=1:3
  component=components{c};
  % File names to use later
  uncorrpiece=sprintf(...
    'PP.S0001.%s.%s.HH%s.%s.%s.%s%s%s.%s%s%s%s.uc.SAC',...
    evtstr,valtype2,component,yearstr,jdstr,hrstr,minstr,...
    secstr,freqstr1,freqstr2,freqstr3,freqstr4);
  corrpiece=sprintf(...
    'PP.S0001.%s.%s.HH%s.%s.%s.%s%s%s.%s%s%s%s.cr.SAC',...
    evtstr,valtype2,component,yearstr,jdstr,hrstr,minstr,...
    secstr,freqstr1,freqstr2,freqstr3,freqstr4);
  
  % Do we need 1 hourly miniseed/SAC or more?
  hrspassed1=ceil(hours(postbuffer-prebuffer));
  hrspassed2=postbuffhr-prebuffhr;
  if (postbuffhr==0)&&(prebuffhr==23)
    hrspassed2=1;  
  end
  hrspassed=max(hrspassed1,hrspassed2);
  if (postbuffhr==prebuffhr) && floor(hours(postbuffer-prebuffer))==0
    hrspassed=0;
  end
  % Need these to put away hourly SAC files, later
  hrsacfiles=cell(hrspassed+1,1);
  sacsavedirs=cell(hrspassed+1,1);
  % 1 hour
  if hrspassed<1
    % Place to save the SAC files, excluding the resulting pieces
    sacfilesave=fullfile(sacdir,'');
    % Create the hourly SAC file
    sacname=makesac(evttime,component);
    % If no SAC file was created, exit the function
    if isempty(sacname)
      timetext=sprintf('%s/%s/%s %s:00:00',datenum2str(evtyear,0),...
        datenum2str(evtmon,0),datenum2str(evtday,0),datenum2str(evthr,0));
      fprintf('A SAC file could not be created for %s in %s. ',...
        timetext,component)
      continue
    else      
      hrsacfiles{1}=sacname;
      sacsavedirs{1}=sacfilesave;
      % Find where to cut the SAC file
      bufferstart=(prebuffmin*60)+prebuffsec;
      bufferend=(postbuffmin*60)+postbuffsec;  
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
        % Go to the next component
        nextcomp=1;
        break
      end      
      % Construct a SAC command to read those files
      readcmd=sprintf(readcmd,sacname);
      if i<(hrspassed+1)
        readcmd=strcat(readcmd,' %s');   
      end
      % Move onto the next hour
      mcdate.Hour=mcdate.Hour+1;
      sacfilesave=fullfile(sacdir,'');
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
    bufferstart=(prebuffmin*60)+prebuffsec;
    bufferend=(postbuffmin*60)+postbuffsec+3600*hrspassed;      
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
  startpt=bufferstart+seconds(evttime-prebuffer);
  endpt=startpt+totaltime;
  newend=endpt-startpt;
  cutcmd=sprintf(...
    'echo "r %s ; cut %g %g ; read ; chnhdr B 0 E %g ; w %s ; q" | /usr/local/sac/bin/sac',...
    corrpiece,startpt,endpt,newend,corrpiece);
  [status,cmdout]=system(cutcmd);
  % New header variables
  hdrsec=floor(evtsec/1);
  hdrmsec=round(mod(evtsec,1)*1000);
  hdrevla=round(rowdata.Var3,1);
  hdrevlo=round(rowdata.Var4,1);
  hdrevdp=round(rowdata.Var5,1);
  hdrmag=round(rowdata.Var6,1);
  hdrchange=sprintf(...
    'chnhdr NZJDAY %d NZHOUR %d NZMIN %d NZSEC %d NZMSEC %d EVLA %g EVLO %g EVDP %g MAG %g LCALDA TRUE',...
    evtjd,evthr,evtmin,hdrsec,hdrmsec,hdrevla,hdrevlo,hdrevdp,hdrmag);
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
  [status,cmdout]=system(sprintf('mv %s %s',corrpiece,sacpiecesave));
  % Add the name of the final SAC piece to the cell array
  corrpiece=fullfile(sacpiecesave,corrpiece);
  corrpieces=vertcat(corrpieces,corrpiece); 
end    

% If we're making a plot
if makeplot==1
  evtid=rowdata.Var1;
  evtlat=rowdata.Var3;
  evtlon=rowdata.Var4;
  evlalo=[evtlat evtlon];
  depth=rowdata.Var5;
  magnitude=rowdata.Var6;
  % Plot from Z, Y, X
  plotorder=[1 2 3];

  % Add phases?
  if addphases==0
    plotsacdata(1,corrpieces,plotorder,3,measval,frequency,...
      [],'','',100,[],0,saveplot,'mat',plotdir,1,evtid,magnitude,...
      evlalo,depth);
  else
    evlalo=[rowdata.Var3 rowdata.Var4];
    ttimetbl=iristtimes(evlalo,depth,'');
    phasenames=ttimetbl.Var1;
    arrtimes=ttimetbl.Var2;
    plotsacdata(1,corrpieces,plotorder,3,measval,frequency,...
      [],'','',100,[],0,saveplot,'mat',plotdir,1,evtid,magnitude,...
      evlalo,depth,phasenames,arrtimes);    
  end
end

