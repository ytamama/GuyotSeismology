function newcsv=adjrms(oldcsvs,newname,valtype,starttime,finaltime,tzone)
%
% Function to return a CSV file, whose contents are either a part of or a 
% combination of CSV files. The CSV file inputted is of guyotrmsseishr.m, 
% or vairmshr.m, recording the RMS hourly ground motion or weather 
% phenomenon. We specify a certain starting and ending time interval 
% for which we collect the data from the inputted CSV files to make
% a new CSV file. 
% 
% INPUTS
% oldcsvs : Name(s) of the CSV files to input, entered as a cell array
%           in chronological order 
% newname : Name of our new CSV file, which will contain the data from 
%           'oldcsv' spanning our desired time span. 
% valtype : Do the CSV files record a weather phenomenon (recorded by the
%           Vaisala WXT 530 weather station with the Septentrio PolaRx5 
%           receiver at Guyot Hall) or seismic data (recorded by a 
%           broadband Nanometrics three-component seismometer at Guyot
%           Hall)?
%
%           0 : Seismic data (default)
%           1 : Weather data
%
% starttime : From what time do we start our time series (inclusive)? 
%             If plotting 'day' or 'hr' (rmstype=0 or 1), input a 
%             datetime vector in local time. 
%             If plotting 'qrt' (rmstype=2), input a number from 0-23 
%             signifying an hour (in UTC time)
% finaltime : At what time do we end our time series (inclusive)?
%             If plotting 'day' or 'hr' (rmstype=0 or 1), input a 
%             datetime vector in local time. 
%             If plotting 'qrt' (rmstype=2), input a number from 0-23 
%             signifying an hour (in UTC time)
% tzone : The MATLAB time zone in which the dates are specified for the 
%         inputted CSV files
%
% OUTPUT
% newcsv : Our new CSV file, containing a subset of the RMS data recorded
%          in the original CSV file
%
% References
% Uses defval.m, in csdms-contrib/slepian_alpha
%
% Last Modified by Yuri Tamama, 10/18/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set default values
defval('valtype',0)

% Load and concatenate data for all files
for f=1:length(oldcsvs)
  csvfile=oldcsvs{f};
  data=readtable(csvfile,'Delimiter',',');
  outputtimes=data.outputtimes;
  outputtimes=datetime(outputtimes,'InputFormat','eeee dd-MMM-uuuu HH:mm:ss');
  outputtimes.TimeZone=tzone;
  if valtype==0
    rmsx=data.rmsx;
    rmsy=data.rmsy;
    rmsh=data.rmsh;
    rmsz=data.rmsz;
    if f==1 
      datatbl=table(outputtimes,rmsx,rmsy,rmsh,rmsz);
    else
      temptbl=table(outputtimes,rmsx,rmsy,rmsh,rmsz);
      datatbl=vertcat(datatbl,temptbl);
    end 
  else
    outputvec=data.outputvec;  
    if f==1 
      datatbl=table(outputtimes,outputvec);
    else
      temptbl=table(outputtimes,outputvec);
      datatbl=vertcat(datatbl,temptbl);
    end 
  end
end

% Sort datatbl and filter from starttime to finaltime
datatbl=sortrows(datatbl,1);
datatbl=datatbl(datatbl.outputtimes>=starttime & datatbl.outputtimes<=finaltime,:);
% Write to new CSV file
writetable(datatbl,newname)
newcsv=newname;


