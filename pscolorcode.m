function colorvec=pscolorcode(inputval,colorcode)
% 
% Function that returns a 3 element vector representing a RGB color, 
% for use in pseudorsec.m.
% 
% INPUTS
% inputval : A magnitude, depth (km), or epicentral distance
% colorcode : Do we color code by magnitude, depth, or epicentral 
%             distance?
%             1 - Magnitude
%             2 - Depth 
%             3 - Epicentral distance 
%
% OUTPUT
% colorvec : A 3 element vector representing a RGB color
% 
% References
% Use of colormap, including how to adjust for the number of colors in 
% the colormap, from MATLAB help forums
% 
% Last Modified by Yuri Tamama, 12/27/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Prepare relevant colormaps
if colorcode==1
  cmap=colormap(jet(12));
  if inputval<=-1
    colorvec=cmap(1,:);
  elseif inputval<=0
    colorvec=cmap(2,:);
  elseif inputval<=1
    colorvec=cmap(3,:);
  elseif inputval<=2
    colorvec=cmap(4,:);
  elseif inputval<=3
    colorvec=cmap(5,:);
  elseif inputval<=4
    colorvec=cmap(6,:);
  elseif inputval<=5
    colorvec=cmap(7,:);
  elseif inputval<=6
    colorvec=cmap(8,:);
  elseif inputval<=7
    colorvec=cmap(9,:);
  elseif inputval<=8
    colorvec=cmap(10,:);
  elseif inputval<=9
    colorvec=cmap(11,:);
  else
    colorvec=cmap(12,:);
  end 
elseif colorcode==2
  cmap=colormap(jet(14));
  if inputval<50
    colorvec=cmap(1,:);
  elseif inputval<100
    colorvec=cmap(2,:);
  elseif inputval<150
    colorvec=cmap(3,:);
  elseif inputval<200
    colorvec=cmap(4,:);
  elseif inputval<250
    colorvec=cmap(5,:);
  elseif inputval<300
    colorvec=cmap(6,:);
  elseif inputval<350
    colorvec=cmap(7,:);
  elseif inputval<400
    colorvec=cmap(8,:);
  elseif inputval<450
    colorvec=cmap(9,:);
  elseif inputval<500
    colorvec=cmap(10,:);
  elseif inputval<550
    colorvec=cmap(11,:);
  elseif inputval<600
    colorvec=cmap(12,:);
  elseif inputval<650
    colorvec=cmap(13,:); 
  else
    colorvec=cmap(14,:);
  end 
else
  cmap=colormap(jet(18));
  if inputval<10
    colorvec=cmap(1,:);
  elseif inputval<20
    colorvec=cmap(2,:);
  elseif inputval<30
    colorvec=cmap(3,:);
  elseif inputval<40
    colorvec=cmap(4,:);
  elseif inputval<50
    colorvec=cmap(5,:);
  elseif inputval<60
    colorvec=cmap(6,:);
  elseif inputval<70
    colorvec=cmap(7,:);
  elseif inputval<80
    colorvec=cmap(8,:);
  elseif inputval<90
    colorvec=cmap(9,:);
  elseif inputval<100
    colorvec=cmap(10,:);
  elseif inputval<110
    colorvec=cmap(11,:);
  elseif inputval<120
    colorvec=cmap(12,:);
  elseif inputval<130
    colorvec=cmap(13,:); 
  elseif inputval<140
    colorvec=cmap(14,:); 
  elseif inputval<150
    colorvec=cmap(15,:); 
  elseif inputval<160
    colorvec=cmap(16,:); 
  elseif inputval<170
    colorvec=cmap(17,:); 
  else
    colorvec=cmap(18,:);
  end
end

