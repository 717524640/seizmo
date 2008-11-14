function [times]=serial2gregorian(serial,option)
%SERIAL2GREGORIAN    Convert serial dates to Gregorian dates
%
%    Description: SERIAL2GREGORIAN(DATES) returns the equivalent Gregorian
%     dates for the serial dates stored in DATES.  A serial date of 1
%     corresponds to Jan 1, 0000.
%
%     SERIAL2GREGORIAN(DATES,OPTION) allows specifying the output format.
%      OPTION        OUTPUT
%       'caldate' =>  [year month dayofmonth]
%       'caltime' =>  [year month dayofmonth hour minute seconds]
%       'doydate' =>  [year dayofyear]
%       'doytime' =>  [year dayofyear hour minute seconds]
%
%    Notes:
%     - Does not account for UTC leap seconds
%     - Basically like Matlab's DATEVEC except that it also outputs day of
%       year style dates but does not handle string input.
%
%    Tested on: Matlab r2007b
%
%    Usage:    dates=serial2gregorian(dates)
%
%    Examples:
%     See how long it takes to run serial2gregorian vs datevec:
%      serial2gregorian(now)-datevec(now)
%      datevec(now)-datevec(now)
%
%    See also: gregorian2serial, isleapyear, doy2cal, cal2doy, fixdates

%     Version History:
%        Nov.  11, 2008 - initial version
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Nov. 11, 2008 at 16:45 GMT

% todo:

% check nargin
error(nargchk(1,2,nargin));

% check times
if(~isnumeric(serial))
    error('SAClab:gregorian2serial:badInput',...
        'DATES must be a numeric array!');
end

% check option
if(nargin==1 || isempty(option))
    option='caltime';
elseif(~ischar(option)...
        || ~any(strcmpi(option,{'caldate' 'caltime' 'doydate' 'doytime'})))
    error('SAClab:gregorian2serial:optionBad',...
        ['OPTION must be ''caldate'', ''caltime'', '...
        '''doydate'' or ''doytime''!']);
end
    
% expand
sz=size(serial);
serial=reshape(serial,[prod(sz(1:2)) 1 sz(3:end)]);

% get year
yr=floor(serial/365.2425);
newserial=serial-(365*yr+fix(yr/4)-fix(yr/100)+fix(yr/400));
low=newserial<1;
if(any(low(:)))
    yr(low)=yr(low)-1;
    serial(low)=serial(low)...
        -(365*yr(low)+fix(yr(low)/4)-fix(yr(low)/100)+fix(yr(low)/400));
end
serial(~low)=newserial(~low);
clear newserial

% convert
switch lower(option)
    case 'caldate'
        times=nan([prod(sz(1:2)) 3 sz(3:end)]);
        ndays=[0 31 59 90 120 151 181 212 243 273 304 334]+1;
        times(:,1,:)=yr;
        ndays2=ndays(ones(prod(sz(1:2)),1),:,ones(prod(sz(3:end)),1));
        leap=isleapyear(times(:,1,:));
        ndays2(:,3:end,:)=ndays2(:,3:end,:)+leap(:,ones(1,10),:);
        times(:,2,:)=sum(serial(:,ones(12,1),:)>=ndays2,2);
        times(:,3,:)=serial(:,1,:)...
            -ndays(times(:,2,:))-(leap & times(:,2,:)>2)+1;
    case 'caltime'
        times=nan([prod(sz(1:2)) 6 sz(3:end)]);
        ndays=[0 31 59 90 120 151 181 212 243 273 304 334]+1;
        times(:,1,:)=yr;
        ndays2=ndays(ones(prod(sz(1:2)),1),:,ones(prod(sz(3:end)),1));
        leap=isleapyear(times(:,1,:));
        ndays2(:,3:end,:)=ndays2(:,3:end,:)+leap(:,ones(1,10),:);
        times(:,2,:)=sum(serial(:,ones(12,1),:)>=ndays2,2);
        times(:,3,:)=fix(serial(:,1,:))...
            -ndays(times(:,2,:))-(leap & times(:,2,:)>2)+1;
        serial=mod(serial,1);
        times(:,4,:)=fix(serial*24);
        serial=serial-times(:,4,:)/24;
        times(:,5,:)=fix(serial*1440);
        serial=serial-times(:,5,:)/1440;
        times(:,6,:)=serial*86400;
    case 'doydate'
        times=nan([prod(sz(1:2)) 2 sz(3:end)]);
        times(:,1,:)=yr;
        times(:,2,:)=serial;
    case 'doytime'
        times=nan([prod(sz(1:2)) 5 sz(3:end)]);
        times(:,1,:)=yr;
        times(:,2,:)=fix(serial);
        serial=serial-times(:,2,:);
        times(:,3,:)=fix(serial*24);
        serial=serial-times(:,3,:)/24;
        times(:,4,:)=fix(serial*1440);
        serial=serial-times(:,4,:)/1440;
        times(:,5,:)=serial*86400;
end

end