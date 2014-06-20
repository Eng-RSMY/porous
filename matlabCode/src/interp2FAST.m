function [zi,iflag] = interp2FAST(varargin)
%INTERP2 2-D interpolation (table lookup).
%   ZI = INTERP2(X,Y,Z,XI,YI) interpolates to find ZI, the values of the
%   underlying 2-D function Z at the points in matrices XI and YI.
%   Matrices X and Y specify the points at which the data Z is given.
%
%   XI can be a row vector, in which case it specifies a matrix with
%   constant columns. Similarly, YI can be a column vector and it 
%   specifies a matrix with constant rows. 
%
%   ZI = INTERP2(Z,XI,YI) assumes X=1:N and Y=1:M where [M,N]=SIZE(Z).
%   ZI = INTERP2(Z,NTIMES) expands Z by interleaving interpolates between
%   every element, working recursively for NTIMES.  INTERP2(Z) is the
%   same as INTERP2(Z,1).
%
%   ZI = INTERP2(...,METHOD) specifies alternate methods.  The default
%   is linear interpolation.  Available methods are:
%
%     'nearest' - nearest neighbor interpolation
%     'linear'  - bilinear interpolation
%     'spline'  - spline interpolation
%     'cubic'   - bicubic interpolation as long as the data is
%                 uniformly spaced, otherwise the same as 'spline'
%
%   For faster interpolation when X and Y are equally spaced and monotonic,
%   use the syntax ZI = INTERP2(...,*METHOD).
%
%   ZI = INTERP2(...,METHOD,EXTRAPVAL) specificies a method and a scalar 
%   value for ZI outside of the domain created by X and Y.  Thus, ZI will
%   equal EXTRAPVAL for any value of YI or XI which is not spanned by Y 
%   or X respectively. A method must be specified for EXTRAPVAL to be used,
%   the default method is 'linear'.
%
%   All the interpolation methods require that X and Y be monotonic and
%   plaid (as if they were created using MESHGRID).  If you provide two
%   monotonic vectors, interp2 changes them to a plaid internally. 
%   X and Y can be non-uniformly spaced.
%
%   For example, to generate a coarse approximation of PEAKS and
%   interpolate over a finer mesh:
%       [x,y,z] = peaks(10); [xi,yi] = meshgrid(-3:.1:3,-3:.1:3);
%       zi = interp2(x,y,z,xi,yi); mesh(xi,yi,zi)
%
%   Class support for inputs X, Y, Z, XI, YI:  
%      float: double, single
%
%   See also INTERP1, INTERP3, INTERPN, MESHGRID, TriScatteredInterp.

%   Copyright 1984-2010 The MathWorks, Inc.
%   $Revision: 5.33.4.23 $  $Date: 2010/11/17 11:29:29 $

uniform = true;

narg = nargin-1;
method = [varargin{end} '    ']; % Protect against short string.
ExtrapVal = nan; % setting default ExtrapVal as NAN


[msg,x,y,z,xi,yi] = xyzchk(varargin{1:5});
x = varargin{1};
y = varargin{2};
z = varargin{3};
xi = varargin{4};
yi = varargin{5};


% Now do the interpolation based on method.
if strncmpi(method,'l',1) || strncmpi(method,'bil',3) % bilinear interpolation.
    zi = linear(ExtrapVal,x,y,z,xi,yi);

elseif strncmpi(method,'c',1) || strncmpi(method,'bic',3) % bicubic interpolation
    if uniform
        [zi,iflag] = cubic(ExtrapVal,x,y,z,xi,yi);
    else
        zi = spline2(x,y,z,xi,yi,ExtrapVal);
    end

elseif strncmpi(method,'n',1) % Nearest neighbor interpolation
    zi = nearest(ExtrapVal,x,y,z,xi,yi);

elseif strncmpi(method,'s',1) % Spline interpolation
    % A column is removed from z if it contains a NaN.
    % Orient to preserve as much data as possible.
    [inan, jnan] = find(isnan(z));
    ncolnan = length(unique(jnan));
    nrownan = length(unique(inan));
    if ncolnan > nrownan
        zi = spline2(y',x',z',yi,xi,ExtrapVal);
    else
        zi = spline2(x,y,z,xi,yi,ExtrapVal);
    end
else
    error(message('MATLAB:interp2:InvalidMethod', deblank( method )));

end

%------------------------------------------------------
function F = linear(ExtrapVal,arg1,arg2,arg3,arg4,arg5)
%LINEAR 2-D bilinear data interpolation.
%   ZI = LINEAR(EXTRAPVAL,X,Y,Z,XI,YI) uses bilinear interpolation to
%   find ZI, the values of the underlying 2-D function in Z at the points
%   in matrices XI and YI.  Matrices X and Y specify the points at which
%   the data Z is given.  X and Y can also be vectors specifying the
%   abscissae for the matrix Z as for MESHGRID. In both cases, X
%   and Y must be equally spaced and monotonic.
%
%   Values of EXTRAPVAL are returned in ZI for values of XI and YI that are
%   outside of the range of X and Y.
%
%   If XI and YI are vectors, LINEAR returns vector ZI containing
%   the interpolated values at the corresponding points (XI,YI).
%
%   ZI = LINEAR(EXTRAPVAL,Z,XI,YI) assumes X = 1:N and Y = 1:M, where
%   [M,N] = SIZE(Z).
%
%   ZI = LINEAR(EXTRAPVAL,Z,NTIMES) returns the matrix Z expanded by
%   interleaving bilinear interpolates between every element, working
%   recursively for NTIMES. LINEAR(EXTRAPVAL,Z) is the same as
%   LINEAR(EXTRAPVAL,Z,1).
%
%   See also INTERP2, CUBIC.

if nargin==2 % linear(extrapval,z), Expand Z
    [nrows,ncols] = size(arg1);
    s = 1:.5:ncols; lengths = length(s);
    t = (1:.5:nrows)'; lengtht = length(t);
    s = repmat(s,lengtht,1);
    t = repmat(t,1,lengths);
    
elseif nargin==3 % linear(extrapval,z,n), Expand Z n times
    [nrows,ncols] = size(arg1);
    ntimes = floor(arg2);
    s = 1:1/(2^ntimes):ncols; lengths = length(s);
    t = (1:1/(2^ntimes):nrows)'; lengtht = length(t);
    s = repmat(s,lengtht,1);
    t = repmat(t,1,lengths);

elseif nargin==4 % linear(extrapval,z,s,t), No X or Y specified.
    [nrows,ncols] = size(arg1);
    s = arg2; t = arg3;

elseif nargin==5
    error(message('MATLAB:interp2:linear:nargin'));

elseif nargin==6 % linear(extrapval,x,y,z,s,t), X and Y specified.
    [nrows,ncols] = size(arg3);
    mx = numel(arg1); my = numel(arg2);
    if (mx ~= ncols || my ~= nrows) && ~isequal(size(arg1),size(arg2),size(arg3))
        error(message('MATLAB:interp2:linear:XYZLengthMismatch'));
    end
    if nrows < 2 || ncols < 2
        error(message('MATLAB:interp2:linear:sizeZ'));
    end
    s = 1 + (arg4-arg1(1))/(arg1(end)-arg1(1))*(ncols-1);
    t = 1 + (arg5-arg2(1))/(arg2(end)-arg2(1))*(nrows-1);

end

if nrows < 2 || ncols < 2
    error(message('MATLAB:interp2:linear:sizeZsq'));
end
if ~isequal(size(s),size(t))
    error(message('MATLAB:interp2:linear:XIandYISizeMismatch'));
end

% Check for out of range values of s and set to 1
sout = find((s<1)|(s>ncols));
if ~isempty(sout), s(sout) = 1; end

% Check for out of range values of t and set to 1
tout = find((t<1)|(t>nrows));
if ~isempty(tout), t(tout) = 1; end

% Matrix element indexing
ndx = floor(t)+floor(s-1)*nrows;

% Compute intepolation parameters, check for boundary value.
if isempty(s), d = s; else d = find(s==ncols); end
s(:) = (s - floor(s));
if ~isempty(d), s(d) = s(d)+1; ndx(d) = ndx(d)-nrows; end

% Compute intepolation parameters, check for boundary value.
if isempty(t), d = t; else d = find(t==nrows); end
t(:) = (t - floor(t));
if ~isempty(d), t(d) = t(d)+1; ndx(d) = ndx(d)-1; end

% Now interpolate.
onemt = 1-t;
if nargin==6,
    F =  ( arg3(ndx).*(onemt) + arg3(ndx+1).*t ).*(1-s) + ...
         ( arg3(ndx+nrows).*(onemt) + arg3(ndx+(nrows+1)).*t ).*s;
else
    F =  ( arg1(ndx).*(onemt) + arg1(ndx+1).*t ).*(1-s) + ...
         ( arg1(ndx+nrows).*(onemt) + arg1(ndx+(nrows+1)).*t ).*s;
end

% Now set out of range values to ExtrapVal.
if ~isempty(sout), F(sout) = ExtrapVal; end
if ~isempty(tout), F(tout) = ExtrapVal; end

%------------------------------------------------------
function [F,iflag] = cubic(ExtrapVal,arg1,arg2,arg3,arg4,arg5)
%CUBIC 2-D bicubic data interpolation.
%   CUBIC(...) is the same as LINEAR(....) except that it uses
%   bicubic interpolation.
%
%   This function needs about 7-8 times SIZE(XI) memory to be available.
%
%   See also LINEAR.

%   Based on "Cubic Convolution Interpolation for Digital Image
%   Processing", Robert G. Keys, IEEE Trans. on Acoustics, Speech, and
%   Signal Processing, Vol. 29, No. 6, Dec. 1981, pp. 1153-1160.
iflag = 0;

if nargin==2, % cubic(extrapval,z), Expand Z
    [nrows,ncols] = size(arg1);
    s = 1:.5:ncols; lengths = length(s);
    t = (1:.5:nrows)'; lengtht = length(t);
    s = repmat(s,lengtht,1);
    t = repmat(t,1,lengths);
    
elseif nargin==3, % cubic(extrapval,z,n), Expand Z n times
    [nrows,ncols] = size(arg1);
    ntimes = floor(arg2);
    s = 1:1/(2^ntimes):ncols; lengths = length(s);
    t = (1:1/(2^ntimes):nrows)'; lengtht = length(t);
    s = repmat(s,lengtht,1);
    t = repmat(t,1,lengths);

elseif nargin==4, % cubic(extrapval,z,s,t), No X or Y specified.
    [nrows,ncols] = size(arg1);
    s = arg2; t = arg3;

elseif nargin==5,
    error(message('MATLAB:interp2:cubic:nargin'));

elseif nargin==6, % cubic(extrapval,x,y,z,s,t), X and Y specified.
    [nrows,ncols] = size(arg3);
    mx = numel(arg1); my = numel(arg2);
    if (mx ~= ncols || my ~= nrows) && ~isequal(size(arg1),size(arg2),size(arg3))
        error(message('MATLAB:interp2:cubic:XYZLengthMismatch'));
    end
    if nrows < 3 || ncols < 3
        error(message('MATLAB:interp2:cubic:sizeZ'));
    end
    s = 1 + (arg4-arg1(1))/(arg1(end)-arg1(1))*(ncols-1);
    t = 1 + (arg5-arg2(1))/(arg2(end)-arg2(1))*(nrows-1);
    if arg4 ~= arg4
      iflag = 1;
    end
    if arg5 ~= arg5
      iflag = 1;
    end


end

if iflag == 0
  if nrows < 3 || ncols < 3
      error(message('MATLAB:interp2:cubic:sizeZsq'));
  end
  if ~isequal(size(s),size(t)),
      error(message('MATLAB:interp2:cubic:XIandYISizeMismatch'));
  end

  % Check for out of range values of s and set to 1
  sout = find((s<1)|(s>ncols));
  if ~isempty(sout), s(sout) = 1; end

  % Check for out of range values of t and set to 1
  tout = find((t<1)|(t>nrows));
  if ~isempty(tout), t(tout) = 1; end

  % Matrix element indexing
  ndx = floor(t)+floor(s-1)*(nrows+2);

  % Compute intepolation parameters, check for boundary value.
  if isempty(s), d = s; else d = find(s==ncols); end
  s(:) = (s - floor(s));
  if ~isempty(d), s(d) = s(d)+1; ndx(d) = ndx(d)-nrows-2; end

  % Compute intepolation parameters, check for boundary value.
  if isempty(t), d = t; else d = find(t==nrows); end
  t(:) = (t - floor(t));
  if ~isempty(d), t(d) = t(d)+1; ndx(d) = ndx(d)-1; end

  if nargin==6,
      % Expand z so interpolation is valid at the boundaries.
      zz = zeros(size(arg3)+2);
      zz(1,2:ncols+1) = 3*arg3(1,:)-3*arg3(2,:)+arg3(3,:);
      zz(2:nrows+1,2:ncols+1) = arg3;
      zz(nrows+2,2:ncols+1) = 3*arg3(nrows,:)-3*arg3(nrows-1,:)+arg3(nrows-2,:);
      zz(:,1) = 3*zz(:,2)-3*zz(:,3)+zz(:,4);
      zz(:,ncols+2) = 3*zz(:,ncols+1)-3*zz(:,ncols)+zz(:,ncols-1);
      nrows = nrows+2; %also ncols = ncols+2;
  else
      % Expand z so interpolation is valid at the boundaries.
      zz = zeros(size(arg1)+2);
      zz(1,2:ncols+1) = 3*arg1(1,:)-3*arg1(2,:)+arg1(3,:);
      zz(2:nrows+1,2:ncols+1) = arg1;
      zz(nrows+2,2:ncols+1) = 3*arg1(nrows,:)-3*arg1(nrows-1,:)+arg1(nrows-2,:);
      zz(:,1) = 3*zz(:,2)-3*zz(:,3)+zz(:,4);
      zz(:,ncols+2) = 3*zz(:,ncols+1)-3*zz(:,ncols)+zz(:,ncols-1);
      nrows = nrows+2; %also ncols = ncols+2;
  end

  % Now interpolate using computationally efficient algorithm.
  t0 = ((2-t).*t-1).*t;
  t1 = (3*t-5).*t.*t+2;
  t2 = ((4-3*t).*t+1).*t;
  t(:) = (t-1).*t.*t;
  F     = ( zz(ndx).*t0 + zz(ndx+1).*t1 + zz(ndx+2).*t2 + zz(ndx+3).*t ) ...
      .* (((2-s).*s-1).*s);
  ndx(:) = ndx + nrows;
  F(:)  = F + ( zz(ndx).*t0 + zz(ndx+1).*t1 + zz(ndx+2).*t2 + zz(ndx+3).*t ) ...
      .* ((3*s-5).*s.*s+2);
  ndx(:) = ndx + nrows;
  F(:)  = F + ( zz(ndx).*t0 + zz(ndx+1).*t1 + zz(ndx+2).*t2 + zz(ndx+3).*t ) ...
      .* (((4-3*s).*s+1).*s);
  ndx(:) = ndx + nrows;
  F(:)  = F + ( zz(ndx).*t0 + zz(ndx+1).*t1 + zz(ndx+2).*t2 + zz(ndx+3).*t ) ...
      .* ((s-1).*s.*s);
  F(:) = F/4;
  % Now set out of range values to ExtrapVal.
  if ~isempty(sout), F(sout) = ExtrapVal; end
  if ~isempty(tout), F(tout) = ExtrapVal; end
else
  F = 0;
end


%------------------------------------------------------
function F = nearest(ExtrapVal,arg1,arg2,arg3,arg4,arg5)
%NEAREST 2-D Nearest neighbor interpolation.
%   ZI = NEAREST(EXTRAPVAL,X,Y,Z,XI,YI) uses nearest neighbor interpolation
%   to find ZI, the values of the underlying 2-D function in Z at the points
%   in matrices XI and YI.  Matrices X and Y specify the points at which
%   the data Z is given.  X and Y can also be vectors specifying the
%   abscissae for the matrix Z as for MESHGRID. In both cases, X
%   and Y must be equally spaced and monotonic.
%
%   Values of EXTRAPVAL are returned in ZI for values of XI and YI that are
%   outside of the range of X and Y.
%
%   If XI and YI are vectors, NEAREST returns vector ZI containing
%   the interpolated values at the corresponding points (XI,YI).
%
%   ZI = NEAREST(EXTRAPVAL,Z,XI,YI) assumes X = 1:N and Y = 1:M, where
%   [M,N] = SIZE(Z).
%
%   F = NEAREST(EXTRAPVAL,Z,NTIMES) returns the matrix Z expanded by
%   interleaving interpolates between every element.  NEAREST(EXTRAPVAL,Z)
%   is the same as NEAREST(EXTRAPVAL,Z,1).
%
%   See also INTERP2, LINEAR, CUBIC.

if nargin==2, % nearest(z), Expand Z
    [nrows,ncols] = size(arg1);
    u = 1:.5:ncols; lengthu = length(u);
    v = (1:.5:nrows)'; lengthv = length(v);
    u = repmat(u,lengthv,1);
    v = repmat(v,1,lengthu);

elseif nargin==3, % nearest(z,n), Expand Z n times
    [nrows,ncols] = size(arg1);
    ntimes = floor(arg2);
    u = 1:1/(2^ntimes):ncols; lengthu = length(u);
    v = (1:1/(2^ntimes):nrows)'; lengthv = length(v);
    u = repmat(u,lengthv,1);
    v = repmat(v,1,lengthu);

elseif nargin==4, % nearest(z,u,v)
    [nrows,ncols] = size(arg1);
    u = arg2; v = arg3;

elseif nargin==5,
    error(message('MATLAB:interp2:nearest:nargin'));

elseif nargin==6, % nearest(x,y,z,u,v), X and Y specified.
    [nrows,ncols] = size(arg3);
    mx = numel(arg1); my = numel(arg2);
    if (mx ~= ncols || my ~= nrows) && ...
            ~isequal(size(arg1),size(arg2),size(arg3))
        error(message('MATLAB:interp2:nearest:XYZLengthMismatch'));
    end
    if nrows > 1 && ncols > 1
        u = 1 + (arg4-arg1(1))/(arg1(mx)-arg1(1))*(ncols-1);
        v = 1 + (arg5-arg2(1))/(arg2(my)-arg2(1))*(nrows-1);
    else
        u = 1 + (arg4-arg1(1));
        v = 1 + (arg5-arg2(1));
    end
end

if ~isequal(size(u),size(v))
    error(message('MATLAB:interp2:nearest:XIandYISizeMismatch'));
end

% Check for out of range values of u and set to 1
uout = (u<.5)|(u>=ncols+.5);
anyuout = any(uout(:));
if anyuout, u(uout) = 1; end

% Check for out of range values of v and set to 1
vout = (v<.5)|(v>=nrows+.5);
anyvout = any(vout(:));
if anyvout, v(vout) = 1; end

% Interpolation parameters
u = round(u); v = round(v);

% Now interpolate
ndx = v+(u-1)*nrows;
if nargin==6,
    F = arg3(ndx);
else
    F = arg1(ndx);
end

% Now set out of range values to ExtrapVal.
if anyuout, F(uout) = ExtrapVal; end
if anyvout, F(vout) = ExtrapVal; end

%----------------------------------------------------------
function F = spline2(varargin)
%2-D spline interpolation

% Determine abscissa vectors
varargin{1} = varargin{1}(1,:);
varargin{2} = varargin{2}(:,1).';

%
% Check for plaid data.
%
xi = varargin{4}; yi = varargin{5};
xxi = xi(1,:); yyi = yi(:,1);

if ~isequal(repmat(xxi,size(xi,1),1),xi) || ...
        ~isequal(repmat(yyi,1,size(yi,2)),yi)
    F = splncore(varargin(2:-1:1),varargin{3},varargin(5:-1:4));
else
    F = splncore(varargin(2:-1:1),varargin{3},{yyi(:).' xxi},'gridded');
end

ExtrapVal = varargin{6};
% Set out-of-range values to ExtrapVal
if isnumeric(ExtrapVal)
    d = xi < min(varargin{1}) | xi > max(varargin{1}) | ...
        yi < min(varargin{2}) | yi > max(varargin{2});
    F(d) = ExtrapVal;
end
