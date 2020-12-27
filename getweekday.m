function weekdayname=getweekday(datetimeobj)
% 
% Function to retrieve the weekday corresponding to an inputted date.
% 
% INPUT
% datetimeobj : A datetime object
%            Default: datetime('today')
% 
% OUTPUT
% weekdayname : A string, for the name of the corresponding weekday
% 
% Last Modified by Yuri Tamama, 12/27/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

datetimeobj.Format='eeee dd-MMM-uuuu HH:mm:ss';
datetimestr=cellstr(datetimeobj);
datetimestr=strsplit(datetimestr{1});
weekdayname=datetimestr{1};
