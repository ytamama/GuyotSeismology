%disptovel.m
%Computes the velocity of the seismometer at Guyot Hall, Princeton
%University from the displacement recorded
%Plots the velocity as a time series within the time specified

%inputs
%filename - .mat file containing relevant data
%yyyy - year
%mm - month
%dd - day
%HH - hour
%seconds - range of seconds within the hour (1-3600) that we want to consider 
%(e.g. [1800 1900])

%lasted edited: March 21, 2020 by Yuri Tamama

function disptovel(matfile,yyyy,mm,dd,HH,seconds) 

%set time step and time vector
deltat = 0.01;
trange = [seconds(1):deltat:seconds(2)];
tlen = length(trange);
datestr = sprintf("%d/%d/%d %d GMT",mm,dd,yyyy,HH);
savedate = sprintf("%d%d%d_%d%d%d",mm,dd,yyyy,HH,seconds(1),seconds(2));

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


%plot velocity and save
figure(1)
subplot(3,1,1)
plot(trange, velx);
ylabel("X Velocity (nm/s)")
title({"Velocity of Seismic Waves";"Recorded at Guyot Hall at Princeton University";datestr})
subplot(3,1,2)
plot(trange, vely);
ylabel("Y Velocity (nm/s)")
subplot(3,1,3)
plot(trange, velz);
ylabel("Z Velocity (nm/s)")
xlabel(sprintf("Time (s) since %s:00:00 GMT",HH))
print('-bestfit','-dpdf','SeismicVelocity_'+savedate);
print('-dpng','SeismicVelocity_'+savedate);
print('-depsc','SeismicVelocity'+savedate);


end

