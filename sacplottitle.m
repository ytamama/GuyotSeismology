function titlestrs=sacplottitle(evttype,evtinfo)
%
% Function to return a title suitable for the plot of SAC data we
% are creating
%
% INPUTS
% evttype : What type of event is this plot for? 
%           0 : Ambient noise
%           1 : Earthquakes
%           2 : Campus blasts 
% evtinfo : Enter in info about the event as a cell array!
%           Ambient noise : {freqinfo; measval; header; stacode; 
%                            staloc; rmoutlier}
%                            freqinfo : The cell array of the frequencies
%                                       through which the data are filtered.
%                                       If we plot multiple sets of SAC 
%                                       files, each with a different 
%                                       frequency range, enter each vector 
%                                       in order!
%                            measval : 0 for measuring displacement, 1 for 
%                                      velocity, and 2 for acceleration
%                            header : Header of plotted SAC file
%                            stacode : Network and station code
%                            staloc : Short description of location
%                            rmoutlier : 2 element vector for how we remove
%                                        the outliers from the values
%                                        plotted (see plotsacdata.m)
%
%           Earthquake : {freqinfo; measval; IRIS event ID
%                         evlalo; magnitude; depth; staloc; stacode; 
%                         stalalo; distance (degrees); backazimuth; 
%                         fastsw; slowsw; rmoutlier} 
%                         event ID : Event ID of earthquake; enter as a 
%                                   number
%                         evlalo : [latitude longitude] of event
%                         stalalo: [latitude longitude] of station
%                         distance : Distance from event to station
%                         backazimuth : Back azimuth of event to station
%                         fastsw : Fast surface wave speed threshold, if 
%                                 plotting
%                         slowsw : Slow surface wave speed threshold, if 
%                                 plotting
% 
%           Campus blasts : {freqinfo; measval; header; stacode; staloc;
%                           rmoutlier}
%
% If any of the values above are unknown, enter an empty array!
% 
% OUTPUT
% titlestrs : Cell array containing the title for the plot
% 
% References:
% Referred to MATLAB help forums on www.mathworks.com
% The lat-lon coordinates of Guyot Hall are from guyotphysics.m, in 
% csdms-contrib/slepian_zero
% Uses IRIS's traveltime and distance-azimuth web services
% (see iristtimes.m, irisazimuth.m)
% Information about earthquakes is from the IRIS Data Management Center
% 
% Last Modified by Yuri Tamama, 10/27/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Collect info about the data being plotted
freqinfo=evtinfo{1};
if ~isempty(freqinfo)
  % Retrieve each frequency range  
  titlestrf='Filtered to';
  for f=1:length(freqinfo)  
    freqlimits=freqinfo{f};
    freqstr2=sprintf('%.2f',freqlimits(2));
    freqstr3=sprintf('%.2f',freqlimits(3)); 
    titlestrf=sprintf('%s %s to %s Hz',titlestrf,freqstr2,freqstr3);
    if f<length(freqinfo)
      titlestrf=sprintf('%s;',titlestrf);
    end    
  end   
else
  titlestrf='';
end
%
measval=evtinfo{2};
if measval==0
  vallabel='Displacement';
elseif measval==1
  vallabel='Velocity';
else
  vallabel='Acceleration';
end

% Make the title based on the event type
% Earthquake
if evttype==1
  evtid=evtinfo{3};
  evlalo=evtinfo{4};
  magnitude=evtinfo{5};
  depth=evtinfo{6};
  staloc=evtinfo{7};
  stacode=evtinfo{8};
  stalalo=evtinfo{9};
  % If available, this is the Great Circle distance from station to event
  % (degrees), computed using IRIS's travel time web service. Otherwise, 
  % (i.e. if the earthquake occurs "above ground"), then this is the 
  % geoid distance from station to event (degrees), computed using IRIS's
  % distance-azimuth web service
  distdeg=evtinfo{10};
  backazimuth=evtinfo{11};
  fastsw=evtinfo{12};
  slowsw=evtinfo{13};
  rmoutlier=evtinfo{14};
  
  % Calculate values or replace with default vallues, if necessary
  if isempty(staloc)
    staloc='Guyot Hall, Princeton University';
  end
  if isempty(stacode)
    stacode='PP.S0001';
  end
  if isempty(stalalo)
    stalalo=[40.34585 -74.65475];
  end
  if isempty(distdeg) && isempty(backazimuth)
    if depth>=0
      [backazimuth,~,~,~]=irisazimuth(evlalo,stalalo);   
      ttimetbl=iristtimes(evlalo,depth,'',stalalo);
      distdeg=ttimetbl.distdegs;
      distdeg=distdeg(1);
    else
      [backazimuth,~,distdeg,~]=irisazimuth(evlalo,stalalo);
    end
  elseif isempty(distdeg)
    if depth>=0
      ttimetbl=iristtimes(evlalo,depth,'',stalalo);
      distdeg=ttimetbl.distdegs;
      distdeg=distdeg(1);
    else
      [~,~,distdeg,~]=irisazimuth(evlalo,stalalo);
    end
  elseif isempty(backazimuth)
    [backazimuth,~,~,~]=irisazimuth(evlalo,stalalo);  
  end
  
  % Construct title
  locstr=irisevtloc(evtid);
  titlestr1=sprintf('IRIS ID %d (%s)',evtid,locstr);
  magstr=sprintf('Magnitude=%.1f ',magnitude);
  depstr=sprintf(' Depth=%.1f km',depth);
  deltastr=' \Delta';
  deltastr2=sprintf('=%.2f%s ',round(distdeg,2),char(176));
  backazstr=strcat(sprintf(' Back Azimuth=%.2f',backazimuth),char(176));
  titlestr2=strcat(magstr,depstr,deltastr,deltastr2,backazstr);  
  titlestr3=sprintf('%s at %s (%s)',vallabel,staloc,...
    replace(stacode,'.',' '));
  if ~isempty(fastsw) && ~isempty(slowsw)
    titlestrsw=sprintf(...
      'Upper (%g km/s) and Lower (%g km/s) Surface Wave Speeds in Magenta',...
      fastsw,slowsw);
  else
    titlestrsw='';
  end
  if ~isempty(rmoutlier)
    if rmoutlier(1)==0
      titlestrrm=sprintf('Bottom %g%% per File',rmoutlier(2));
    else
      titlestrrm=sprintf('No signals +/- %.2f MAD from the median',rmoutlier(2));
    end
  else
    titlestrrm='';
  end
  titlestrall={titlestr1;titlestr2;titlestr3;titlestrf;titlestrsw;...
    titlestrrm};

% Non-earthquake
else
  header=evtinfo{3};
  stacode=evtinfo{4};
  staloc=evtinfo{5};
  if isempty(staloc)
    staloc='Guyot Hall, Princeton University';
  end
  if isempty(stacode)
    stacode='PP.S0001';
  end
  yrstr=num2str(header.NZYEAR);  
  jdstr=datenum2str(header.NZJDAY,1);
  hrstr=datenum2str(header.NZHOUR,0);
  minstr=datenum2str(header.NZMIN,0);
  hdrsec=round(header.NZSEC+(header.NZMSEC/100),2);
  secstr=datenum2str(hdrsec,0);
  titlestr1=sprintf('Ground %s on %s JD %s %s:%s:%s GMT',...
    vallabel,yrstr,jdstr,hrstr,minstr,secstr);
  titlestr2=sprintf('Recorded at %s (%s)',staloc,replace(stacode,'.',' '));
  % Campus blast
  if evttype==2
    titlestrb='Campus Blast';
    titlestrall={titlestrb;titlestr1;titlestr2;titlestrf};
  % Ambient noise
  else
    titlestrall={titlestr1;titlestr2;titlestrf};
  end
end

% Get rid of what strings are empty
titlestrs={};
for i=1:length(titlestrall)
  teststr=titlestrall{i};
  if ~isempty(teststr)
    titlestrs=vertcat(titlestrs,teststr);
  end
end



