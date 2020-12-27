function [corrfiles,figurehdl]=mstime2sac(measval,startutc,finalutc,...
  frequency,rmoutlier,savedir,makeplot,saveplot,plotdir)
% 
% Function to generate SAC files, one per directional component, of 
% seismic data spanning a time interval (from starttime to finaltime).
% The SAC files will contain seismic data from the Nanometrics Meridian 
% PH-120 seismometer, situated in the basement of Guyot Hall in Princeton 
% University. 
%
% INPUTS
% measval : What do we want for the signal?
%           0 for displacement in nm (default if left empty)
%           1 for velocity in nm/s 
%           2 for acceleration in nm/(s^2)
% startutc : What time, in UTC, do we wish to start our signal?
% finalutc : What time, in UTC, do we wish to end our signal?
% frequency : The frequencies at which we wish to filter the data
%             Enter as a four-element vector 
%             Default: [0.01 0.02 10.00 20.00] Hz
% rmoutlier :  If plotting our values, how should we define and remove our
%              outliers?
%
%              0 - Use a percentage limit. For every SAC file, we remove
%                  signals that are at or above this percentile. 
%                  Enter a two number vector, with 0 as the first element
%                  and the percentile limit as the second.
%              1 - Remove outliers that are more than a certain number of
%                  median standard deviations (MAD) away from the median. 
%                  Enter a 2 number vector, with 1 as the first element 
%                  and the # of MADs as the second, like this:
%                  [1 3] - remove signals at least 3 MADs away from the
%                          median for every SAC file
% 
%              Input an empty array if we don't want to remove any signals
%              (default)
% savedir : Where do you want to save your SAC files?
%           Default: In the current working directory
% makeplot : Make a plot of the selected interval?
%            0 for no (default if left empty)
%            1 for yes
% saveplot : Do we want to save our plot?
%            0 - No (default)
%            1 - Yes 
% plotdir : Where do we save our plot? By default, it will be saved in 
%           your current working directory
% 
% OUTPUTS
% corrfiles : A cell array of the SAC files outputted, in order from 
%             Z (vertical), Y (North-South), and X (East-West)
% figurehdl : If plotting, the figure handle of the resulting plot
% 
% References:
% Learned how to access SAC commands from MATLAB from mcms2mat.m,
% in csdms-contrib/slepian_oscar
% Uses dat2jul.m, jul2dat.m, readsac.m, in csdms-contrib/slepian_oscar
% Uses defval.m in csdms-contrib/slepian_alpha 
% Consulted the SAC manual, from http://ds.iris.edu/files/sac-manual/
%
% For more on SAC, see Helffrich et al., (2013), The Seismic Analysis 
% Code: a Primer and User's Guide
% 
% Last Modified by Yuri Tamama, 12/27/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('measval',0);
defval('frequency',[0.01 0.02 10.00 20.00]);
defval('rmoutlier',[]);
defval('makeplot',0);
defval('saveplot',0);
defval('savedir',pwd);
defval('plotdir',pwd);

% Initialize cell array to save the names of the resulting SAC files
corrfiles={};

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

% Place where you keep your data
sacdir=getenv('MC');
% Response files
respfmt='PP.S0001.00.HH%s.resp';
respfmt=fullfile(getenv('RESP'),respfmt);

% Note how long our time series should be, and add a buffer to either side!
% This buffer will be affected by the taper during instrument correction, 
% and can be removed so the taper does not affect the data we want
totaltime=seconds(finalutc-startutc);
totaltimestr=num2str(round(totaltime,0));
% Buffer start time
% Calculated so that removing 10% total from the time we want + buffer
% leaves us with the time we want! 
buffertime=ceil((1/18)*(totaltime)); 
prebuffer=startutc;
prebuffer.Second=prebuffer.Second-buffertime;
% Buffer end time
postbuffer=finalutc;
postbuffer.Second=postbuffer.Second+buffertime;


% Strings for naming SAC files
% Start time
yearstr=num2str(startutc.Year);
hrstr=datenum2str(startutc.Hour,0);   
minstr=datenum2str(startutc.Minute,0);     
secstr=datenum2str(floor(startutc.Second),0);   
jdstr=datenum2str(dat2jul(startutc.Month,startutc.Day,startutc.Year),1);
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
    upper(valtype2(1)),totaltimestr,component,yearstr,jdstr,hrstr,minstr,...
    secstr,freqstr1,freqstr2,freqstr3,freqstr4);
  corrpiece=sprintf(...
    'PP.S0001.%s.%ss.HH%s.%s.%s.%s%s%s.%s%s%s%s.cr.SAC',...
    upper(valtype2(1)),totaltimestr,component,yearstr,jdstr,hrstr,minstr,...
    secstr,freqstr1,freqstr2,freqstr3,freqstr4);
  
  % Do we need 1 hourly miniseed/SAC or more?
  hrspassed1=ceil(hours(postbuffer-prebuffer));
  hrspassed2=postbuffer.Hour-prebuffer.Hour;
  if (postbuffer.Hour==0)&&(prebuffer.Hour==23)
    hrspassed2=1;  
  end
  hrdiff=max(hrspassed1,hrspassed2);
  if (postbuffer.Hour==prebuffer.Hour) && floor(hours(postbuffer-prebuffer))==0
    hrdiff=0;
  end
  
  % Need these to put away hourly SAC files, later
  hrsacfiles={};
  sacsavedirs={};
  % Variables that tracks whether we need a buffer (nobuffer=0) or cannot
  % use one (nobuffer=1)
  nobuffer=0;
  % 1 hour
  if hrdiff<1
    % Place to save the SAC files, excluding the resulting pieces
    sacfilesave=fullfile(sacdir,...
      datestr(datenum(startutc.Year,startutc.Month,...
      startutc.Day),'yyyy/mm/dd'));
    % Create the hourly SAC file
    % Edit to account for changes in makesac
    [sacname,~,~,~,~,~]=makesac(startutc,component);
    % If no SAC file was created, exit the function
    if exist(sacname)==0
      timetext=sprintf('%s/%s/%s %s:00:00',yrstr,...
        datenum2str(startutc.Month,0),datenum2str(startutc.Day,0),hrstr);
      fprintf('A SAC file could not be created for %s in %s. ',...
        timetext,component)
      continue
    else      
      hrsacfiles=vertcat(hrsacfiles,sacname);
      sacsavedirs=vertcat(sacsavedirs,sacfilesave);
      % Check whether we have enough data for these buffers, or at
      % least the interval itself
      [testdata,testhdr]=readsac(sacname,0);
      stmdy=jul2dat(testhdr.NZYEAR,testhdr.NZJDAY);
      sttime=datetime(testhdr.NZYEAR,stmdy(1),stmdy(2),...
        testhdr.NZHOUR,testhdr.NZMIN,testhdr.NZSEC+(testhdr.NZMSEC/1000));
      sttime.TimeZone='UTC';
      fintime=sttime;
      fintime.Second=fintime.Second+(testhdr.NPTS/100);
      % If our SAC file cuts into the interval we actually want
      if sttime>startutc || fintime<finalutc
        fprintf('We do not have enough data for this interval\n')
        if sttime>startutc
          fprintf('Choose an interval starting after %s\n',datestr(sttime))
        elseif fintime<finalutc
          fprintf('Choose an interval ending before %s\n',datestr(fintime)) 
        end
        fprintf('Moving onto the next component\n')
        continue
      % If our SAC file starts after or ends before the buffer time  
      elseif sttime>prebuffer || fintime<postbuffer 
        nobuffer=1;
        fprintf('We cannot have a buffer for this interval.\n')
        % Specify where to cut the SAC file
        startpt=seconds(startutc-sttime);
        endpt=startpt+totaltime;
      elseif sttime<=prebuffer && fintime>=postbuffer
        % Specify the buffers + where to cut the SAC file
        bufferstart=seconds(prebuffer-sttime);
        bufferend=seconds(postbuffer-sttime);
        startpt=seconds(startutc-sttime);
        endpt=startpt+totaltime;
      end    
      uncorrpiece=sacname;
    end
  % More than 1 hourly miniseed/SAC  
  else
    % Iterate through each hour between the start of the taper 
    % buffer to the end of it, encompassing the interval
    mcdate=prebuffer;
    readcmd='r %s';
    for i=1:hrdiff+1
      sacfilesave=fullfile(sacdir,...
        datestr(datenum(mcdate.Year,mcdate.Month,mcdate.Day),...
        'yyyy/mm/dd'));
      % Generate hourly SAC file
      [sacname,~,~,~,~,~]=makesac(mcdate,component);
      % If no SAC file was created, exit the function
      timetext=sprintf('%s/%s/%s %s:00:00 %s',num2str(mcdate.Year),...
        datenum2str(mcdate.Month,0),datenum2str(mcdate.Day,0),...
        datenum2str(mcdate.Hour),component);
      if exist(sacname)~=2
        fprintf('A SAC file could not be created for %s in %s.',...
          timetext,component)
        % But if this is the prebuffer or postbuffer hour... we'll just
        % have to go ahead with no buffer
        if mcdate.Hour<startutc.Hour || mcdate.Hour>finalutc.Hour
          fprintf('We cannot have a buffer for this interval.\n')
          nobuffer=1;
        % But if one of our present, non-buffer hours are missing, 
        % we should quit
        elseif mcdate.Hour>=startutc.Hour && mcdate.Hour<=finalutc.Hour
          fprintf('We do not have enough data for this interval in %s\n',...
            component)
          fprintf('Moving onto the next component\n')
          nextcomp=1;
          break
        end
      else
        [testdata,testhdr]=readsac(sacname,0);  
        % Check if:
        % Case A : Hour is before the final hour but the data do not 
        % lead continuously into the next hour
        if i<hrdiff+1
          ftime=testhdr.NPTS/100;
          toend=((testhdr.NZMIN*60)+testhdr.NZSEC+(testhdr.NZMSEC/1000)+ftime==3600);
          if toend<1
            fprintf('Data are cut off at the end before the final hour\n')
            nextcomp=1;
            break
          end
        % Case B : Hour is after the first hour, but the data are
        % cut off at the beginning
        end
        if i>1
          stmin=(testhdr.NZMIN==0);
          stsec=(testhdr.NZSEC==0);
          stmsec=(testhdr.NZMSEC==0);
          if (stmin+stsec+stmsec)<3
            fprintf('Data are cut off at the beginning after the starting hour\n')
            nextcomp=1;
            break
          end
        end
        % Case C : This is the first SAC file but the data begin past 
        % the prebuffer time
        % Also check if the data begin after the start time
        if i==1
          stmdy=jul2dat(testhdr.NZYEAR,testhdr.NZJDAY);
          sthr=testhdr.NZHOUR;
          stmin=testhdr.NZMIN;
          stsec=testhdr.NZSEC+(testhdr.NZMSEC/1000);
          sttime=datetime(testhdr.NZYEAR,stmdy(1),stmdy(2),...
            sthr,stmin,stsec);
          sttime.TimeZone='UTC';
          if sttime>startutc
            fprintf('Choose an interval starting after %s\n',datestr(sttime))
            nextcomp=1;
            break
          elseif sttime>prebuffer
            fprintf('We cannot use a buffer for this seismogram\n')
            nobuffer=1;
          end   
          % Keep the header information of the first file
          sthdr=testhdr;  
        end
        % Case D : this is the last SAC file but the data cut off before
        % the postbuffer hour
        % Also check if the data are cut off before the final hour
        if i==hrdiff+1
          stmdy=jul2dat(testhdr.NZYEAR,testhdr.NZJDAY);
          sthr=testhdr.NZHOUR;
          stmin=testhdr.NZMIN;
          stsec=testhdr.NZSEC+(testhdr.NZMSEC/1000);
          sttime=datetime(testhdr.NZYEAR,stmdy(1),stmdy(2),...
            sthr,stmin,stsec);
          sttime.TimeZone='UTC';
          tlen=(testhdr.NPTS-1)/100;
          fintime=sttime;
          fintime.Second=fintime.Second+tlen;
          if fintime<finalutc
            fprintf('Choose an interval ending before %s\n',datestr(fintime))   
            nextcomp=1;
            break
          elseif fintime<postbuffer
            fprintf('We cannot use a buffer for this seismogram\n')
            nobuffer=1;
          end 
          % Keep the header information of the last file
          finhdr=testhdr;
        end    
        % If the data are good to go, add to the SAC files array
        sacsavedirs=vertcat(sacsavedirs,sacfilesave);
        hrsacfiles=vertcat(hrsacfiles,sacname);
      end   
      % Move onto the next hour
      mcdate.Hour=mcdate.Hour+1;
    end
    if nextcomp==1
      nextcomp=0;
      continue
    end
    
    % Before moving on, check whether we need to "throw out" SAC files
    % exclusive to the buffer, if we're progressing with no buffer
    if nobuffer==1
      newfiles={};
      newsavedirs={};
      for f=1:length(hrsacfiles)
        tempsac=hrsacfiles{f};
        % If this is within the hour(s) we ultimately want
        if temphdr.NZHOUR>=startutc.Hour && temphdr.NZHOUR<=finalutc.Hour
          newfiles=vertcat(newfiles,tempsac);
          newsavedirs=vertcat(newsavedirs,sacsavedirs{f});
        else
          % Remove this SAC file
          % Note: 'rm' is set so that it asks for input, and 'rmm' is set
          % to act like the default 'rm'
          [status,cmdout]=system(sprintf('rmm %s',tempsac));
        end
      end  
      hrsacfiles=newfiles;
      sacsavedirs=newsavedirs;
    end
    hrdiff=length(hrsacfiles)-1;
    
    % Construct a SAC command to read our files
    if hrdiff>=1
      for i=1:hrdiff+1
        sacname=hrsacfiles{i};  
        readcmd=sprintf(readcmd,sacname);
        if i<(hrdiff+1)
          readcmd=strcat(readcmd,' %s');   
        end
      end  
    end
    
    % Merge the SAC files!
    % Accessing SAC from MATLAB from mcms2mat.m
    if hrdiff>=1 
      mergecmd=sprintf(...
        'echo "%s ; merge ; w %s ; q" | /usr/local/sac/bin/sac',...
        readcmd,uncorrpiece);
      [status,cmdout]=system(mergecmd);
    % If we end up not needing to merge anything, due to missing files, 
    % set uncorrpiece equal to the SAC file we have
    else
      uncorrpiece=hrsacfiles{1};
    end
    
    % Figure out where to cut our SAC files
    % When do our data start?
    stmdy=jul2dat(sthdr.NZYEAR,sthdr.NZJDAY);
    datasttime=datetime(sthdr.NZYEAR,stmdy(1),stmdy(2),...
      sthdr.NZHOUR,sthdr.NZMIN,sthdr.NZSEC+(sthdr.NZMSEC/1000));
    datasttime.TimeZone='UTC';
    % If using a taper buffer
    if nobuffer==0
      bufferstart=seconds(prebuffer-datasttime);
      bufferend=seconds(postbuffer-datasttime);
    end
    startpt=seconds(startutc-datasttime);
    endpt=startpt+totaltime;    
  end    
  
  % Cut the SAC file at the taper buffers, and instrument correct!
  respfile=sprintf(respfmt,component);
  transfer=sprintf(...
    'transfer from evalresp fname %s to %s freqlimits %g %g %g %g prewhitening on',...
    respfile,valtype,frequency(1),frequency(2),frequency(3),frequency(4));
  
  if nobuffer==0
    % Where to cut merged file to taper buffers
    % When do our data start?
    corrcmd=sprintf(...
      'echo "r %s ; cut %g %g ; read ; rtr ; rmean ; taper type ; %s ; w %s ; q" | /usr/local/sac/bin/sac',...
      uncorrpiece,bufferstart,bufferend,transfer,corrpiece);
  else
    corrcmd=sprintf(...
      'echo "r %s ; read ; rtr ; rmean ; taper type ; %s ; w %s ; q" | /usr/local/sac/bin/sac',...
      uncorrpiece,transfer,corrpiece);
  end
  [status,cmdout]=system(corrcmd);
  
  % Cut off the taper buffers and adjust header
  newend=endpt-startpt;
  cutcmd=sprintf(...
    'echo "r %s ; cut %g %g ; read ; chnhdr B 0 E %g ; w %s ; q" | /usr/local/sac/bin/sac',...
    corrpiece,startpt,endpt,newend,corrpiece);
  [status,cmdout]=system(cutcmd);
  % New header variables
  hdrsec=floor(startutc.Second/1);
  hdrmsec=round(mod(startutc.Second,1)*1000);
  hdrchange=sprintf(...
    'chnhdr NZJDAY %d NZHOUR %d NZMIN %d NZSEC %d NZMSEC %d',...
    dat2jul(startutc.Month,startutc.Day,startutc.Year),...
    startutc.Hour,startutc.Minute,hdrsec,hdrmsec);
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
  % Remove the uncorrected SAC piece
  if hrdiff>=1
    [status,cmdout]=system(sprintf('rmm %s',uncorrpiece));
    pause(0.5)
  end
  % Move the corrected SAC file unless we want the file in the 
  % current working directory
  if ~strcmp(savedir,pwd) && ~isempty(savedir)
    [status,cmdout]=system(sprintf('mv %s %s',corrpiece,savedir));
    corrpiece=fullfile(savedir,corrpiece);
  end
  % Add the name of the final SAC piece to the cell array
  corrfiles=vertcat(corrfiles,corrpiece); 
end    

% If we're making a plot
if makeplot==1
  if isempty(corrfiles)
    disp('No SAC files will be plotted because data do not exist.')
    figurehdl='';
    return
  end
  freqinfo={frequency};
  corder={'Z';'Y';'X'};
  spinfo={3; [1 2 3]; {'r';'g';'b'}};
  stainfo={[];[];[];[]};
  stalbl=0;
  evtinfo={0;[];[]};
  timeinfo={0;[];[]};
  % Use plotsacdata.m 
  if ~isempty(plotdir)
    [figurehdl,~,~]=plotsacdata(1,corrfiles,measval,freqinfo,corder,spinfo,...
    stainfo,rmoutlier,stalbl,saveplot,plotdir,evtinfo,timeinfo);
  else
    [figurehdl,~,~]=plotsacdata(1,corrfiles,measval,freqinfo,corder,spinfo,...
    stainfo,rmoutlier,stalbl,saveplot,pwd,evtinfo,timeinfo);
  end
else
  figurehdl='';
end
