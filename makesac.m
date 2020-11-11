function [sacname,mdata,probtime,mmstime,msctime,mdtime]=makesac(evtdate,...
  component)
% 
% Function to find the miniseed file corresponding to the hour of an 
% inputted event and its component, and subsequently generate a SAC file
% if such an hourly SAC file does not exist 
% 
% INPUTS
% evtdate : A datetime in UTC
%           Default: January 1, 2020 at midnight
% component : The directional component of the miniseed file the user 
%             wants converted to SAC
%             e.g. 'X', 'Y', or 'Z'
%             Default: 'X'
% 
% OUTPUTS
% sacname : The name of the SAC file that has been generated (located
%           in the current working directory)
%           If, for whatever reason, an hourly SAC file cannot be made,
%           then an empty string will be returned in place of the SAC 
%           file's name
% mdata : Is the SAC file missing data? We might obtain a SAC file for
%            a given hour, but this file may be missing data.
%            0 : No data missing
%            1 : Yes, data are missing
% probtime : If the entered time corresponds to a miniseed file that 
%            converts to multiple SAC files, due to GPS connection issues,
%            return this time in UTC. An empty vector is returned otherwise.
% mmstime : If the entered time corresonds to a miniseed file that does
%           not exist, this datetime is returned in UTC. An empty vector
%           is returned otherwise.
% msctime : If an hourly miniseed file exists, but the hourly SAC file
%           somehow does not, return this datetime in UTC. An empty vector
%           is returned otherwise. 
% mdtime : If a returned hourly SAC file is incomplete (i.e. missing
%          data from that hour), return this datetime in UTC. An empty
%          vector is returned otherwise.
% 
% References
% Conversion process from .miniseed to SAC is from from mcms2mat.m and 
% mcms2sac, in csdms-contrib/slepian_oscar
% Accessing SAC from MATLAB is from mcms2mat.m in 
% csdms-contrib/slepian_oscar
% Uses readsac.m and dat2jul.m, in csdms-contrib/slepian_oscar
% Uses defval.m, in csdms-contrib/slepian_alpha 
% 
% The seismic data are recorded by Nanometrics Meridian PH-120 seismometer,
% situated in the basement of Guyot Hall.
%
% For more on SAC, see Helffrich et al., (2013), The Seismic Analysis 
% Code: a Primer and User's Guide
% 
% Last Modified by Yuri Tamama, 10/15/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default values
defval('evtdate',datetime('20200101000000','InputFormat',...
    'yyyyMMddHHmmss'));
defval('component','X');
defval('sacprop',[])

% Search for the miniseed file(s) that may exist
evtdate.Minute=0;
evtdate.Second=0;
evtyearstr=num2str(evtdate.Year);
evtmonstr=datenum2str(evtdate.Month,0);
evtdaystr=datenum2str(evtdate.Day,0);
evthrstr=datenum2str(evtdate.Hour,0);

% Insert your own directory for:
% Where you store miniseed files
searchdir=fullfile(getenv('MC0'),sprintf('%s/%s/%s',...
  evtyearstr,evtmonstr,evtdaystr)); 

% Check if an hourly SAC file exists yet or not 
mdata=0;
sacname='';
sacnamefmt='PP.S0001.00.HH%s.D.%s.%s.%s0000.SAC';
% Need JD of the given date 
evtjd=dat2jul(evtdate.Month,evtdate.Day,evtdate.Year);
jdstr=datenum2str(evtjd,1); 

% Convert .miniseed files to SAC
% Check for both types of possible .miniseed names
msname=sprintf(...
  'PP.S0001.00.HH%s_MC-PH1_0248_%s%s%s_%s0000.miniseed',component,...
  evtyearstr,evtmonstr,evtdaystr,evthrstr);
msname=fullfile(searchdir,msname);   
msname2=sprintf('S0001.HH%s_MC-PH1_0248_%s%s%s_%s0000.miniseed',...
  component,evtyearstr,evtmonstr,evtdaystr,evthrstr);
msname2=fullfile(searchdir,msname2);

% If the miniseed does not exist, exit function
% keyboard
if (exist(msname) == 0) && (exist(msname2) == 0)
  fprintf('MINISEED file not found for %s. Exiting function.\n',...
    datestr(evtdate)); 
  probtime=[];
  mdtime=[];
  msctime=[];
  mmstime=evtdate;
  sacname='';
  return
    
% Miniseed file with the network name exists
elseif exist(msname)==2
  mmstime=[];
  % Convert to SAC using mseed2sac, from mcms2mat.m and mcms2sac
  [status,cmdout]=system(sprintf('mseed2sac %s',msname));
  if status~=0
    keyboard
  end
  % Get the name of the SAC file
  cmdcells=strsplit(cmdout);
  % If multiple files were generated, alert the user
  % keyboard
  if length(cmdcells) ~= 6   
    mdtime=[];
    msctime=[];
    if length(cmdcells)<6
      keyboard
    end
    if length(cmdcells)<11
      keyboard
    end
    probtime=evtdate;
    % Names of SAC files are in the indices divisible by 5
    indices=1:length(cmdcells);
    indicesdiv5=indices(mod(indices,5)==0);
    sacnames=cmdcells(indicesdiv5);
      
    % Alert the user
    fprintf('Multiple SAC files were made from mseed2sac, so the hour %s will be skipped\n',...
      datestr(evtdate))
    sacname='';
    
    % Remove SAC pieces 
    for s=1:length(sacnames)
      tempsac=sacnames{s};
      if exist(tempsac)==2
        [status,cmdout]=system(sprintf('rmm %s',tempsac));
        if status~=0
          keyboard
        end
        pause(0.05)
      end
    end
    return
 
  % If mseed2sac returns 1 SAC file
  else
    probtime=[];
    sacname=cmdcells{length(cmdcells)-1};
    sacnamemdl=sprintf(sacnamefmt,component,evtyearstr,jdstr,evthrstr);
    % Check whether the SAC file starts/ends on the hour expected, is
    % missing any data, etc. 
    % keyboard
    if strcmp(sacname,sacnamemdl)==0
      % Two cases:
      % 1) We made a duplicate SAC file in the same directory, in which
      % case sacnamemdl should exist
      %
      % 2) We don't have a duplicate SAC file, but rather a SAC file
      % that begins at 59 min. 59.999 seconds of the previous hour.
      if exist(sacname)==2
        msctime=[];
        [testdata,testhdr]=readsac(sacname);
        filemdy=jul2dat(testhdr.NZYEAR,testhdr.NZJDAY);
        filedate=datetime(testhdr.NZYEAR,filemdy(1),filemdy(2),...
          testhdr.NZHOUR,testhdr.NZMIN,testhdr.NZSEC+(testhdr.NZMSEC/1000));
        filedate.TimeZone='UTC';
        filedate2=filedate;
        filedate.Second=filedate.Second+0.001;

        % If the below criteria are satisfied, then we have Case II
        if (length(testdata)==360000) && (filedate==evtdate)
          if evtdate.Hour==0
            % Change the date
            chtime=sprintf(...
              'chnhdr NZJDAY %d NZHOUR 0 NZMIN 0 NZSEC 0 NZMSEC 0 B 0',...
              evtjd);   
          else
            chtime=sprintf(...
              'chnhdr NZHOUR %d NZMIN 0 NZSEC 0 NZMSEC 0 B 0',...
              evtdate.Hour);
          end
          chcmd=sprintf(...
            'echo "r %s ; %s ; w %s ; q" |  /usr/local/sac/bin/sac',...
            sacname,chtime,sacnamemdl); 
          [status,cmdout]=system(chcmd);
          if status~=0
            keyboard
          end
          % Remove the old SAC file
          [status,cmdout]=system(sprintf('rmm %s',sacname));
          if status~=0
            keyboard
          end
          % Add break point
          sacname=sacnamemdl;
          mdtime=[];
          return
          
        % If the file has 360000 points then we likely have a duplicate
        % SAC file: Case I
        elseif (length(testdata)==360000) 
          % Add break point
          if filedate2~=evtdate || exist(sacnamemdl)==0
            keyboard
          end
          % Remove the old SAC file
          [status,cmdout]=system(sprintf('rmm %s',sacname));
          if status~=0
            keyboard
          end
          sacname=sacnamemdl;
          mdtime=[];
          return
            
        % Otherwise, we don't have 360000 points, so the file is likely
        % missing data
        else
          mdtime=evtdate;
          % Return this SAC file, but set the missing data variable
          % equal to 1
          mdata=1;
          % Check that this isn't a duplicate SAC file
          if length(testdata)==360000
            keyboard
          end
          % Add break point
        end   
      else
        % If no such SAC file exists
        msctime=evtdate;
        mdtime=[];
        sacname='';
        return
      end
    % Otherwise, if we got the expected hourly SAC file:
    else
      % If the SAC file does not exist
      if exist(sacname)==0
        msctime=evtdate;
        mdtime=[];
        sacname='';
        return
      end
      % Check if all the data for the hour are present
      [testdata,testhdr]=readsac(sacname,0);
      msctime=[];
      % Check the hour
      if testhdr.NZHOUR~=evtdate.Hour
        keyboard
      end
      if length(testdata)==360000
        mdtime=[];
      else
        mdtime=evtdate;
        % Return this SAC file, but set the missing data variable
        % equal to 1
        mdata=1;
      end
    end
  end
    
% Miniseed exists, but is missing the network name
else
  mmstime=[];
  % Convert to SAC
  [status,cmdout]=system(sprintf('mseed2sac %s',msname2));
  if status~=0
    keyboard
  end    
  % Get the name of the SAC file
  cmdcells=strsplit(cmdout);
  % If multiple files were generated, alert the user
  if length(cmdcells) ~= 15    
    if length(cmdcells)<15
      keyboard
    end
    mdtime=[];
    msctime=[];
    probtime=evtdate; 
    % Names of SAC files are in the indices divisible by 14
    indices=1:length(cmdcells);
    indicesdiv14=indices(mod(indices,14)==0);
    sacnames=cmdcells(indicesdiv14);
      
    % Alert the user
    fprintf('Multiple SAC files were made from mseed2sac, so the hour %s will be skipped\n',...
      datestr(evtdate))
    sacname='';
      
    % Remove SAC pieces
    for s=1:length(sacnames)
      tempsac=sacnames{s};
      if exist(tempsac)==2 
        [status,cmdout]=system(sprintf('rmm %s',tempsac));
        if status~=0
          keyboard
        end
        pause(0.05)
      end
    end
    return
      
  % 1 SAC file is returned
  else
    probtime=[];
    % Check whether the SAC file starts/ends on the hour expected, is
    % missing any data, etc. 
    oldname=cmdcells{length(cmdcells)-1}; 
    oldnamefmt='XX.S0001..HH%s.D.%s.%s.%s0000.SAC';
    oldnamemdl=sprintf(oldnamefmt,component,evtyearstr,jdstr,evthrstr);
      
    if strcmp(oldname,oldnamemdl)==0
      % Two cases:
      % 1) We made a duplicate SAC file in the same directory, in which
      % case sacnamemdl should exist
      %
      % 2) We don't have a duplicate SAC file, but rather a SAC file
      % that begins at 59 min. 59.999 seconds of the previous hour.
      if exist(oldname)==2
        msctime=[];
        [testdata,testhdr]=readsac(oldname,0);
        filemdy=jul2dat(testhdr.NZYEAR,testhdr.NZJDAY);
        filedate=datetime(testhdr.NZYEAR,filemdy(1),filemdy(2),...
          testhdr.NZHOUR,testhdr.NZMIN,testhdr.NZSEC+(testhdr.NZMSEC/1000));
        filedate.TimeZone='UTC';
        filedate2=filedate;
        filedate.Second=filedate.Second+0.001;
        % If the above criteria are satisfied, remake adjust the SAC
        % file to fix the time
        if (length(testdata)==360000) && (filedate==evtdate)
          mdtime=[];
          if evtdate.Hour==0
            % Change the date
            chtime=sprintf(...
              'chnhdr NZJDAY %d NZHOUR 0 NZMIN 0 NZSEC 0 NZMSEC 0 B 0 E 3599.99',...
              evtjd);   
          else
            chtime=sprintf(...
              'chnhdr NZHOUR %d NZMIN 0 NZSEC 0 NZMSEC 0 B 0 E 3599.99',...
              evtdate.Hour);
          end
          chcmd=sprintf(...
            'echo "r %s ; %s ; w %s ; q" |  /usr/local/sac/bin/sac',...
            oldname,chtime,oldnamemdl); 
          [status,cmdout]=system(chcmd);
          if status~=0
            keyboard
          end
          % Remove the old SAC file
          [status,cmdout]=system(sprintf('rmm %s',oldname));
          if status~=0
            keyboard
          end
          oldname=oldnamemdl;
            
        % If the file has 360000 points then we likely have a duplicate
        % SAC file
        elseif (length(testdata)==360000) 
          % Add break point
          if filedate2~=evtdate || exist(oldnamemdl)==0
            keyboard
          end
          % Remove the old SAC file
          [status,cmdout]=system(sprintf('rmm %s',oldname));
          if status~=0
            keyboard
          end
          oldname=oldnamemdl;
          mdtime=[];
            
        % Otherwise, we don't have 360000 points, so the file is likely
        % missing data
        else
          mdtime=evtdate;
          % Return this SAC file, but set the missing data variable
          % equal to 1
          mdata=1;
          % Check that this isn't a duplicate SAC file
          if length(testdata)==360000
            keyboard
          end
          % Add break point
        end 
             
      else
        % If no such SAC file exists
        msctime=evtdate;
        mdtime=[];
        sacname='';
        return
      end
        
    % If the file is named as we expect, check if the data contain all
    % 360000 points
    else
      % Check if the SAC file exists
      if exist(oldname)==0
        msctime=evtdate;
        mdtime=[];
        sacname='';
        return
      end
      [testdata,testhdr]=readsac(oldname,0);
      msctime=[];
      if testhdr.NZHOUR~=evtdate.Hour
        keyboard
      end
      if length(testdata)==360000
        mdtime=[];
      else
        mdtime=evtdate;
        % Return this SAC file, but set the missing data variable
        % equal to 1
        mdata=1;
      end
    end   
  end   
    
  % This miniseed file has the issue where the network name is not 
  % defined... Let's fix that if we made the SAC file
  if ~isempty(oldname)
    % Rename SAC file
    partname=oldname(10:length(oldname)); 
    sacname=sprintf('PP.S0001.00%s',partname);
    % Rename the SAC file
    [status,cmdout]=system(sprintf('mv %s %s',oldname,sacname));
    if status~=0
      keyboard
    end
    % Fix the network name
    netwk=sprintf(...
      'echo "r %s ; chnhdr KNETWK ''PP'' KHOLE ''00'' ; w %s ; q" |  /usr/local/sac/bin/sac',...
      oldname,sacname);    
    [status,cmdout]=system(netwk);
    if status~=0
      keyboard
    end
  end
end


% Check that our SAC file starts within and ends within the current
% hour
[sacdata,sachdr]=readsac(sacname,0);
% Start within this hour
if sachdr.NZHOUR~=evtdate.Hour
  % If it doesn't it should be earlier than the hour
  if sachdr.NZHOUR>evtdate.Hour
    keyboard
  end
  sacmdy=jul2dat(sachdr.NZYEAR,sachdr.NZJDAY);
  sactime=datetime(sachdr.NZYEAR,sacmdy(1),sacmdy(2),...
    sachdr.NZHOUR,sachdr.NZMIN,sachdr.NZSEC+(sachdr.NZMSEC/1000));
  sactime.TimeZone='UTC';
  % breakpt
  sacb=seconds(evtdate-sactime);
  cutcmd=sprintf(...
    'echo "r %s ; cut %g E ; read ; w %s ; q" | /usr/local/sac/bin/sac',...
    sacname,sacb,sacname);
  % breakpt
  [status,cmdout]=system(cutcmd);
  if status~=0
    keyboard
  end
  hdrcmd=sprintf(...
    'echo "r %s ; chnhdr B 0 ; wh ; q" | /usr/local/sac/bin/sac',...
    sacname);
  [status,cmdout]=system(hdrcmd);
  if status~=0
    keyboard
  end
  [sacdata,sachdr]=readsac(sacname,0);
end
  
% End within this hour
ftime=sachdr.NPTS/100;
fst=(sachdr.NZMIN*60)+sachdr.NZSEC+(sachdr.NZMSEC/1000);
% breakpt
if fst+ftime>3600
  keyboard
  sace=3600-fst;
  % First, make sure header.B is set to 0
  hdrcmd=sprintf(...
    'echo "r %s ; chnhdr B 0 ; wh ; q" | /usr/local/sac/bin/sac',...
    sacname);
  [status,cmdout]=system(hdrcmd);  
  if status~=0
    keyboard
  end
  cutcmd=sprintf(...
    'echo "r %s ; cut B B %g ; read ; w %s ; q" | /usr/local/sac/bin/sac',...
    sacname,sace,sacname);
  % breakpt
  [status,cmdout]=system(cutcmd);
  if status~=0
    keyboard
  end
  hdrcmd2=sprintf(...
    'echo "r %s ; chnhdr E 3599.99 ; wh ; q" | /usr/local/sac/bin/sac',...
    sacname);
  [status,cmdout]=system(hdrcmd2);
  if status~=0
    keyboard
  end
end

if exist(sacname)~=2
  keyboard
end
[sacdata,sachdr]=readsac(sacname,0);
if sachdr.NPTS<360000
  mdata=1;
  mdtime=evtdate;
elseif sachdr.NPTS==360000
  mdata=0;
end



