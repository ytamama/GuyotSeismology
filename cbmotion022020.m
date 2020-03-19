%cbmotion022020
%Plots a particle motion diagram (changing with time) in the x, y, and z directions
%of the seismometer in Guyot Hall at Princeton University
%in response to the movement caused by the campus blasts
%Campus Blasts: 2-18-2020 and 2-21-2020

%last edited March 19, 2020 by Yuri Tamama


%set file names and time step
feb18file = "PP.S0001.00.HHA_MC-PH1_0248_20200218_160000.mat";
feb21file = "PP.S0001.00.HHA_MC-PH1_0248_20200221_160000.mat";
deltat = 0.01;

%choose which campus blast to analyze
%set to 1 if choosing; 0 if not choosing
feb18 = 1;
feb21 = 0;

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
    trange = [2563.5:deltat:2567];
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

%plot a time-changing plot in 3d
figure(1)
plot3(sx(1),sy(1),sz(1),'*-','MarkerEdgeColor', 'blue', 'Color','blue')
if feb18 == 1
    xlim([-5*10^4 5*10^4])
    ylim([-5*10^4 5*10^4])
    zlim([-5*10^4 5*10^4])
else
    xlim([-10*10^4 11*10^4])
    ylim([-10*10^4 11*10^4])
    zlim([-10*10^4 11*10^4])
end
%set x,y, and z limits
legend(sprintf('%d',trange(1)))
hold on
pause on
%below was the only method I know of that lets me plot a particle motion
%diagram that changes with time AND tracks the seismometer's motion
for i = 2:tlen
    plot3(sx(1:i),sy(1:i),sz(1:i),'*-','MarkerEdgeColor', 'blue', 'Color','blue')
    %set x,y, and z limits
    legend(sprintf('%d',trange(i)))
    pause(0.05)
end
hold off

figure(2)
plot3(sx,sy,sz,'*-','MarkerEdgeColor', 'blue','Color','blue')
%set x,y,and z limits
legend(sprintf('%d',trange(tlen)))
title({"Particle Motion Diagram of Seismometer";"in Guyot Hall at Princeton University";datestr})
xlabel("Displacement in x")
ylabel("Displacement in y")
zlabel("Displacement in z")
print('-bestfit','-dpdf','CB_ParticleMotion'+savedate);  %save the final product
print('-dpng','CB_ParticleMotion'+savedate);






