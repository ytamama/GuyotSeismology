function [timevector,outputz,outputy,outputx]=alignrmstimes(...
  timecell,inputyrs,inputz,inputy,inputx)
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
% inputyrs : A vector listing the years over which the RMS values were
%            computed
% inputz : A cell containing the RMS displacement/velocity/acceleration
%          vectors in the Z (vertical) component, listed in order of 
%          ascending year. 
% inputy : A cell containing the RMS displacement/velocity/acceleration
%          vectors in the Z (North-South) component, listed in order of 
%          ascending year.
% inputx : A cell containing the RMS displacement/velocity/acceleration
%          vectors in the Z (East-West) component, listed in order of 
%          ascending year.
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
%
% References
% Conversion from a datetime array to a cell array is a method I 
% learned from www.mathworks.com help forums
% 
% Last Modified by Yuri Tamama, 09/02/2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Identify which year was most recently plotted;
allyrs=[2017 2018 2019 2020];
yrindex=[1 2 3 4];
recentyr=inputyrs(length(inputyrs));
recentind=yrindex(allyrs==recentyr);
recenttimes=timecell{recentind};
oldestyr=inputyrs(1);
oldestind=yrindex(allyrs==oldestyr);
oldesttimes=timecell{oldestind};
numtimes=length(oldesttimes);

% Identify the first weekday
firstday=recenttimes(1);
firstday=strsplit(firstday{1});
firstwkday=firstday{1};

% Iterate through the years and find the first index with the year
startindices=zeros(4,1);
startindices(recentind)=1;
for i=1:4
  if i==recentind
    continue;
  else
    if ismember(allyrs(i),inputyrs)
      timevec=timecell{i};
      for j=1:numtimes
        temptime=timevec(j);
        temptimestr=strsplit(temptime{1});
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
cutvals=1:length(latestart:numtimes);

% Align and cut the data vectors!
timevec1=timecell{1};
timevec1=timevec1(startindices(1):length(timevec1));
timevec1=timevec1(cutvals);
timevec2=timecell{2};
timevec2=timevec2(startindices(2):length(timevec2));
timevec2=timevec2(cutvals);
timevec3=timecell{3};
timevec3=timevec3(startindices(3):length(timevec3));
timevec3=timevec3(cutvals);
timevec4=timecell{4};
timevec4=timevec4(startindices(4):length(timevec4));
timevec4=timevec4(cutvals);

timestrings=recenttimes(cutvals);
outputx=zeros(length(cutvals),4);
outputy=zeros(length(cutvals),4);
outputz=zeros(length(cutvals),4);
for i=1:4
  if startindices(i)>0
    % Z
    modz=inputz{i};
    modz=modz(startindices(i):length(modz));
    outputz(:,i)=modz(cutvals);
    % Y
    mody=inputy{i};
    mody=mody(startindices(i):length(mody));
    outputy(:,i)=mody(cutvals);    
    % X
    modx=inputx{i};
    modx=modx(startindices(i):length(modx));
    outputx(:,i)=modx(cutvals);
  end
end

% Convert the time strings in timevector to datetime objects!
timevector=[];
for i=1:length(timestrings)
  nowtimestr=timestrings{i};
  nowtime=datetime(nowtimestr,'InputFormat','eeee dd-MMM-uuuu HH:mm:ss');
  timevector=[timevector; nowtime];
end


