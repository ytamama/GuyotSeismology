function getdispdata(yyyy,mm,dd)
%
%Program to generate .mat files of seismic data over a span of multiple
%days within a given year and month
%Calls upon mcms2mat.m, by Professor Simons, in
%https://github.com/csdms-contrib/slepian_oscar
%
%INPUTS
%yyyy - year of seismic data
%mm - month of seismic data
%dd - range of days for which we want .mat files (e.g. 1:5)
%
%OUTPUTS
%.mat files of seismic data, one per hour
%
%last modified by Yuri Tamama, April 16, 2020


%set inputs for mcms2mat.m
HH=0:23;
MM=00;
SS=00;
qp=0;    %no plots!
pdf=0;
of=1;
numdays=length(dd);

for i = 1:numdays
    %produce .mat files for every hour
    mcms2mat(yyyy,mm,dd(i),HH,MM,SS,qp,pdf,of);  
end

end

