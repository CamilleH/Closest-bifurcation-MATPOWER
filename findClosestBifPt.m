function outputs = findClosestBifPt(systemName,caseName,c,dir0)
% FINDCLOSESTBIFPT: this function finds the closest bifurcation point using Dobson's
% iterative method. At each iteration, a CPF is run from the base case
% loading in a specific direction that is determined by the normal to the
% bifurcation surface at the maximum loadability point at the previous 
% iteration. The process stops when two normals in two consecutive runs are
% close enough in terms of the angle between them.

nbIterMax = 20;
thresAngle = 1e-2;

normal = dir0;
angleNorm = pi/2;
nbIter = 0;

optionsCPF.chooseStartPoint = 0;

if c==0
    sysToLoad = systemName;
else
    sysToLoad = sprintf('%s_cont%d',systemName,c);
end

% load the file
mpc = openCase(sysToLoad);
P0 = mpc.bus([5 6 8],3);
hfig = ch_loadFigure;
figure(hfig)
hold on
plot3(P0(1),P0(2),P0(3),'ok','MarkerFaceColor','r'),
fprintf('Iteration     Angle     Distance\n');

while nbIter < nbIterMax && angleNorm > thresAngle
    % Save the current normal
    normal_old = normal;
    optionsCPF.dirCPF = normal;
    
    % Run CPF
    resultsCPF = ch_CPF_Dyn(systemName,caseName,c,optionsCPF);
    
    % Compute the normal
    resultsCorr = ch_processAfterCPF(systemName,caseName,c,optionsCPF,resultsCPF);
    normal = resultsCorr.currSurf.normalLoad;
    
    % Plot
    Plim = resultsCPF.bus([5 6 8],3);
    figure(hfig)
    hold on
    plot3(Plim(1),Plim(2),Plim(3),'or');
    
    % Compute the angle between the old and new unit normals
    angleNorm = acos(dot(normal_old,normal));
    fprintf(1,'%6d       %6.3f      %.2f\n',nbIter,angleNorm,norm(Plim-P0));
    nbIter = nbIter+1;
end
outputs = Plim;
end