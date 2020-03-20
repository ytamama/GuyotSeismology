%disptoacc.m
%Computes the acceleration of the seismometer at Guyot Hall, Princeton
%University from the displacement recorded
%Plots the acceleration as a time series within the time specified

%inputs
%filename - .mat file containing relevant data
%yyyy - year
%mm - month
%dd - day
%HH - hour
%seconds - range of seconds within the hour (1-3600) that we want to consider 
%(e.g. [1800 1900])

%lasted edited: March 20, 2020 by Yuri Tamama

function disptoacc(matfile,yyyy,mm,dd,HH,seconds) 

%set time step and time vector
deltat = 0.01;
trange = [seconds(1):deltat:seconds(2)];
tlen = length(trange);
datestr = sprintf("%d/%d/%d %d GMT",mm,dd,yyyy,HH);
savedate = sprintf("%d%d%d_%d%d%d",mm,dd,yyyy,HH,seconds(1),seconds(2));

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


%plot a time series of acceleration vs time
figure(1)
subplot(3,1,1)
plot(trange, accx);
ylabel("X Acceleration (m/s)")
title({"Acceleration of Seismic Waves";"Recorded at Guyot Hall at Princeton University";datestr})
subplot(3,1,2)
plot(trange, accy);
ylabel("Y Acceleration (m/s)")
subplot(3,1,3)
plot(trange, accz);
ylabel("Z Acceleration (m/s)")
xlabel(sprintf("Time (s) since %s:00:00 GMT",HH))
print('-bestfit','-dpdf','SeismicAccel_'+savedate);
print('-dpng','SeismicAccel_'+savedate);



end


