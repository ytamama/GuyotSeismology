%cbvel022020
%Computes the velocity of the seismometer at Guyot Hall in the x, y, and z directions
%from displacement data collected by the seismometer
%Plots the velocity as a time series and finds the largest absolute
%magnitude of velocity
%Campus Blasts: 2-18-2020 and 2-21-2020

%last edited March 21, 2020 by Yuri Tamama


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

%convert velocities from nm/s to mm/s
velx = velx*(1e-6);
vely = vely*(1e-6);
velz = velz*(1e-6);

%plot a time series of velocity vs time
figure(1)
subplot(3,1,1)
plot(trange, velx);
ylabel("X Velocity (mm/s)")
title({"Velocity of Campus Blasts";"Recorded at Guyot Hall at Princeton University";datestr})
subplot(3,1,2)
plot(trange, vely);
ylabel("Y Velocity (mm/s)")
subplot(3,1,3)
plot(trange, velz);
ylabel("Z Velocity (mm/s)")
xlabel("Time (s) since 16:00:00 GMT")
print('-bestfit','-dpdf','CampusBlastVelocity_'+savedate);
print('-dpng','CampusBlastVelocity_'+savedate);
print('-depsc','CampusBlastVelocity_'+savedate);

%compute maximum absolute value of velocity, in mm/s
maxvelx = max(abs(velx));
maxvely = max(abs(vely));
maxvelz = max(abs(velz));





