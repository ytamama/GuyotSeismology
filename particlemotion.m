%particlemotion.m
%Plots a particle motion diagram (changing with time) in the x, y, and z directions
%of the seismometer in Guyot Hall at Princeton University

%inputs
%matfile - .mat file containing relevant data
%yyyy - year
%mm - month
%dd - day
%HH - hour
%seconds - range of seconds within the hour (1-3600) that we want to consider 
%(e.g. [1800 1900])

%last edited March 25, 2020 by Yuri Tamama

function particlemotion(matfile,yyyy,mm,dd,HH,seconds) 

%set a default directory to save graphs
%names hidden here for privacy
setenv('',getenv(''))
savedir=getenv('');
savedir=fullfile(savedir,datestr(datenum(yyyy,mm,dd),'/yyyy/mm/dd'));
savedir=fullfile(savedir,sprintf("ParticleMotion_%d%d%d_%d%d%d",mm,dd,yyyy,HH,floor(seconds(1)),floor(seconds(2))));

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

%find maximum magnitude of displacement to set constant limits in x, y, z
sx_max = max(abs(sx));
sx_lim = 1.2*sx_max;
sy_max = max(abs(sy));
sy_lim = 1.2*sy_max;
sz_max = max(abs(sz));
sz_lim = 1.2*sz_max;

%plot a time-changing plot in 3d
figure(1)
plot3(sx(1),sy(1),sz(1),'*-','MarkerEdgeColor', 'blue', 'Color','blue')
xlim([-sx_lim sx_lim])
ylim([-sy_lim sy_lim])
zlim([-sz_lim sz_lim])
title({"Particle Motion Diagram of Seismometer";"in Guyot Hall at Princeton University";datestring})
xlabel("X (nm)")
ylabel("Y (nm)")
zlabel("Z (nm)")
legend(sprintf('%d',trange(1)))

hold on
pause on
%plot a particle motion diagram that changes with time and tracks the seismometer's motion
for i = 2:tlen
    plot3(sx(1:i),sy(1:i),sz(1:i),'*-','MarkerEdgeColor', 'blue', 'Color','blue')
    xlim([-sx_lim sx_lim])
    ylim([-sy_lim sy_lim])
    zlim([-sz_lim sz_lim])
    legend(sprintf('%d',trange(i)))
    title({"Particle Motion Diagram of Seismometer";"in Guyot Hall at Princeton University";datestring})
    xlabel("X (nm)")
    ylabel("Y (nm)")
    zlabel("Z (nm)")
    pause(0.01)
end
hold off

%plot and save the final particle motion diagram
figure(2)
plot3(sx,sy,sz,'*-','MarkerEdgeColor', 'blue','Color','blue')
xlim([-sx_lim sx_lim])
ylim([-sy_lim sy_lim])
zlim([-sz_lim sz_lim])
legend(sprintf('%d',trange(tlen)))
title({"Particle Motion Diagram of Seismometer";"in Guyot Hall at Princeton University";datestring})
xlabel("X (nm)")
ylabel("Y (nm)")
zlabel("Z (nm)")

%save the final product
print('-bestfit','-dpdf',savedir);
print('-depsc',savedir);


end



