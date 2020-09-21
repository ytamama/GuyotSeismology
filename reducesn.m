function [newdata,prcval]=reducesn(datavec)
% 
% Function that takes in a vector of numerical values and iteratively
% removes the top 0.5% of signals (i.e. start from 99.5%, then 99%, then
% 89.5%, and so on of the original data) from the absolute values of 
% the data until the signal to noise amplitude ratio is below 2.5. 
% 
% The signal to noise ratio is computed by comparing the maximum
% absolute value of the data to the median absolute value
%
% INPUTS
% datavec : Vector of numerical values
% 
% OUTPUTS
% newdata : The vector, with the top X% of values (i.e. at or above
%           that percentile) replaced with NaN
% prcval : A number indicating that the bottom X% of data remain
% 
% Last Modified by Yuri Tamama, 09/21/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

prcval=100;
ston=100;
while ston>2.5
  datamed=median(abs(datavec));
  maxval=prctile(abs(datavec),prcval);
  ston=maxval/datamed;
  if ston<=2.5  
    newdata=datavec;
    if prcval<100
      newdata(abs(newdata)>=maxval)=NaN;
    end
    return
  else
    prcval=prcval-0.1;
  end
end






