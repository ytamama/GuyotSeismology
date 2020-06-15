function sacname=makesac(evtdate,component)
% 
% Function to find the miniseed file corresponding to the hour of an 
% inputted event and its component, and subsequently generate a SAC file
% in the current working directory IF such an hourly SAC file does not 
% exist in the current working directory
% 
% INPUTS
% evtdate : A datetime
%           Default: January 1, 2020 at midnight
% component : The directional component of the miniseed file the user 
%             wants converted to SAC
%             e.g. 'X', 'Y', or 'Z'
%             Default: 'X'
% 
% OUTPUT
% sacname : The name of the SAC file that has been generated
%           In the event that the seismometer, when collecting data, 
%           abruptly stops and resumes data collection, multiple SAC 
%           files may be generated for the inputted hour. In that case, 
%           the user will be asked whether or not he/she/they would like 
%           to use the most recently created SAC file.
% 
% References
% Conversion process from .miniseed to SAC from mcms2mat.m and 
% mcms2sac, in csdms-contrib/slepian_oscar
%
% Uses defval.m, in csdms-contrib/slepian_alpha 
% 
% Last Modified by Yuri Tamama, 06/12/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default values
defval('evtdate',datetime('20200101000000','InputFormat',...
    'yyyyMMddHHmmss'));
defval('component','X');

% Search for the miniseed file(s) that may exist
evtyear=num2str(evtdate.Year);
evtmon=datenum2str(evtdate.Month,0);
evtday=datenum2str(evtdate.Day,0);
evthr=datenum2str(evtdate.Hour,0);
% Insert where you keep your miniseed files!
searchdir=fullfile(getenv()); 

% Check if an hourly SAC file exists yet or not in the current 
% working directory first
sacnamefmt='PP.S0001.00.HH%s.D.%s.%s.%s0000.SAC';
% Need JD of the given date (code from mcms2mat.m)
jd=ceil(datenum(evtdate.Year,evtdate.Month,evtdate.Day)-datenum(...
    evtdate.Year,00,00));
jdstr=datenum2str(jd,1); 
% Name of potentially existing SAC file
maybexist=sprintf(sacnamefmt,component,evtyear,jdstr,evthr);
if exist(maybexist)==2
  % Assign to the output, the existing SAC file
  sacname=maybexist;
else
  % Convert .miniseed files to SAC
  % Check for both types of possible .miniseed names
  msname=sprintf(...
    'PP.S0001.00.HH%s_MC-PH1_0248_%s%s%s_%s0000.miniseed',...
                component,evtyear,evtmon,evtday,evthr);
  msname=fullfile(searchdir,msname);   
  msname2=sprintf(...
    'S0001.HH%s_MC-PH1_0248_%s%s%s_%s0000.miniseed',...
                component,evtyear,evtmon,evtday,evthr);
  msname2=fullfile(searchdir,msname2);

  % Convert the .miniseed to SAC if it exists
  if (exist(msname) == 0) && (exist(msname2) == 0)
    error('MINISEED file not found.')   
  elseif exist(msname)==2
    % Convert to SAC using mseed2sac, from mcms2mat.m and mcms2sac
    [~,cmdout]=system(sprintf('mseed2sac %s',msname));
    % Get the name of the SAC file
    % Ask the user for input only if multiple SAC files were generated
    % for that one hour
    cmdcells=strsplit(cmdout);
    sacname=cmdcells{length(cmdcells)-1};
    if length(cmdcells) ~= 6       
      reply=input(sprintf('%s was created. Would you like to use that?',...
        sacname),'s');
      % Return the most recently made SAC file if the user replies 
      % with nothing or with an affirmative. 
      % Otherwise return an empty string
      if strcmpi(reply(1),'Y')==0
        sacname='';
      end
    end   
  else
    % Convert to SAC
    [~,cmdout]=system(sprintf('mseed2sac %s',msname2));
    % Get the name of the SAC file
    % Ask the user for input only if multiple SAC files were generated
    cmdcells=strsplit(cmdout);
    oldname=cmdcells{length(cmdcells)-1}; 
    if length(cmdcells) ~= 15       
      reply=input(sprintf('%s was created. Would you like to use that?',...
        oldname),'s');
      % Return an empty string if the user replies in the negative
      if strcmpi(reply(1),'Y')==0
        oldname='';
        sacname='';
      end
    end   
  
    % This miniseed file has the issue where the network name is not 
    % defined... Let's fix that if we made the SAC file
    if ~isempty(oldname)
      % Rename SAC file
      partname=oldname(10:length(oldname)); 
      sacname=sprintf('PP.S0001.00%s',partname);
      [~,cmdout]=system(sprintf('mv %s %s',oldname,sacname));
      % Fix the network name
      [seisdata,header,~,~,~]=readsac(sacname,0);
      header.KNETWK='PP';  
      if isfield(header,'KHOLE')
        header.KHOLE='00';
      end
      % Write to new SAC file
      writesac(seisdata,header,sacname);  
    end
  end
end

