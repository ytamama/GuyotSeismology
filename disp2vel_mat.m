function [velx,vely,velz,trange]=disp2vel_mat(matfile,seconds,makeplot) 
%
% Computes the velocity of the seismometer at Guyot Hall, Princeton
% University from the displacement recorded as an hourly MAT file
% (produced by mcms2mat.m)
%
% INPUTS
% matfile : MAT file containing the displacement data, along with its
%           directory
% seconds : Range of seconds within the hour (1-3600) that we consider 
% (e.g. [1800 1900])
%           Default: The entire time range of the file
% makeplot : Do we want to make a plot of velocity vs. time?
%            0 for no (default)
%            1 for yes
% 
% OUTPUTS
% velx, vely, velz : Velocity, converted from displacement 
%                    data in the x, y, and z components
% trange : The time, in seconds, over when the data were reocrded
% A plot of velocity vs. time, if requested
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

% Set times during which the data were collected
deltat = header.DELTA;
trange = [seconds(1):deltat:seconds(2)];
tlen = length(trange);
yyyy=header.NZYEAR;
[mm,dd,~]=jul2dat(yyyy,header.NZJDAY);
HH=header.NZHOUR;
datestring = sprintf("%d/%d/%d %d GMT",mm,dd,yyyy,HH);

% Crop displacement vectors as needed
firstind = (trange(1))*100 + 1;   
lastind = (trange(tlen))*100 + 1;
sx = sx(firstind:lastind);
sy = sy(firstind:lastind);
sz = sz(firstind:lastind);

% Compute velocities in x, y, and z directions
% Forward, central, and backward differencing
slen = length(sx);
velx = zeros(slen,1);
vely = zeros(slen,1);
velz = zeros(slen,1);
for i = 1:slen
  if i == 1  
    % Forward difference
    velx(i) = (sx(i+1)-sx(i))/deltat;
    vely(i) = (sy(i+1)-sy(i))/deltat;
    velz(i) = (sz(i+1)-sz(i))/deltat;    
  elseif i == slen
    % Backward difference
    velx(i) = (sx(i)-sx(i-1))/deltat;
    vely(i) = (sy(i)-sy(i-1))/deltat;
    velz(i) = (sz(i)-sz(i-1))/deltat;
  else
    % Central difference
    velx(i) = (sx(i+1)-sx(i-1))/deltat;
    vely(i) = (sy(i+1)-sy(i-1))/deltat;
    velz(i) = (sz(i+1)-sz(i-1))/deltat;
  end
end

% Plot a time series of velocity vs time, if requested
if makeplot==1
% Find maximum magnitudes of velocity to set as axis limits  
  vx_max = max(abs(velx));
  vx_lim = 1.1*vx_max;
  vy_max = max(abs(vely));
  vy_lim = 1.1*vy_max;
  vz_max = max(abs(velz));
  vz_lim = 1.1*vz_max;
  
  figure()
  subplot(3,1,1)
  plot(trange, velx);
  ylim([-vx_lim vx_lim])
  ylabel("X (nm/s)")
  title({"Velocity of Seismic Waves";...
    "Recorded at Guyot Hall at Princeton University";datestring})
  subplot(3,1,2)
  plot(trange, vely);
  ylim([-vy_lim vy_lim])
  ylabel("Y (nm/s)")
  subplot(3,1,3)
  plot(trange, velz);
  ylim([-vz_lim vz_lim])
  ylabel("Z (nm/s)")
  xlabel(sprintf("Time (s) since %d:00:00 GMT",HH))
end

end

