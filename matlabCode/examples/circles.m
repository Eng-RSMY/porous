addpath ../src

load radii.dat;
load centers.dat;
%centers = centers(433,:);
%radii = radii(433);

prams.Nouter = 1024;
% number of points on outer solid wall
prams.Ninner = 256;
% number of points per circle exclusion
prams.nv = 465;
% number of exclusions
prams.gmresTol = 1e-8;
% gmres tolerance
prams.maxIter = min(2*(prams.Nouter + prams.nv*prams.Ninner),1500);
% maximum number of gmres iterations
prams.atol = 1e-6;
prams.rtol = 1e-3;
% absolute and relative tolerances for ode45
prams.T = 100;
% time horizon for ode45
prams.ntime = 5001;
% number of time steps that ode45 will output

% Different options
options.bieSolve = false;
options.computeEuler = true;
options.tracersSimulation = true;
options.axis = [-0.5 5.5 0 30];
%options.axis = [3.65 3.8 23.95 24.15];
%options.axis = [-0.5 5.5 15 30];
%options.axis = [3.5 4.5 23.8 24.5];
options.axis = [-0.1 5.1 0 30];
options.dataFile = 'output/circlesData.bin';
options.farField = 'circles';
options.fmm = true;
options.logFile = 'output/circles.log';
options.profile = false;
options.saveData = true;
options.usePlot = false;
options.verbose = true;

oc = curve;
Xouter = oc.initConfig(prams.Nouter,'square');
% outer most boundary
Xinner = oc.initConfig(prams.Ninner,'circles', ...
          'nv',prams.nv, ...
          'center',centers, ...
          'radii',radii);
% circular exclusions

if options.profile
  profile off; profile on;
end

if options.bieSolve
  stokesSolver(Xinner,Xouter,options,prams);
end
% solve density function and write to .bin files.  It this calculation
% has already ben done, everything can be loaded in tracers to do the
% Lagrange tracker simulation.




if options.tracersSimulation
%  [xtar,ytar] = meshgrid(linspace(0.2,4.8,200),linspace(30,30,1));
%  [xtar,ytar] = meshgrid(linspace(0.3,4.3,200),linspace(30,30,1));
  [xtar,ytar] = meshgrid(linspace(2,2,1),linspace(30,30,1));
%  xtar = [4.2]; ytar = [30];
  X0 = [xtar(:);ytar(:)];
  % initial tracer locations
  fileName = 'output/circlesData.bin';
  % file that has all the necessary density function and geometry stored
  options.xmin = 0.25;
  options.xmax = 4.53;
  options.nx = 800;
  % min, max, and number of Euler locations in x direction
  options.ymin = 0;
  options.ymax = 33;
  options.ny = 7200;
  % min, max, and number of Euler locations in y direction
  options.nparts = 5;
  % need to compute in sections otherwise seem to run out of memory
%  options.ymThresh = options.ymin + 2;
  options.ymThresh = options.ymin + 0;
  options.ypThresh = options.ymax - 2;
  % thresholds where velocity will be set to zero

  [time,xtra,ytra] = tracers(X0,options,prams,fileName);
  % simulate tracers. Each column represents a tracer and each row
  % represents the time variable
end



if options.profile
  profile off;
  filename = [options.logFile(1:end-4) 'Profile'];
  profsave(profile('info'),filename);
end
% save the profile


