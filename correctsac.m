function correctedsac=correctsac(sacfiles,measval,frequency,respfile)
% 
% Function that takes in 1 or 3 SAC files as input, deconvolves the 
% SAC file(s) from the instrument response, and filters the SAC file(s)
% at the desired frequency range. 
% 
% sacfiles : The name(s) of the SAC file(s) to instrument correct, 
%            entered as string(s) in a cell array. 
% 
%            If only 1 SAC file is entered, that file will be 
%            corrected by removing the mean and linear trend, applying
%            a taper, and applying the transfer function to deconvolve
%            from the instrument response, with prewhitening
% 
%            Alternatively, if 3 SAC files are entered, those files 
%            will be concatenated in order. All but a number of seconds
%            on either side will be cut. Then, the same instrument
%            correction process will happen as above, and the excess
%            seconds will be trimmed off, resulting in one hour-long SAC
%            file without the tapering effect. The SAC files must be 
%            listed in chronological order, and be of adjacent hours
%
% measval : Do we want displacement, velocity, or acceleration?
%           0 - Displacement, in nm 
%           1 - Velocity, in nm/s
%           2 - Acceleration, in nm/s^2
% channel : The channel from which we get the SAC files
%           e.g.) HHX, BHN
% frequency : The frequencies at which the data will be filtered
% respfile : The path and name of the instrument's response file, if 
%            known. Enter an empty string if that needs to be found 
%            using an IRIS query.
%           
% OUTPUT
% correctedsac : The name of the SAC file that has been instrument 
%                corrected. 
% 
% References
% Code to convert from a .miniseed file to a .SAC file and
% apply instrument response correction from
% mcms2mat.m, in csdms-contrib/slepian_oscar
% Uses readsac.m, in csdms-contrib/slepian_oscar
% Uses jul2dat.m, in csdms-contrib/slepian_oscar
% 
% Referred to the SAC manual, found here: 
% http://ds.iris.edu/files/sac-manual/
% Also see "The Seismic Analysis Code : a Primer and User's Guide"
% by Helffrich et al., 2013
% 
% The facilities of IRIS Data Services, specifically the RESP web service, 
% were used for this code. IRIS Data Services are funded through the 
% Seismological Facilities for the Advancement of Geoscience (SAGE) Award 
% of the National Science Foundation under Cooperative Support Agreement
% EAR-1851048.
% 
% Last Modified by Yuri Tamama, 11/04/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check length of inputted SAC files and load header of main file
if length(sacfiles)==1
  corrtype=1;
  sacfile=sacfiles{1};
elseif length(sacfiles)==3
  corrtype=2;
  sacfile=sacfiles{2};
else
  disp('Enter a valid number of SAC files. Exiting function.')
  correctedsac='';
  return
end
[~,header]=readsac(sacfile,0);
channel=header.KCMPNM;
channel=replace(channel,' ','');
netwkname=header.KNETWK;
netwkname=replace(netwkname,' ','');
staname=header.KSTNM;
staname=replace(staname,' ','');
if isfield(header,'KHOLE')
  locname=header.KHOLE;
  locname=replace(locname,' ','');
else
  locname='*';
end
  
% Do we want displacement, velocity, or acceleration?
if measval==0
  vallabelmini='disp';
  valtype='none';
elseif measval==1
  vallabelmini='vel';
  valtype='vel';
else
  vallabelmini='acc';
  valtype='acc';
end

% Instrument response files
if isempty(respfile)
  % Time stamp
  yearstr=num2str(header.NZYEAR,0);
  filejd=header.NZJDAY;
  filemdy=jul2dat(header.NZYEAR,filejd);
  monstr=datenum2str(filemdy(1),0);
  daystr=datenum2str(filemdy(2),0);
  hrstr=datenum2str(header.NZHOUR,0);
  minstr=datenum2str(header.NZMIN,0);
  secstr=datenum2str(header.NZSEC,0);
  timestamp=sprintf('%s-%s-%sT%s:%s:%s',yearstr,monstr,daystr,hrstr,...
    minstr,secstr);
  % Structure IRIS query URL
  urlstart='service.iris.edu/irisws/resp/1/query?';
  urlend=sprintf('net=%s&sta=%s&loc=%s&cha=%s&time=%s',netwkname,...
    staname,locname,channel,timestamp);
  % Response file name
  if isfield(header,'KHOLE')
    respfile=sprintf(' %s.%s.%s.%s.resp',netwkname,staname,locname,...
      channel);
  else
    respfile=sprintf(' %s.%s..%s.resp',netwkname,staname,channel);
  end
  fullquery=strcat('wget "',urlstart,urlend,'" -O- -q >!',respfile);
  [status,cmdout]=system(fullquery);
  respfile=respfile(2:length(respfile));
end
if strcmpi(locname,'*')
  locname='';
end

% Transfer command
transfer=sprintf(...
  'transfer from evalresp fname %s to %s freqlimits %g %g %g %g prewhitening on',...
  respfile,valtype,frequency(1),frequency(2),frequency(3),...
  frequency(4));

% File names
freqstr1=num2str(frequency(1));
freqstr2=num2str(frequency(2));
freqstr3=num2str(frequency(3));
freqstr4=num2str(frequency(4));
% Time of the data
yearstr=num2str(header.NZYEAR);
jdstr=datenum2str(header.NZJDAY,1);
hrstr=datenum2str(header.NZHOUR,0);
minstr=datenum2str(header.NZMIN,0);
secstr=datenum2str(header.NZSEC,0);
uncorrfmt='%s.%s.%s.%s.%s.%s.%s.%s%s%s.%s%s%s%s.uc.SAC';
uncorrectedsac=sprintf(uncorrfmt,netwkname,staname,locname,...
  vallabelmini,channel,yearstr,jdstr,hrstr,minstr,secstr,freqstr1,...
  freqstr2,freqstr3,freqstr4);
corrfmt='%s.%s.%s.%s.%s.%s.%s.%s%s%s.%s%s%s%s.cr.SAC';
correctedsac=sprintf(corrfmt,netwkname,staname,locname,...
  vallabelmini,channel,yearstr,jdstr,hrstr,minstr,secstr,freqstr1,...
  freqstr2,freqstr3,freqstr4);

% Taper buffer start and end 
% Assign so that cutting 5% from either side of the merged file gets us
% 1 hour of data, as intended
tapertime=200; 
bufferstart=3600-tapertime;
bufferend=7199.99+tapertime;
      
% Apply Instrument Correction!
% Only 1 SAC file
if corrtype==1
  corrcmd=sprintf(...
    'echo "r %s ; read ; rtr ; rmean ; taper type ; %s ; w %s ; q" | /usr/local/sac/bin/sac',...
    sacfiles{1},transfer,correctedsac);
  [status,cmdout]=system(corrcmd);  
% 3 SAC files
else
  mergecmd=sprintf(...
    'echo "r %s %s %s ; chnhdr KCMPNM HH%s ; merge ; w %s ; q" | /usr/local/sac/bin/sac',...
    sacfiles{1},sacfiles{2},sacfiles{3},channel,uncorrectedsac);
  [status,cmdout]=system(mergecmd);    
  corrcmd=sprintf(...
    'echo "r %s ; cut %g %g ; read ; rtr ; rmean ; taper type ; %s ; w %s ; q" | /usr/local/sac/bin/sac',...
    uncorrectedsac,bufferstart,bufferend,transfer,correctedsac);  
  [status,cmdout]=system(corrcmd);
  % Cut off the buffer on either end
  sacstart=3600;
  sacend=7199.99;
  cutcmd=sprintf(...
    'echo "r %s ; cut %g %g ; read ; chnhdr B 0 E 3599.99 NZHOUR %d NZJDAY %d  ; w %s ; q" | /usr/local/sac/bin/sac',...
    correctedsac,sacstart,sacend,header.NZHOUR,header.NZJDAY,correctedsac);
  [status,cmdout]=system(cutcmd);
end


