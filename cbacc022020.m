%cbacc022020
%Computes the acceleration of the seismometer at Guyot Hall in the x, y, and z directions
%from displacement data collected by the seismometer
%Plots the acceleration as a time series and finds the largest absolute
%magnitude of acceleration
%Campus Blasts: 2-18-2020 and 2-21-2020

%last edited March 19, 2020 by Yuri Tamama


%set file names (from mcms2mat.m) and time step
feb18file = "PP.S0001.00.HHA_MC-PH1_0248_20200218_160000.mat";
feb21file = "PP.S0001.00.HHA_MC-PH1_0248_20200221_160000.mat";
deltat = 0.01;

%choose which campus blast to analyze
%set to 1 if choosing; 0 if not choosing
feb18 = 0;
feb21 = 1;

%error catching
if (feb18 == 1) && (feb21 == 1)
    error("Can't analyze both at once!")
end
if (feb18 == 0) && (feb21 == 0)
    error("Analyze one campus blast!")
end


%different pathways based on which file to load
%February 18 blast
if feb18 == 1
    trange = [1804.5:deltat:1807.5];
    trange = transpose(trange);
    tlen = length(trange);
    datestr = "February 18, 2020 (JD 49)";
    savedate = "Feb182020";  %for saving data
    
    %load .mat data
    load(feb18file);     

%February 21 blast
else
    trange = [2563.5:deltat:2567.5];
    tlen = length(trange);
    datestr = "February 21, 2020 (JD 52)";  %for plotting
    savedate = "Feb212020";  %for saving data
    
    %load .mat data
    load(feb21file);     
end


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

%convert velocities from nm/s to m/s
accx = accx*(1e-9);
accy = accy*(1e-9);
accz = accz*(1e-9);

%plot a time series of acceleration vs time
figure(1)
subplot(3,1,1)
plot(trange, accx);
ylabel("X Acceleration (m/s)")
title({"Acceleration of Campus Blasts";"Recorded at Guyot Hall at Princeton University";datestr})
subplot(3,1,2)
plot(trange, accy);
ylabel("Y Acceleration (m/s)")
subplot(3,1,3)
plot(trange, accz);
ylabel("Z Acceleration (m/s)")
xlabel("Time (s) since 16:00:00 GMT")
% print('-bestfit','-dpdf','CampusBlastAccel_'+savedate);
% print('-dpng','CampusBlastAccel_'+savedate);


%compute maximum absolute value of acceleration
maxaccx = max(abs(accx));
maxaccy = max(abs(accy));
maxaccz = max(abs(accz));

