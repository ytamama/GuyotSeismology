function disptovel(matfile,yyyy,mm,dd,HH,seconds) 
%
%Computes the velocity of the seismometer at Guyot Hall, Princeton
%University from the displacement recorded
%Plots the velocity as a time series within the time specified
%
%INPUTS:
%matfile - .mat file containing relevant data
%yyyy - year
%mm - month
%dd - day
%HH - hour
%seconds - range of seconds within the hour (1-3600) that we consider 
%(e.g. [1800 1900])
%
%last edited: April 14, 2020 by Yuri Tamama

%set a default directory to save graphs
savedir=fullfile(getenv('MC'),datestr(datenum(yyyy,mm,dd),'yyyy/mm/dd'));
savedir=fullfile(savedir,sprintf("SeismicVel_%d%d%d_%d%d%d",mm,dd,...
    yyyy,HH,floor(seconds(1)),floor(seconds(2))));

%set time step and time vector
deltat = 0.01;
trange = [seconds(1):deltat:seconds(2)];
tlen = length(trange);
datestring = sprintf("%d/%d/%d %d GMT",mm,dd,yyyy,HH);

%load .mat file
load(matfile);

%crop displacement vectors to blast times
firstind = (trange(1))*100 + 1;   
lastind = (trange(tlen))*100 + 1;
sx = sx(firstind:lastind);
sy = sy(firstind:lastind);
sz = sz(firstind:lastind);

%compute velocities in x, y, and z directions
%forward, central, and backward differencing
slen = length(sx);
velx = zeros(slen,1);
vely = zeros(slen,1);
velz = zeros(slen,1);
for i = 1:slen
    if i == 1  
        %forward difference
        velx(i) = (sx(i+1)-sx(i))/deltat;
        vely(i) = (sy(i+1)-sy(i))/deltat;
        velz(i) = (sz(i+1)-sz(i))/deltat;    
    elseif i == slen
        %backward difference
        velx(i) = (sx(i)-sx(i-1))/deltat;
        vely(i) = (sy(i)-sy(i-1))/deltat;
        velz(i) = (sz(i)-sz(i-1))/deltat;
    else
        %central difference
        velx(i) = (sx(i+1)-sx(i-1))/deltat;
        vely(i) = (sy(i+1)-sy(i-1))/deltat;
        velz(i) = (sz(i+1)-sz(i-1))/deltat;
    end
end

%find maximum magnitude of velocity to set x, y, z, limits
vx_max = max(abs(velx));
vx_lim = 1.1*vx_max;
vy_max = max(abs(vely));
vy_lim = 1.1*vy_max;
vz_max = max(abs(velz));
vz_lim = 1.1*vz_max;

%plot a time series of velocity vs time
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

%save the final product
print('-bestfit','-dpdf',savedir);
print('-depsc',savedir);


end

