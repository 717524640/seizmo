function [pf]=slowdecaypairs(results,azrng,gcrng)
%SLOWDECAYPAIRS    Returns 2-station measurements of slowness & decay rate
%
%    Usage:    pf=slowdecaypairs(results,azrng,gcrng)
%
%    Description:
%     PF=SLOWDECAYPAIRS(RESULTS,AZRNG,GCRNG) takes the relative arrival
%     time and amplitude measurements contained in RESULTS produced by
%     CMB_1ST_PASS, CMB_CLUSTERING, CMB_OUTLIERS, or CMB_2ND_PASS and
%     calculates the slowness and decay rate between every pair of stations
%     within the criteria set by azimuthal range AZRNG and distance range
%     GCRNG.  Note that AZRNG & GCRNG are relative ranges, meaning an AZRNG
%     of [0 5] will find all pairs within 5 degrees of azimuth of one
%     another.  As a special case, if AZRNG is scalar then the value is
%     taken as the maximum azimuthal difference.  If GCRNG is scalar the
%     value is taken as the minimum degree distance.  The output PF is a
%     struct with as many elements as there are pairs found.  The format of
%     the PF struct is described in the Notes section below.
%
%    Notes:
%     - The PF struct has the following fields:
%       .gcdist         - degree distance difference between stations
%       .azwidth        - azimuthal difference between stations
%       .slow           - horizontal slowness (s/deg)
%       .slowerr        - horizontal slowness standard error
%       .decay          - decay rate
%       .decayerr       - decay rate standard error
%       .cslow          - corrected horizontal slowness***
%       .cslowerr       - corrected horizontal slowness standard error
%       .cdecay         - corrected decay rate
%       .cdecayerr      - corrected decay rate standard error
%       .cluster        - cluster id
%       .kname          - {net stn stream cmp}
%       .st             - [lat lon elev(m) depth(m)]
%       .ev             - [lat lon elev(m) depth(m)]
%       .delaz          - [degdist az baz kmdist]
%       .corrections    - traveltime & amplitude correction values
%       .corrcoef       - max correlation coefficient between waveforms
%       .synthetics     - TRUE if synthetic data (only reflect synthetics)
%       .earthmodel     - model used to make synthetics or 'DATA'
%       .freq           - filter corners of bandpass
%       .phase          - core-diffracted wave type
%       .runname        - name of this run, used for naming output
%       .dirname        - directory containing the waveforms
%       .time           - date string of time of this struct's creation
%
%      *** Correction is different between data and synthetics.  For data
%          the .cslow value is found by subtracting out the corrections
%          (and hence attempts to go from 3D to 1D by removing the lateral
%          heterogeniety).  For synthetics the .cslow value is essentially
%          the opposite (it is corrected to 3D).  So basically:
%                     +----------+---------------+
%                     |   DATA   |   SYNTHETICS  |
%            +--------+----------+---------------+
%            |  .slow |    3D    |       1D      |
%            +--------+----------+---------------+
%            | .cslow |    1D    |       3D      |
%            +--------+----------+---------------+
%
%    Examples:
%     % Return station pair profiles with an azimuth
%     % of <10deg and a distance of >15deg:
%     pf=slowdecaypairs(results,[0 10],[15 inf])
%
%     % This does the same as the last example:
%     pf=slowdecaypairs(results,10,15)
%
%    See also: PREP_CMB_DATA, CMB_1ST_PASS, CMB_OUTLIERS, CMB_2ND_PASS,
%              SLOWDECAYPROFILES

%     Version History:
%        Dec. 12, 2010 - initial version
%        Jan. 18, 2011 - update for results struct standardization, added
%                        corrections & correlation coefficients to output,
%                        time is now a string, require common event
%        Jan. 26, 2011 - pass on new .synthetics & .earthmodel fields,
%                        .cslow depends on .synthetics, added Notes
%                        about PF struct format
%        Jan. 29, 2011 - save output, fix corrections bug
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Jan. 29, 2010 at 13:35 GMT

% todo:

% check nargin
error(nargchk(3,3,nargin));

% check results struct
error(check_cmb_results(results));

% check azrng & gcrng
if(~isreal(azrng) || ~any(numel(azrng)==[1 2]))
    error('seizmo:slowdecaypairs:badInput',...
        'AZRNG must be [MINAZ MAXAZ] or MAXAZ!');
elseif(~isreal(gcrng) || ~any(numel(gcrng)==[1 2]))
    error('seizmo:slowdecaypairs:badInput',...
        'GCRNG must be [MINGC MAXGC] or MINGC!');
end

% expand scalar azrng & gcrng
if(isscalar(azrng)); azrng=[0 azrng]; end
if(isscalar(gcrng)); gcrng=[gcrng inf]; end

% verbosity
verbose=seizmoverbose;

% loop over every result
total=0;
for a=1:numel(results)
    % skip if results.useralign is empty
    if(isempty(results(a).useralign)); continue; end
    
    % number of records
    nrecs=numel(results(a).useralign.data);
    
    % extract header details
    [st,ev,delaz,kname]=getheader(results(a).useralign.data,...
        'st','ev','delaz','kname');
    
    % check event info matches
    ev=unique(ev,'rows');
    if(size(ev,1)>1)
        error('seizmo:slowdecaypairs:badInput',...
            'EVENT location varies between records!');
    end
    
    % corrected relative arrival times and amplitudes
    rtime=results(a).useralign.solution.arr;
    if(results(a).synthetics)
        % we add corrections here to go from 1D to 3D
        switch results(a).phase
            case 'Pdiff'
                crtime=results(a).useralign.solution.arr...
                    +results(a).corrections.ellcor...
                    +results(a).corrections.crucor.prem...
                    +results(a).corrections.mancor.hmsl06p.upswing;
            case {'SHdiff' 'SVdiff'}
                crtime=results(a).useralign.solution.arr...
                    +results(a).corrections.ellcor...
                    +results(a).corrections.crucor.prem...
                    +results(a).corrections.mancor.hmsl06s.upswing;
        end
    else % data
        % we subtract corrections here to go from 3D to 1D
        switch results(a).phase
            case 'Pdiff'
                crtime=results(a).useralign.solution.arr...
                    -results(a).corrections.ellcor...
                    -results(a).corrections.crucor.prem...
                    -results(a).corrections.mancor.hmsl06p.upswing;
            case {'SHdiff' 'SVdiff'}
                crtime=results(a).useralign.solution.arr...
                    -results(a).corrections.ellcor...
                    -results(a).corrections.crucor.prem...
                    -results(a).corrections.mancor.hmsl06s.upswing;
        end
    end
    rtimeerr=results(a).useralign.solution.arrerr;
    rampl=results(a).useralign.solution.amp;
    crampl=results(a).useralign.solution.amp...
        ./results(a).corrections.geomsprcor;
    ramplerr=results(a).useralign.solution.amperr;
    
    % get cluster indexing
    cidx=results(a).usercluster.T;
    good=results(a).usercluster.good;
    
    % get outliers
    outliers=results(a).outliers.bad;
    
    % get pairs within range (need the indices)
    dgc=abs(delaz(:,ones(nrecs,1))-delaz(:,ones(nrecs,1)).')...
        .*(triu(nan(nrecs),1)+tril(ones(nrecs),-1));
    daz=abs(delaz(:,2*ones(nrecs,1))-delaz(:,2*ones(nrecs,1)).')...
        .*(triu(nan(nrecs),1)+tril(ones(nrecs),-1));
    [idx1,idx2]=find(dgc>=gcrng(1) & dgc<=gcrng(2) ...
        & daz>=azrng(1) & daz<=azrng(2));
    
    % reduce to pairs in same cluster and not outliers
    gidx=cidx(idx1)==cidx(idx2) & ~outliers(idx1) & ~outliers(idx2) ...
        & ismember(cidx(idx1),find(good));
    idx1=idx1(gidx);
    idx2=idx2(gidx);
    npairs=numel(idx1);
    
    % initialize struct
    pf(total+(1:npairs))=struct('gcdist',[],'azwidth',[],...
        'slow',[],'slowerr',[],'decay',[],'decayerr',[],...
        'cslow',[],'cslowerr',[],'cdecay',[],'cdecayerr',[],...
        'cluster',[],'kname',[],'st',[],'ev',[],'delaz',[],...
        'corrections',[],'corrcoef',[],...
        'synthetics',results(a).synthetics,...
        'earthmodel',results(a).earthmodel,...
        'freq',results(a).filter.corners,'phase',results(a).phase,...
        'runname',results(a).runname,'dirname',results(a).dirname,...
        'time',datestr(now));
    
    % detail message
    if(verbose); print_time_left(0,npairs); end
    
    % loop over every pair, get values, fill in info
    for b=1:npairs
        % insert known info
        pf(total+b).cluster=cidx(idx1(b));
        pf(total+b).kname=kname([idx1(b) idx2(b)],:);
        pf(total+b).st=st([idx1(b) idx2(b)],:);
        pf(total+b).ev=ev;
        pf(total+b).delaz=delaz([idx1(b) idx2(b)],:);
        
        % great circle distance and width
        pf(total+b).gcdist=dgc(idx1(b),idx2(b));
        pf(total+b).azwidth=daz(idx1(b),idx2(b));
        
        % corrections
        pf(total+b).corrections=fixcorrstruct(results(a).corrections,...
            [idx1(b) idx2(b)]);
        
        % correlation coefficients
        pf(total+b).corrcoef=...
            submat(ndsquareform(results(a).useralign.xc.cg),...
            1,idx1(b),2,idx2(b),3,1);
        
        % find slowness & decay rate
        [m,covm]=wlinem(delaz([idx1(b) idx2(b)],1),...
            rtime([idx1(b) idx2(b)]),1,...
            diag(rtimeerr([idx1(b) idx2(b)]).^2));
        pf(total+b).slow=m(2);
        pf(total+b).slowerr=sqrt(covm(2,2));
        [m,covm]=wlinem(delaz([idx1(b) idx2(b)],1),...
            crtime([idx1(b) idx2(b)]),1,...
            diag(rtimeerr([idx1(b) idx2(b)]).^2));
        pf(total+b).cslow=m(2);
        pf(total+b).cslowerr=sqrt(covm(2,2));
        [m,covm]=wlinem(delaz([idx1(b) idx2(b)],1),...
            log(rampl([idx1(b) idx2(b)])),1,...
            diag(log(rampl([idx1(b) idx2(b)])...
            +ramplerr([idx1(b) idx2(b)]).^2)....
            -log(rampl([idx1(b) idx2(b)]))));
        pf(total+b).decay=m(2);
        pf(total+b).decayerr=sqrt(covm(2,2));
        [m,covm]=wlinem(delaz([idx1(b) idx2(b)],1),...
            log(crampl([idx1(b) idx2(b)])),1,...
            diag(log(crampl([idx1(b) idx2(b)])...
            +ramplerr([idx1(b) idx2(b)]).^2)...
            -log(crampl([idx1(b) idx2(b)]))));
        pf(total+b).cdecay=m(2);
        pf(total+b).cdecayerr=sqrt(covm(2,2));
        
        % detail message
        if(verbose); print_time_left(b,npairs); end
    end
    
    % save output
    tmp=pf(total+1:end);
    save([datestr(now,30) '_' results(a).runname '_pairs.mat'],'tmp');
    
    % increment total
    total=total+npairs;
end

end


function [s]=fixcorrstruct(s,good)
fields=fieldnames(s);
for i=1:numel(fields)
    if(isstruct(s.(fields{i})))
        s.(fields{i})=fixcorrstruct(s.(fields{i}),good);
    else
        s.(fields{i})=s.(fields{i})(good);
    end
end
end