function rfiles=rotsac(fnames,hdrinfo)
% 
% Function to rotate horizontal SAC files (in the North and East)
% to the radial and the transverse direction
% 
% INPUTS
% fnames : The names of the north and east direction SAC files, 
%          entered like so:
%          {esac; nsac} where
%          esac : East component SAC file
%          nsac : North component SAC file
% hdrinfo : Is there any information we need in the header before rotating
%           our files? 
%           If so, enter in this order:
%           [evla, evlo, stla, stlo], where
%           evla : Event latitude
%           evlo : Event longitude
%           stla : Station latitude
%           stlo : Station longitude 
%           Note: If we only want to input the station latitude and 
%                 longitude, enter -360 in indices 1 and 2 of this array
%           Note 2: You either input one set of coordinates, all, or none
% 
% OUTPUTS
% rfiles : The rotated SAC files, entered in this order : 
%          {rfile; tfile}
%          rfile : Radial component SAC file
%          tfile : Transverse component SAC file
%
% References
% Uses SAC comamnds, found in the SAC manual
% Referred to the SAC tutorial by Zhigang Peng
% Calling SAC from MATLAB from mcms2mat.m in csdms-contrib/slepian_oscar
% Uses defval.m, in csdms-contrib/slepian_alpha
% 
% Last Modified by Yuri Tamama, 09/28/2020
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
defval('hdrinfo',[])

% Form the file names for our radial and transverse SAC files
esac=fnames{1};
nsac=fnames{2};
rsac=replace(esac,'HHX','HHR');
tsac=replace(nsac,'HHY','HHT');
% Input station and/or event coordinates if necessary
if ~isempty(hdrinfo)
  if length(hdrinfo)==4
    chhdr=sprintf(' EVLA %g EVLO %g STLA %g STLO %g',...
      hdrinfo(1),hdrinfo(2),hdrinfo(3),hdrinfo(4));
  elseif length(hdrinfo)==2
    if hdrinfo(1)==-360
      chhdr=sprintf(' STLA %g STLO %g',hdrinfo(1),hdrinfo(2));
    else
      chhdr=sprintf(' EVLA %g EVLO %g',hdrinfo(1),hdrinfo(2));
    end
  end
else
  chhdr='';
end

% Set the component inclination to 90 degrees for both files
lalocmd=sprintf(...
  'echo "r %s %s ; chnhdr%s CMPINC 90 ; w %s %s ; q" | /usr/local/sac/bin/sac',...
  nsac,esac,chhdr,nsac,esac);
[status,cmdout]=system(lalocmd);
% Define CMPAZ 
azcmdn=sprintf(...
  'echo "r %s ; chnhdr CMPAZ 0 ; wh ; q" | /usr/local/sac/bin/sac',...
  nsac);
[status,cmdout]=system(azcmdn);
azcmde=sprintf(...
  'echo "r %s ; chnhdr CMPAZ 90 ; wh ; q" | /usr/local/sac/bin/sac',...
  esac);
[status,cmdout]=system(azcmde);
% Rotate from XYZ to RTZ
rotcmd=sprintf(...
  'echo "r %s %s ; rotate to GCP ; w %s %s ; q" | /usr/local/sac/bin/sac',...
  nsac,esac,rsac,tsac);
[status,cmdout]=system(rotcmd);

% Return the RTZ files
rfiles={rsac;tsac};

