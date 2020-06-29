function [newdata,newhdr]=combinesacpieces(sacnames,evtdate,component)
%
% Occasionally, one miniseed file, containing 1 hour's worth of data, 
% converts  to multiple SAC files, each with a fraction of an hour of data
% This program aims to ameliorate this problem by taking in the names 
% of those SAC files produced during the miniseed to SAC conversion
% and concatenates the data of those files into one continuous dataset.
%
% Note: This code accounts for the case where the data for 
% the beginning of the hour is missing, thus making it necessary to 
% generate (a) SAC file(s) of the previous hour
% 
% Note 2: If NaN's still remain in the data even after concatenation, this 
% means data is missing from that particular hour. For now, we'll say 
% we cannot use this hour. The outputted array of data will be all NaN, 
% to serve as an indicator for that outcome.
% 
% INPUT
% sacnames : Cell array containing the names of the SAC files, produced 
%            during a problematic miniseed to SAC conversion
% evtdate : A datetime, with the hour corresponding to the inputted 
%           SAC files
%
% OUTPUTS
% newdata  : The concatenated SAC data. 
% newhdr   : The new header for the concatenated SAC data
% 
% References
% Conversion process from .miniseed to SAC from mcms2mat.m and 
% mcms2sac, in csdms-contrib/slepian_oscar
% 
% Use of readsac.m, also in csdms-contrib/slepian_oscar
% 
% Last Modified by Yuri Tamama, 06/28/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Directories we may need - insert your own!
% Directory storing miniseed files
msdir=getenv('');
% Directory to "recycle files" afterwards (not toss them, in case 
% we need them later)
rfdir=getenv('');

numfiles=length(sacnames);
newdata=NaN(360000,1);
[~,newhdr]=readsac(sacnames{1});
% Iterate through the SAC files and concatenate their data
for i=1:numfiles
  sacfile=sacnames{i};
  [tempdata,hdr]=readsac(sacfile);
  startind=((60*hdr.NZMIN)+hdr.NZSEC)*100+hdr.NZMSEC+1;
  newdata(startind:startind+length(tempdata)-1)=tempdata;  
end
% Crop to 360,000 points, in case of excess
newdata=newdata(1:360000);

% If the start of newdata is NaN, that means we need the SAC file
% from the previous hour, contain the data from this hour
if isnan(newdata(1))
  disp('Data is missing from the start of the hour.')
  disp('We will search for this data from the SAC file(s) of the previous hour.')
  
  % First, check how many values are continuously NaN from the start
  nancount=0;
  for i=1:length(newdata)
    if isnan(newdata(i))
      nancount=nancount+1;
    end
    if i<length(newdata) 
      if ~isnan(newdata(i+1))
        break
      end
    end
  end
  
  % Try to get the SAC file for the previous hour
  prevdate=evtdate;
  prevdate.Hour=prevdate.Hour-1;
  prevyear=num2str(prevdate.Year);
  prevmon=datenum2str(prevdate.Month,0);
  prevday=datenum2str(prevdate.Day,0);
  prevhr=datenum2str(prevdate.Hour,0);
  % Directory to search miniseed files
  searchdir=fullfile(msdir,sprintf('%s/%s/%s',...
    prevyear,prevmon,prevday));   

  % Find the miniseed file
  % Use the miniseed files applicable to your network!
  msname=sprintf(...
    'PP.S0001.00.HH%s_MC-PH1_0248_%s%s%s_%s0000.miniseed',...
                component,prevyear,prevmon,prevday,prevhr);
  msname=fullfile(searchdir,msname);   
  msname2=sprintf(...
    'S0001.HH%s_MC-PH1_0248_%s%s%s_%s0000.miniseed',...
                component,prevyear,prevmon,prevday,prevhr);
  msname2=fullfile(searchdir,msname2);
  if (exist(msname) == 0) && (exist(msname2) == 0)
    warning('No miniseed file exists for the previous hour.')
    warning('Missing data will be populated with zeroes.')
  elseif exist(msname)==2
    % Convert miniseed to SAC (from mcms2mat.m and mcms2sac)
    [~,cmdout]=system(sprintf('mseed2sac %s',msname)); 
    cmdcells=strsplit(cmdout);
    % If multiple SAC files were made
    if length(cmdcells) ~= 6  
      indices=1:length(cmdcells);
      indicesdiv5=indices(mod(indices,5)==0);
      prevfiles=cmdcells(indicesdiv5);
      % The array is preset but can be expanded if we have more data...
      % which is what we're after!
      prevdata=NaN(360000,1);
      for i=1:length(prevfiles)
        prevsac=prevfiles{i};
        [tempdata,hdr]=readsac(prevsac);
        startind=((60*hdr.NZMIN)+hdr.NZSEC)*100+hdr.NZMSEC+1;
        prevdata(startind:startind+length(tempdata)-1)=tempdata;
        % 'Recycle' the SAC file when we're done
        [~,cmdout]=system(sprintf('mv %s %s',prevsac,rfdir));        
      end
    else
      prevsac=cmdcells{length(cmdcells)-1};
      [prevdata,~]=readsac(prevsac,0);
      % 'Recycle' the SAC file
      [~,cmdout]=system(sprintf('mv %s %s',prevsac,rfdir));      
    end    
  else
    % Convert miniseed to SAC (from mcms2mat.m and mcms2sac)
    [~,cmdout]=system(sprintf('mseed2sac %s',msname2)); 
    cmdcells=strsplit(cmdout);
    % If multiple SAC files were made
    if length(cmdcells) ~= 15  
      indices=1:length(cmdcells);
      indicesdiv14=indices(mod(indices,14)==0);
      prevfiles=cmdcells(indicesdiv14);
      prevdata=NaN(360000,1);
      for i=1:length(prevfiles)
        prevsac=prevfiles{i};
        [tempdata,hdr]=readsac(prevsac);
        startind=((60*hdr.NZMIN)+hdr.NZSEC)*100+hdr.NZMSEC+1;
        prevdata(startind:startind+length(tempdata)-1)=tempdata;    
        % 'Recycle' the SAC file when we're done
        [~,cmdout]=system(sprintf('mv %s %s',prevsac,rfdir));
      end
    else
      prevsac=cmdcells{length(cmdcells)-1};
      [prevdata,~]=readsac(prevsac,0);
      % 'Recycle' the SAC file
      [~,cmdout]=system(sprintf('mv %s %s',prevsac,rfdir));
    end        
  end
  
  % If the data from the previous hour has excess at the end, then 
  % we know that excess belongs to the current hour. 
  if length(prevdata)>360000
    newdata(1:nancount)=prevdata(...
      length(prevdata)-(nancount-1):length(prevdata));
  end
end

% If we still have NaNs in the constructed data, then we cannot use it
if sum(isnan(newdata))>0
  disp('NaNs still remain in the data. These data are unusable')
  newdata=NaN(length(newdata),1);
  return
end

% Edit the header
newhdr.B=0;
newhdr.E=3599.99;
newhdr.NPTS=length(newdata);

