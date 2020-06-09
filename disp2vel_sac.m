function [veldata,header]=disp2vel_sac(sacfile,makeplot)
% 
% Computes the velocity recorded by the seismometer at Guyot Hall, 
% Princeton University, from its displacement data recorded in a 
% SAC file
% 
% INPUTS
% sacfile : SAC file containing the displacement data, including its
%           full directory
% makeplot : Do we want to plot velocity vs. time?
%            0 for no (default)
%            1 for yes 
% 
% OUTPUTS
% veldata : Velocity, calculated from displacement via differentiation
% header : Updated header
% A plot of velocity vs. time, if desired
% 
% References
% Uses readsac.m to read in the displacement data
% written by Prof. Frederik Simons and Anna Van Brummen
% (in csdms-contrib/slepian_oscar repository)
% 
% Uses dat2jul.m, written by Prof. Frederik Simons, also in 
% also in csdms-contrib/slepian_oscar
% 
% Uses defval.m, written by Prof. Frederik Simons and by 
% ebrevdo-at-alumni-princeton.edu (in slepian_alpha repository)
% 
% Last Modified: 06/09/2020 by Yuri Tamama
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set the default value
defval('makeplot',0);

% Read in the SAC file using READSAC.M 
[dispdata,header]=readsac(sacfile,0);

% Edit the header
header.IDEP=7;

% Compute velocities in x, y, and z directions
% Forward, central, and backward differencing
deltat=header.DELTA;
numpts=header.NPTS;
veldata=zeros(numpts,1);
trange=[header.B:deltat:header.E];
for i=1:numpts
  if i == 1  
    % Forward difference
    veldata(i) = (dispdata(i+1)-dispdata(i))/deltat;  
  elseif i == numpts
    % Backward difference
    veldata(i) = (dispdata(i)-dispdata(i-1))/deltat;
  else
    % Central difference
    veldata(i) = (dispdata(i+1)-dispdata(i-1))/deltat;
  end
end

if makeplot==1
  % Find the date/time strings that would be necessary to have on
  % the plot
  yyyy=header.NZYEAR;
  [mm,dd,~]=jul2dat(yyyy,header.NZJDAY);
  HH=header.NZHOUR;
  datestring = sprintf('%d/%d/%d %d GMT',mm,dd,yyyy,HH);     
    
  % Find maximum magnitudes of velocity to set as axis limits  
  vmax = max(abs(veldata));
  vlim = 1.1*vmax;
  
  % Plot
  figure()
  plot(trange,vmax);
  ylim([-vlim vlim])
  ylabel('Velocity (nm/s)') 
  xlabel(sprintf('Time (s) since %d:00:00 GMT',HH))
  title({'Velocity of Seismic Waves';...
    'Recorded at Guyot Hall at Princeton University';datestring}) 
end
