%% This function is a wrap-up function to test findClosestBifPt.

clear;clc
systemName = 'case9static';
mpc = loadcase(systemName);
hfig = figure(1);

[mpc_out,finished] = findClosestBifPt(mpc,1,hfig);