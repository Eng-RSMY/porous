addpath ../src

load radii.dat;
load centers.dat;
%centers = centers(433,:);
%radii = radii(433);

prams.Ninner = 64;
% number of points per circle exclusion
prams.nv = 50;
% number of exclusions

oc = curve;
X = oc.initConfig(prams.Ninner,'circles', ...
          'nv',prams.nv, ...
          'center',centers, ...
          'radii',radii);
% circular exclusions

nearestDistance = zeros(prams.nv,1);

z = X(1:end/2,:) + 1i*X(end/2+1:end,:);
zcen = centers(:,1) + 1i*centers(:,2);
for k = 1:prams.nv
  [~,s] = min(abs(zcen(k) - zcen([(1:k-1) (k+1:prams.nv)])));
  if s >= k
    s = s+1;
  end
end


