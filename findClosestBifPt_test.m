%% This function is a wrap-up function to test findClosestBifPt.

close all;clear;clc
systemName = 'case9static';
caseName = 'loads568';
c=0;
dirCPF = [0;1;0];

Pclosest = findClosestBifPt(systemName,caseName,c,dirCPF);