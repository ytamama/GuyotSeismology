function fnameout=iriseval(netname,locname,staname,chaname,yrname,jd,...
  freqinfo,fnamein,measval)
%
% Function to retrieve the frequency-amplitude response of a seismometer, 
% using IRIS's evalresp program.
% 
% INPUTS
% netname : Name of the network (default: 'PP') 
% locname : Location code, entered as a string (default: '00')
% staname : Name of the station (default: 'S0001')
% chaname : Name of the channel, specifying the directional component
% yrname : Year for which we wish to retrieve the response
% jd : The Julian Day, within the inputted year, for which we want to
%      retrieve the response
% freqinfo : 3 element vector of this format:
%            [freqmin, freqmax, freqnum] where
%            freqmin : Lowest frequency
%            freqmax : Highest frequency
%            numfreq : Number of "data points" between the lowest and
%                      highest frequency
% fnamein : Name of the .RESP file of the seismometer, including the full 
%           path
% measval : In what units do we want the instrument response?
%           0 : Displacement
%           1 : Velocity
%           2 : Acceleration
%           3 : Default 
%
% OUTPUT
% fnameout : Name of the data file, containing the frequency, amplitude
%            response, and phase response as columns in that order
% 
% References
% Uses IRIS's evalresp software to obtain the values of frequency, 
% amplitude response, and phase response
% Uses defval.m, in csdms-contrib/slepian_alpha 
% 
% Last Modified by Yuri Tamama, 11/08/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('staname','S0001')
defval('netname','PP')

% Units
plotunits={'dis';'vel';'acc';'def'};

% Construct command
respcmd=sprintf('evalresp %s %s %d %d %f %f %d -f %s -u ''%s'' -r ''fap''',...
  staname,chaname,yrname,jd,freqinfo(1),freqinfo(2),freqinfo(3),...
  fnamein,plotunits{measval+1});
[status,cmdout]=system(respcmd);
if status~=0
  keyboard
end

% Rename the file
fnameold=sprintf('FAP.%s.%s.%s.%s',netname,staname,locname,chaname);
fnameout=sprintf('%d.%d.%d.%s.FAP.%s.%s.%s.%s.txt',yrname,jd,...
  freqinfo(3),plotunits{measval+1},netname,staname,locname,chaname);
namecmd=sprintf('mv %s %s',fnameold,fnameout);
[status,cmdout]=system(namecmd);
if status~=0
  keyboard
end


