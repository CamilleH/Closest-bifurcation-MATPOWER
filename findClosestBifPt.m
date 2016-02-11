function [mpc_out,finished] = findClosestBifPt(mpc,verbose)
% FINDCLOSESTBIFPT: this function finds the closest bifurcation point using Dobson's
% iterative method. At each iteration, a CPF is run from the base case
% loading in a specific direction that is determined by the normal to the
% bifurcation surface at the maximum loadability point at the previous 
% iteration. The process stops when two normals in two consecutive runs are
% close enough in terms of the angle between them.

%% Loading system case and defining parameters
define_constants;
nb_bus = size(mpc.bus,1);
nbIterMax = 20;
thresAngle = 1e-2;
angleNorm = pi/2;
if nargin == 1
    verbose = 0;
end

%% Initializing 
nonzero_loads = mpc.bus(:,PD)~=0;
normal = mpc.bus(nonzero_loads,PD);
normal = normal/norm(normal);
dir_mll = zeros(nb_bus,1);
nbIter = 0;
P0 = mpc.bus(nonzero_loads,PD);

if verbose
    fprintf('Iteration     Angle     Distance\n');
end

while nbIter < nbIterMax && angleNorm > thresAngle
    % Save the current normal
    normal_old = normal;
   
    % Run MLL problem
    dir_mll(nonzero_loads) = normal;
    results_mll = maxloadlim(mpc,dir_mll,'verbose',0,'use_qlim',0);
    
    % Compute the normal
    normal = get_normal(results_mll);
    
    % Plot
    Plim = results_mll.bus([5 7 9],PD)/results_mll.baseMVA;
    pt_to = Plim + normal;
    figure(hfig)
    hold on
    plot3(Plim(1),Plim(2),Plim(3),'or');    
    vectarrow(Plim,pt_to,'k');
    
    % Compute the angle between the old and new unit normals
    angleNorm = acos(dot(normal_old,normal));
    if verbose
        fprintf(1,'%6d       %6.5f      %.2f\n',nbIter,angleNorm,norm(Plim-P0));
    end
    nbIter = nbIter+1;
end
finished = nbIterMax > nbIter;
mpc_out = results_mll;