function [timevector,outputz,outputy,outputx,outputh]=alignrmstimes(...
  timecell,inputyrs,inputz,inputy,inputx,inputh)
%
% Function to align the RMS ground displacement/velocity/acceleration, 
% computed for a number of years between 2017-2020. This is so the same
% index across all the years' RMS values correspond to the same weekday. 
% 
% Note: Data will be cut off from what is inputted so that the data 
% vectors for all inputted years are the same length.
% 
% Note 2: The times will be aligned based on the first weekday of the most 
% recently inputted year. For example, if the first weekday of the 2020
% RMS values is a Sunday, then the program will align the 2017-2019
% RMS values such that the first weekday of those years is also a Sunday
% (specifically the nearest Sunday within the available data).
% 
% 
% INPUTS
% timecell : A cell containing strings representing the times when the 
%           RMS displacement/velocity/acceleration were computed for 
%           each inputted year, in order of ascending year.
% 
%            A cell containing vectors containing the times when the 
%            RMS displacement/velocity/acceleration were computed for 
%            each inputted year, in order of ascending year. This should
%            have anywhere between 1-4 time vectors! 
% inputyrs : A vector listing the years over which the RMS values were
%            computed
% inputz : A cell containing the RMS displacement/velocity/acceleration
%          vectors in the Z (vertical) component, listed in order of 
%          ascending year. 
% inputy : A cell containing the RMS displacement/velocity/acceleration
%          vectors in the Y (North-South) component, listed in order of 
%          ascending year.
% inputx : A cell containing the RMS displacement/velocity/acceleration
%          vectors in the X (East-West) component, listed in order of 
%          ascending year.
% inputh : A cell containing the RMS displacement/velocity/acceleration
%          vectors in the horizontal component, listed in order of 
%          ascending year. Leave empty if we only want the X and Y 
%          components
% 
% OUTPUTS
% timevector : A vector listing the dates and times, including weekdays, 
%              of the most recent inputted year
% outputz : A matrix listing the RMS displacement/velocity/acceleration 
%           in the Z (vertical) component. Each row now corresponds to 
%           the same weekday across all years.
% outputy : A matrix listing the RMS displacement/velocity/acceleration 
%           in the Y (North-South) component, where each row corresponds
%           to the same weekday.
% outputx : A matrix listing the RMS displacement/velocity/acceleration 
%           in the X (East-West) component, where each row corresponds
%           to the same weekday.
% outputh : A matrix listing the RMS displacement/velocity/acceleration 
%           in the horizontal component, where each row corresponds
%           to the same weekday. This will be an empty array if we do not
%           input an inputh vector
%
% References
% Conversion from a datetime array to a cell array is a method I 
% learned from www.mathworks.com help forums
% 
% Last Modified by Yuri Tamama, 12/27/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Identify which year was most recently plotted;
allyrs=[2017 2018 2019 2020];
yrindex=[1 2 3 4];
recentyr=inputyrs(length(inputyrs));
recentind=yrindex(allyrs==recentyr);
% Vector of datetimes in the most recent year
recenttimes=timecell{recentind};
% oldestyr=inputyrs(1);
% oldestind=yrindex(allyrs==oldestyr);
% oldesttimes=timecell{oldestind};
% numtimes=length(oldesttimes);
% Identify the first weekday in the most recent year
recenttimes.Format='eeee dd-MMM-uuuu HH:mm:ss';
firstday=recenttimes(1);
firstday=cellstr(firstday);
firstday=strsplit(firstday{1});
firstwkday=firstday{1};

% Iterate through the years and find the first index with the same
% weekday
% Also find which year has the shortest data vector, so we cut the data
% vectors for all years to the same length! 
startindices=zeros(4,1);
startindices(recentind)=1;
minlen=-1;
for i=1:4
  if i==recentind
    continue;
  else
    if ismember(allyrs(i),inputyrs)
      timevec=timecell{i};
      timevec.Format='eeee dd-MMM-uuuu HH:mm:ss';
      % Find shortest vector
      if minlen<0
        minlen=length(timevec);
      else
        if length(timevec)<minlen
          minlen=length(timevec);
        end
      end
      % Find the first matching weekday as the most recent year
      for j=1:min(length(timevec),length(recenttimes))
        temptime=timevec(j);
        temptimestr=cellstr(temptime);
        temptimestr=strsplit(temptimestr{1});
        tempwkday=temptimestr{1};
        if strcmpi(tempwkday,firstwkday)
          startindices(i)=j;
          break;
        end
      end
    end
  end
end

% Note that the amount I need to "offset" the data will differ between 
% years, resulting in data vectors with different lengths... Work around
% that by figuring out where to cut the data vectors so they will end up
% with the same length!
latestart=max(startindices);
cutvals=1:length(latestart:minlen);

% Align and cut the data vectors!
timevector=recenttimes(cutvals);
outputx=zeros(length(cutvals),4);
outputy=zeros(length(cutvals),4);
outputz=zeros(length(cutvals),4);
if ~isempty(inputh)
  outputh=zeros(length(cutvals),4);   
else
  outputh=[];  
end    
for i=1:4
  if startindices(i)>0
    % Z
    modz=inputz{i};
    outputz(:,i)=modz(startindices(i):length(cutvals)+startindices(i)-1);
    % Y
    mody=inputy{i};
    outputy(:,i)=mody(startindices(i):length(cutvals)+startindices(i)-1); 
    % X
    modx=inputx{i};
    outputx(:,i)=modx(startindices(i):length(cutvals)+startindices(i)-1);
    % H
    if ~isempty(inputh)
      modh=inputh{i};
      outputh(:,i)=modh(startindices(i):length(cutvals)+startindices(i)-1);
    end    
  end
end

