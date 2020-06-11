function [accdata,header,accplot]=disp2acc_sac(sacfile,makeplot)
% 
% Computes the acceleration recorded by the seismometer at Guyot Hall, 
% Princeton University, from its displacement data recorded in a 
% SAC file
% 
% INPUTS
% sacfile : SAC file containing the displacement data, including its
%           full directory
% makeplot : Do we want to plot acceleration vs. time?
%            0 for no (default)
%            1 for yes 
% 
% OUTPUTS
% accdata : Acceleration, calculated from displacement via differentiation
% header : Updated header
% accplot : The plot of acceleration vs. time, if desired
% 
% References
% Uses readsac.m to read in the displacement data
% in csdms-contrib/slepian_oscar 
% 
% Uses dat2jul.m also in csdms-contrib/slepian_oscar
% 
% Uses defval.m in csdms-contrib/slepian_alpha
% 
% Last Modified: 06/11/2020 by Yuri Tamama
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set the default value
defval('makeplot',0);

% Read in the SAC file using READSAC.M 
[dispdata,header]=readsac(sacfile,0);

% Edit the header
header.IDEP=8;

% Compute accelerations in x, y, and z directions (nm/s^2)
% Forward, central, and backward differencing
deltat=header.DELTA;
numpts=header.NPTS;
accdata=zeros(numpts,1);
trange=[header.B:deltat:header.E];
for i = 1:numpts
  if i == 1  
    % forward difference
    accdata(i) = (dispdata(i+2)-2*dispdata(i+1)+dispdata(i))/(deltat^2);    
  elseif i == numpts
    % backward difference
    accdata(i) = (dispdata(i)-2*dispdata(i-1)+dispdata(i-2))/(deltat^2);
  else
    % central difference
    accdata(i) = (dispdata(i+1)-2*dispdata(i)+dispdata(i-1))/(deltat^2);
  end
end

if makeplot==1
  % Find the date/time strings that would be necessary to have on
  % the plot
  yyyy=header.NZYEAR;
  datenums=jul2dat(yyyy,header.NZJDAY);
  mm=datenums(1);
  dd=datenums(2);
  HH=header.NZHOUR;
  datestring = sprintf('%d/%d/%d %d GMT',mm,dd,yyyy,HH);     
    
  % Find maximum magnitudes of acceleration to set as axis limits  
  amax = max(abs(accdata));
  alim = 1.1*amax;
  
  % Plot
  figure()
  accplot=plot(trange,accdata);
  xlim([header.B header.E+10])
  ylim([-alim alim])
  ylabel('Acceleration (nm/s^2)') 
  xlabel(sprintf('Time (s) since %d:00:00 GMT',HH))
  title({'Ground Acceleration Computed from Displacement';...
    'Recorded at Guyot Hall at Princeton University';datestring})
end
