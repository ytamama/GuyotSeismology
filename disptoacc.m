function disptoacc(matfile,yyyy,mm,dd,HH,seconds) 
%
%Computes the acceleration of the seismometer at Guyot Hall, Princeton
%University from the displacement recorded
%Plots the acceleration as a time series within the time specified
%
%INPUTS
%matfile - .mat file containing relevant data
%yyyy - year
%mm - month
%dd - day
%HH - hour
%seconds - range of seconds within the hour (1-3600) that we consider 
%(e.g. [1800 1900])
%
%lasted edited: April 14, 2020 by Yuri Tamama

%set a default directory to save graphs
savedir=fullfile(getenv('MC'),datestr(datenum(yyyy,mm,dd),'yyyy/mm/dd'));
savedir=fullfile(savedir,sprintf("SeismicAccel_%d%d%d_%d%d%d",mm,dd,...
    yyyy,HH,floor(seconds(1)),floor(seconds(2))));

%set time step and time vector
deltat = 0.01;
trange = [seconds(1):deltat:seconds(2)];
tlen = length(trange);
datestring = sprintf("%d/%d/%d %d GMT",mm,dd,yyyy,HH);

%load .mat file
load(matfile)

%crop displacement vectors to blast times
firstind = (trange(1))*100 + 1;   
lastind = (trange(tlen))*100 + 1;
sx = sx(firstind:lastind);
sy = sy(firstind:lastind);
sz = sz(firstind:lastind);

%compute accelerations in x, y, and z directions (nm/s^2)
%forward, central, and backward differencing
slen = length(sx);
accx = zeros(slen,1);
accy = zeros(slen,1);
accz = zeros(slen,1);
for i = 1:slen
    if i == 1  
        %forward difference
        accx(i) = (sx(i+2)-2*sx(i+1)+sx(i))/(deltat^2);
        accy(i) = (sy(i+2)-2*sy(i+1)+sy(i))/(deltat^2);
        accz(i) = (sz(i+2)-2*sz(i+1)+sz(i))/(deltat^2);    
    elseif i == slen
        %backward difference
        accx(i) = (sx(i)-2*sx(i-1)+sx(i-2))/(deltat^2);
        accy(i) = (sy(i)-2*sy(i-1)+sy(i-2))/(deltat^2);
        accz(i) = (sz(i)-2*sz(i-1)+sz(i-2))/(deltat^2);
    else
        %central difference
        accx(i) = (sx(i+1)-2*sx(i)+sx(i-1))/(deltat^2);
        accy(i) = (sy(i+1)-2*sy(i)+sy(i-1))/(deltat^2);
        accz(i) = (sz(i+1)-2*sz(i)+sz(i-1))/(deltat^2);
    end
end

%find maximum magnitude of acceleration to set x, y, z, limits
ax_max = max(abs(accx));
ax_lim = 1.1*ax_max;
ay_max = max(abs(accy));
ay_lim = 1.1*ay_max;
az_max = max(abs(accz));
az_lim = 1.1*az_max;

%plot a time series of acceleration vs time
figure()
subplot(3,1,1)
plot(trange, accx);
ylim([-ax_lim ax_lim])
ylabel("X (nm/s^2)")
title({"Acceleration of Seismic Waves";...
    "Recorded at Guyot Hall at...Princeton University";datestring})
subplot(3,1,2)
plot(trange, accy);
ylim([-ay_lim ay_lim])
ylabel("Y (nm/s^2)")
subplot(3,1,3)
plot(trange, accz);
ylim([-az_lim az_lim])
ylabel("Z (nm/s^2)")
xlabel(sprintf("Time (s) since %d:00:00 GMT",HH))

%save the final product
print('-bestfit','-dpdf',savedir);
print('-depsc',savedir);


end


