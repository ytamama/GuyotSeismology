function sacname=makesac(evtdate,component)
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
% sacname : The name of the SAC file that has been generated
%           In the event that the seismometer, when collecting data, 
%           abruptly stops and resumes data collection, multiple SAC 
%           files may be generated for the inputted hour. In that case, 
%           the program will attempt to concatenate those SAC files 
%           and return the resulting product.
%           If, for whatever reason, a complete hourly SAC file with no 
%           missing data cannot be made, then an empty string will be 
%           returned in place of the SAC file's name
% 
% References
% Conversion process from .miniseed to SAC from mcms2mat.m and 
% mcms2sac, in csdms-contrib/slepian_oscar
% 
% Uses writesac.m and dat2jul.m, in csdms-contrib/slepian_oscar
%
% Uses defval.m, in csdms-contrib/slepian_alpha 
% 
% Last Modified by Yuri Tamama, 07/10/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set default values
defval('evtdate',datetime('20200101000000','InputFormat',...
    'yyyyMMddHHmmss'));
defval('component','X');

% Search for the miniseed file(s) that may exist
evtyearstr=num2str(evtdate.Year);
evtmonstr=datenum2str(evtdate.Month,0);
evtdaystr=datenum2str(evtdate.Day,0);
evthrstr=datenum2str(evtdate.Hour,0);

% Insert your own directory for:
% Where you store miniseed files
searchdir=''; 
% Where you sequester SAC files we may never need 
rfdir='';

% Check if an hourly SAC file exists yet or not 
sacnamefmt='PP.S0001.00.HH%s.D.%s.%s.%s0000.SAC';
% Directory where the SAC file may already exist
% Insert your own directory!
sacsearchdir=''; 
% Need JD of the given date 
jd=dat2jul(evtdate.Month,evtdate.Day,evtdate.Year);
jdstr=datenum2str(jd,1); 
% Name of potentially existing SAC files
maybexist=sprintf(sacnamefmt,component,evtyearstr,jdstr,evthrstr);
maybexist=fullfile(sacsearchdir,maybexist);
maybexist2=sprintf(sacnamefmt,component,evtyearstr,jdstr,evthrstr);
if exist(maybexist)==2 
  % Assign to the output, the existing SAC file
  sacname=maybexist;
elseif exist(maybexist2)==2
  sacname=maybexist2;  
else
  % Convert .miniseed files to SAC
  % Check for both types of possible .miniseed names
  msname=sprintf(...
    'PP.S0001.00.HH%s_MC-PH1_0248_%s%s%s_%s0000.miniseed',...
                component,evtyearstr,evtmonstr,evtdaystr,evthrstr);
  msname=fullfile(searchdir,msname);   
  msname2=sprintf(...
    'S0001.HH%s_MC-PH1_0248_%s%s%s_%s0000.miniseed',...
                component,evtyearstr,evtmonstr,evtdaystr,evthrstr);
  msname2=fullfile(searchdir,msname2);

  % Convert the .miniseed to SAC if it exists
  if (exist(msname) == 0) && (exist(msname2) == 0)
    dispdate=sprintf('%s/%s/%s %s:00:00',evtyearstr,evtmonstr,evtdaystr,evthrstr);
    fprintf('MINISEED file not found for %s. Exiting function.',...
        dispdate);   
    sacname='';
    return
  elseif exist(msname)==2
    % Convert to SAC using mseed2sac, from mcms2mat.m and mcms2sac
    [~,cmdout]=system(sprintf('mseed2sac %s',msname));
    % Get the name of the SAC file
    cmdcells=strsplit(cmdout);
    % If multiple files were generated, try to concatenate them together
    if length(cmdcells) ~= 6    
      problemtime=sprintf('%s/%s/%s %s:00:00',evtyearstr,evtmonstr,evtdaystr,evthrstr);
      fprintf('Multiple SAC files were made for %s. These files will be concatenated.',...
          problemtime);
      % Names of SAC files are in the indices divisible by 5
      indices=1:length(cmdcells);
      indicesdiv5=indices(mod(indices,5)==0);
      sacnames=cmdcells(indicesdiv5);
      % Combine the data of these SAC files 
      [newdata,newhdr]=combinesacpieces(sacnames,evtdate,component);
      % Sequester SAC pieces to a "recycle" directory
      [status,cmdout]=system(sprintf('mv PP.S0001.*.SAC %s',rfdir));
      % Note: if the data in newdata are all NaN, then the data are unusable
      % (see combinesacpieces.m)
      if mean(isnan(newdata))==1
        disp('Data are missing from this hour and are thus unusable. Exiting function.')
        sacname='';
        return
      end      
      % Write to new SAC file
      sacname=sprintf(sacnamefmt,component,evtyearstr,jdstr,evthrstr);
      writesac(newdata,newhdr,sacname);
    else
      % Even if one file is made, that file may be missing data
      % Compare the SAC file name with one that should be made if 
      % the file were not missing data    
      sacname=cmdcells{length(cmdcells)-1};
      sacnamemdl=sprintf(sacnamefmt,component,evtyearstr,jdstr,evthrstr);
      if strcmp(sacname,sacnamemdl)==0
        disp('The SAC file has missing data. It is not usable.')
        sacname='';
        return        
      end
    end   
  else
    % Convert to SAC
    [~,cmdout]=system(sprintf('mseed2sac %s',msname2));
    % Get the name of the SAC file
    cmdcells=strsplit(cmdout);
    % If multiple files were generated, try to concatenate them together
    if length(cmdcells) ~= 15    
      problemtime=sprintf('%s/%s/%s %s:00:00',evtyearstr,evtmonstr,evtdaystr,evthrstr);
      fprintf('Multiple SAC files were made for %s. These files will be concatenated.',...
          problemtime);
      % Names of SAC files are in the indices divisible by 14
      indices=1:length(cmdcells);
      indicesdiv14=indices(mod(indices,14)==0);
      sacnames=cmdcells(indicesdiv14);
      % Combine the data 
      [newdata,newhdr]=combinesacpieces(sacnames,evtdate,component);
      % Sequester SAC pieces to a "recycle" directory
      [status,cmdout]=system(sprintf('mv XX.S0001..*.SAC %s',rfdir));   
      % Note: if the data in newdata are all NaN, then the data are unusable
      % (see combinesacpieces.m)
      if mean(isnan(newdata))==1
        disp('Data are missing from this hour and are thus unusable. Exiting function.')
        sacname='';
        return
      end
      % Edit the header to add the network name!
      newhdr.KNETWK='PP';  
      if isfield(newhdr,'KHOLE')
        newhdr.KHOLE='00';
      end     
      % Write to new SAC file
      sacname=sprintf(sacnamefmt,component,evtyearstr,jdstr,evthrstr);
      writesac(newdata,newhdr,sacname);
      oldname='';
    else
      % Even if one file is made, that file may be missing data
      oldname=cmdcells{length(cmdcells)-1}; 
      oldnamefmt='XX.S0001..HH%s.D.%s.%s.%s0000.SAC';
      oldnamemdl=sprintf(oldnamefmt,component,evtyearstr,jdstr,evthrstr);
      if strcmp(oldname,oldnamemdl)==0
        disp('The SAC file has missing data. It is not usable.')
        sacname='';
        return        
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

