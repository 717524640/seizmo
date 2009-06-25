function y=logspacen(xb,xe,n)
%LOGSPACEN Logarithmically Spaced Array.
% LOGSPACEN(X1,X2,N) where X1 and X2 are scalars generates a row
% vector of N logarithmically equally spaced points between
% decades 10^X1 and 10^X2. Let X2=LOG10(pi) to stop at pi.
%
% If X1 and X2 are row vectors of the same size, LOGSPACEN(X1,X2,N)
% creates a matrix having N rows where the i-th column of the result
% contains N logarithmically equally spaced points between
% decades 10^X1(i) and 10^X2(i).
%
% If X1 and X2 are column vectors of the same size, LOGSPACEN(X1,X2,N)
% creates a matrix having N columns where the i-th row of the result
% contains N logarithmically equally spaced points between
% decades 10^X1(i) and 10^X2(i).
%
% For N-D and equal-sized X1 and X2, LOGSPACEN(X1,X2,N) expands the
% first singleton dimension of X1 and X2 to N elements containing N
% logarithmically equally spaced points between the corresponding 
% elements of decades 10^X1 and 10^X2.
%
% If N is not provided, N=50 is used.
%
% See also: LOGSPACE, LINSPACEN,LINSPACE

% D.C. Hanselman, University of Maine, Orono ME 04469
% 11/14/01
% Mastering MATLAB 6, Prentice Hall, ISBN 0-13-019468-9

if nargin==2
   n=50;
elseif n<2
   error('N Must be at Least 2.')
end
xbsiz=size(xb);
xesiz=size(xe);
nxb=numel(xb);
nxe=numel(xe);
if nxb==1 && nxe==1 % conventional logspace
   y=(10).^[xb+(0:n-2)*(xe-xb)/(n-1) xe];
   return
elseif nxb==1 && nxe~=1  % scalar expand xb
   xb=repmat(xb,xesiz);
   xbsiz=xesiz;
   nxb=numel(xb);
elseif nxb~=1 && nxe==1  % scalar expand xe
   xe=repmat(xe,xbsiz);
elseif xbsiz~=xesiz
   error('X1 and X2 Must be the Same Size')
end

xsiz=[xbsiz 1];
dim=min(find(xsiz==1));          % first singleton dimension
perm=[dim:ndims(xb)+1 1:dim-1];  % put dim first

xb=permute(xb,perm);          % permute so dim is row dimension
xb=reshape(xb,1,nxb);         % reshape into a row array
xe=permute(xe,perm);          % permute so dim is row dimension
xe=reshape(xe,1,nxb);         % reshape into a row array

y=[cumsum([xb; repmat((xe-xb)/(n-1),n-2,1)],1); xe];

xsiz(dim)=n;                  % new size of dim dimension
y=reshape(y,xsiz(perm));      % put result back in original form
y=(10).^ipermute(y,perm);     % inverse permute and spread out