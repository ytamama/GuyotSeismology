function [accx,accy,accz,trange]=disp2acc_mat(matfile,seconds,makeplot) 
%
% Computes the acceleration of the seismometer at Guyot Hall, Princeton
% University from the displacement recorded as an hourly MAT file
% (produced by mcms2mat.m)
%
% INPUTS
% matfile : MAT file containing the displacement data, along with its
%           directory
% seconds : Range of seconds within the hour (1-3600) that we consider 
% (e.g. [1800 1900])
%           Default: The entire time range of the file
% makeplot : Do we want to make a plot of acceleration vs. time?
%            0 for no (default)
%            1 for yes
% 
% OUTPUTS
% accx, accy, accz : Acceleration, converted from displacement 
%                    data in the x, y, and z components
% trange : The time, in seconds, over when the data were reocrded
% A plot of acceleration vs. time, if requested
%
% References
% MAT files are produced by mcms2mat.m,in csdms-contrib/slepian_oscar, 
% by Professor Frederik Simons and Anna Van Brummen
% 
% Uses dat2jul.m, written by Prof. Frederik Simons, also in 
% also in csdms-contrib/slepian_oscar
% 
% Uses defval.m, written by Prof. Frederik Simons and by 
% ebrevdo-at-alumni-princeton.edu (in slepian_alpha repository)
%
% Last Modified: 06/08/2020 by Yuri Tamama
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the MAT file (creates variables hx,hy,hz,sx,sy,sz)
load(matfile)
header=hx;

% Set default values
defval('makeplot',0);
defval('seconds',[header.B header.E]);

% Find the times during which the data were collected
deltat = header.DELTA;
trange = [seconds(1):deltat:seconds(2)];
tlen = length(trange);

% Crop displacement vectors as needed
firstind = (trange(1))*100 + 1;   
lastind = (trange(tlen))*100 + 1;
sx = sx(firstind:lastind);
sy = sy(firstind:lastind);
sz = sz(firstind:lastind);

% Compute accelerations in x, y, and z directions (nm/s^2)
% Forward, central, and backward differencing
slen = length(sx);
accx = zeros(slen,1);
accy = zeros(slen,1);
accz = zeros(slen,1);
for i = 1:slen
  if i == 1  
    % forward difference
    accx(i) = (sx(i+2)-2*sx(i+1)+sx(i))/(deltat^2);
    accy(i) = (sy(i+2)-2*sy(i+1)+sy(i))/(deltat^2);
    accz(i) = (sz(i+2)-2*sz(i+1)+sz(i))/(deltat^2);    
  elseif i == slen
    % backward difference
    accx(i) = (sx(i)-2*sx(i-1)+sx(i-2))/(deltat^2);
    accy(i) = (sy(i)-2*sy(i-1)+sy(i-2))/(deltat^2);
    accz(i) = (sz(i)-2*sz(i-1)+sz(i-2))/(deltat^2);
  else
    % central difference
    accx(i) = (sx(i+1)-2*sx(i)+sx(i-1))/(deltat^2);
    accy(i) = (sy(i+1)-2*sy(i)+sy(i-1))/(deltat^2);
    accz(i) = (sz(i+1)-2*sz(i)+sz(i-1))/(deltat^2);
  end
end

% Plot a time series of acceleration vs time, if requested
if makeplot==1
  % Find the date/time strings that would be necessary to have on
  % the plot   
  yyyy=header.NZYEAR;
  [mm,dd,~]=jul2dat(yyyy,header.NZJDAY);
  HH=header.NZHOUR;
  datestring = sprintf('%d/%d/%d %d GMT',mm,dd,yyyy,HH);

  % Find maximum magnitudes of acceleration to set as axis limits
  ax_max = max(abs(accx));
  ax_lim = 1.1*ax_max;
  ay_max = max(abs(accy));
  ay_lim = 1.1*ay_max;
  az_max = max(abs(accz));
  az_lim = 1.1*az_max;
    
  % Plot
  figure()
  subplot(3,1,1)
  plot(trange, accx);
  ylim([-ax_lim ax_lim])
  ylabel('X (nm/s^2)')
  title({'Acceleration of Seismic Waves';...
    'Recorded at Guyot Hall at Princeton University';datestring})
  subplot(3,1,2)
  plot(trange, accy);
  ylim([-ay_lim ay_lim])
  ylabel('Y (nm/s^2)')
  subplot(3,1,3)
  plot(trange, accz);
  ylim([-az_lim az_lim])
  ylabel('Z (nm/s^2)')
  xlabel(sprintf('Time (s) since %d:00:00 GMT',HH))
end


end


