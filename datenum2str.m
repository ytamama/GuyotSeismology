function datenumstr=datenum2str(datenumber,jdornot)
% 
% Function that takes in a number pertaining to a date (e.g. hour, 
% day) and outputs a string-formatted version of the date number 
% where the tens place is a zero if the number is less than 10
% 
% INPUT
% datenumber : A number pertaining to a date
% jdornot : Whether or not that number is a Julian day
%           0 for no (default)
%           1 for yes 
% 
% OUTPUT
% datenumstr : The date number but as a string
% 
% See num2str
% 
% References:
% Uses defval.m in csdms-contrib/slepian_alpha
% 
% Last modified by Yuri Tamama, 12/27/2020
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Default values
defval('jdornot',0);

if jdornot == 0
  if datenumber < 10
    datenumstr=sprintf('0%d',datenumber);
  else
    datenumstr=num2str(datenumber);
  end  
else
  if datenumber < 10
    datenumstr=sprintf('00%d',datenumber);
  elseif datenumber < 100
    datenumstr=sprintf('0%d',datenumber);  
  else
    datenumstr=num2str(datenumber);
  end     
end    


