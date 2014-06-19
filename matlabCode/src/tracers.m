function [time,xtra,ytra] = tracers(X0,options,prams,fileName)

om = monitor(options,prams);

[Ninner,Nouter,nv,Xinner,Xouter,sigmaInner,sigmaOuter] = ...
    om.loadGeometry(fileName);
% load all the information about the geometry and density function
if ((prams.Ninner == Ninner) + ...
      (prams.Nouter == Nouter) + (prams.nv == nv))~=3
  message = 'Saved data does not match input parameters';
  om.writeMessage(message);
  message = 'I am stopping';
  om.writeMessage(message);
  return
end

innerGeom = capsules(Xinner,'inner');
outerGeom = capsules(Xouter,'outer');
% build objects for the inner and outer boundaries

fmm = options.fmm;
op = poten(Ninner,fmm);

xmin = options.xmin; xmax = options.xmax; nx = options.nx;
ymin = options.ymin; ymax = options.ymax; ny = options.ny;
nparts = options.nparts;

if options.computeEuler
  [eulerX,eulerY] = ...
      meshgrid(linspace(xmin,xmax,nx),linspace(ymin,ymax,ny));
  % build the Eulerian grid that is used to interpolate in the time
  % integrator

  cutoff = ceil(numel(eulerX)/nparts);
  eX = eulerX(:); eY = eulerY(:);

  tic
  vel = zeros(2*numel(eX),1);
  for k = 1:nparts
    istart = (k-1)*cutoff + 1;
    iend = min(istart + cutoff - 1,numel(eX));
%    disp([istart iend])
    velPart = op.layerEval(0,[eX(istart:iend);eY(istart:iend)],...
        options.ymThresh,options.ypThresh,...
        innerGeom,outerGeom,sigmaInner,sigmaOuter);
    vel(istart:iend) = velPart(1:end/2);
    vel((istart:iend)+numel(eX)) = velPart(end/2+1:end);
  end
  % evalute velocity on an Eulerian grid
  om.writeStars
  message = '****   Velocity found on Eulerian Grid   ****';
  om.writeMessage(message);
  message = ['**** Required time was ' num2str(toc,'%4.2e') ...
      ' seconds  ****'];
  om.writeMessage(message);
  om.writeStars
  om.writeMessage(' ');

  u = reshape(vel(1:end/2),size(eulerX));
  v = reshape(vel(end/2+1:end),size(eulerY));
  % put velocity field in format that works well for interp2
  om.writeEulerVelocities(eulerX,eulerY,u,v);
  % save the velocity field so we don't have to keep recomputing it
else
  fileName1 = [fileName(1:end-8) 'EulerVelocities.bin'];
  [ny,nx,eulerX,eulerY,u,v] = om.loadEulerVelocities(fileName1);
  if (nx ~= options.nx || ny ~= options.ny)
    message = 'Saved Euler grid does not match input parameters';
    om.writeMessage(message);
    message = 'Just an FYI';
    om.writeMessage(message);
  end
end

xtra = []; ytra = []; time = [];

if 1
odeFun = @(t,z) op.interpolateLayerPot(t,z,eulerX,eulerY,u,v,prams.T);
% function handle that evalutes the right-hand side 
tic
opts.RelTol = prams.rtol;
opts.AbsTol = prams.atol;

ntra = numel(X0)/2;
Xtra = zeros(prams.ntime,2*ntra);
for k = 1:numel(X0)/2
  x0 = X0(k);
  y0 = X0(k+numel(X0)/2);
  [time,z] = ode45(odeFun,linspace(0,prams.T,prams.ntime),[x0;y0],opts);
  Xtra(:,k) = z(:,1);
  Xtra(:,k+ntra) = z(:,2);
end
%[time,Xtra] = ode45(odeFun,linspace(0,prams.T,prams.ntime),X0,opts);
om.writeMessage(' ');

om.writeStars
message = '****       Tracer locations found        ****';
om.writeMessage(message);
message = ['**** Required time was ' num2str(toc,'%4.2e') ...
    ' seconds  ****'];
om.writeMessage(message);
om.writeStars
om.writeMessage(' ');

xtra = Xtra(:,1:end/2);
ytra = Xtra(:,end/2+1:end);

if options.usePlot
  om.plotData;
  om.runMovie;
end

om.writeTracerPositions(time,xtra,ytra);
fileName1 = [fileName(1:end-8) 'TracerPositions.bin'];
%[ntime,ntra,time,xtra,ytra] = ...
%    om.loadTracerPositions(fileName1);

end

