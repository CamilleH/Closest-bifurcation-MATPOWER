function [mpc_out,finished] = findClosestBifPt(mpc,varargin)
% FINDCLOSESTBIFPT: this function finds the closest bifurcation point using Dobson's
% iterative method. At each iteration, a CPF is run from the base case
% loading in a specific direction that is determined by the normal to the
% bifurcation surface at the maximum loadability point at the previous 
% iteration. The process stops when two normals in two consecutive runs are
% close enough in terms of the angle between them.

%% Checking the options, if any
input_checker = inputParser;

% verbose
default_verbose = 0;
verbose_levels = [0;1];
check_verbose = @(x)(isnumeric(x) && isscalar(x) && any(x == verbose_levels));
addParameter(input_checker,'verbose',default_verbose,check_verbose);

% Considers reactive power limits of generators
default_use_qlims = 0;
use_qlims_levels = [0;1];
check_use_qlims = @(x)(isnumeric(x) && isscalar(x) && any(x == use_qlims_levels));
addParameter(input_checker,'use_qlims',default_use_qlims,check_use_qlims);

% Check if handle hfig to figure has been given
default_hfig = 0;
check_hfig = @(x) isa(x,'matlab.ui.Figure'); 
addParameter(input_checker,'hfig',default_hfig,check_hfig);

% Check if a proper (symmetric matrix) covariance matrix has been given 
% (to find the most likely point, instead of finding the closest point)
default_cov = 0;
check_cov = @(x) (isnumeric(x) && ismatrix(x) && ...
    size(x,1) == size(x,2) && issymmetric(x));
addParameter(input_checker,'Sigma',default_cov,check_cov);

input_checker.KeepUnmatched = true;
parse(input_checker,varargin{:});

options = input_checker.Results;

%% Loading system case and defining parameters
define_constants;
nb_bus = size(mpc.bus,1);
nbIterMax = 20;
thresAngle = 1e-2;
angleNorm = pi/2;

%% Initializing 
nonzero_loads = mpc.bus(:,PD)~=0;
normal = mpc.bus(nonzero_loads,PD);
normal = normal/norm(normal);
dir_mll = zeros(nb_bus,1);
nbIter = 0;
P0 = mpc.bus(nonzero_loads,PD)/mpc.baseMVA;

if ~(isscalar(options.Sigma) && options.Sigma ~= 0)
    % Normalize the covariance matrix by base power
    options.Sigma = options.Sigma/mpc.baseMVA^2;
end

if options.verbose
    fprintf('Iteration     Angle     Distance\n');
end

% Plot the current point
if ~isempty(options.hfig)
    figure(options.hfig)
    hold on
    plot3(P0(1),P0(2),P0(3),'o','MarkerFaceColor','b','MarkerEdgeColor','b');
end

while nbIter < nbIterMax && angleNorm > thresAngle
    % Save the current normal
    normal_old = normal;
   
    % Run MLL problem
    dir_mll(nonzero_loads) = normal;
    results_mll = maxloadlim(mpc,dir_mll,'verbose',0,...
        'use_qlim',options.use_qlims);
    Plim = results_mll.bus([5 7 9],PD)/results_mll.baseMVA;
    
    % Compute the normal
    normal = get_normal(results_mll);
    if ~(isscalar(options.Sigma) && options.Sigma == 0)
        % Adjusting by projecting onto the covariance matrix, if any has been
        % given as inputs. Note that options.   
        normal = options.Sigma*normal;
        % Normalizing
        normal = normal/norm(normal);
    end
    
    % Plot iterations
    if ~isempty(options.hfig)
        pt_to = Plim + normal;
        figure(options.hfig)
        hold on
        plot3(Plim(1),Plim(2),Plim(3),'o','MarkerFaceColor','r','MarkerEdgeColor','r');
        vectarrow(Plim,pt_to,'k');
    end
    
    % Compute the angle between the old and new unit normals
    angleNorm = acos(dot(normal_old,normal));
    if options.verbose
        fprintf(1,'%6d       %6.5f      %.2f\n',nbIter,angleNorm,norm(Plim-P0));
    end
    nbIter = nbIter+1;
end
finished = nbIterMax > nbIter;
mpc_out = results_mll;