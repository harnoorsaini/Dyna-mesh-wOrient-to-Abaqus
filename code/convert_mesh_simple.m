close all
clear


% REQUIRES
% - mesh_files; manually split ls-dyna files into nodes and elems stripped
% of all keywords

%% -- raw read in
disp(' ')

%nf = strcat('mesh_files/','triceps_nodes.k');
%ef = strcat('mesh_files/','triceps_elem.k');
%nf = strcat('mesh_files/','biceps_nodes.k');
%ef = strcat('mesh_files/','biceps_elems.k');
nf = strcat('mesh_files/','brachialis_nodes.k');
ef = strcat('mesh_files/','brachialis_elems.k');


fid = fopen(nf, 'r');
n   = cell2mat(textscan(fid, '%f %f %f %f %f %f'));
fclose(fid);

fid = fopen(ef, 'r');
e   = cell2mat(textscan(fid, '%f %f %f %f %f %f %f %f %f'));
fclose(fid);

%% -- clean up
disp(' ')

nn = n(:,1:4);
disp('Assume 5 lines between element defitions')
ee(:,1) = e(1:5:length(e),1);
disp('Assume repeating nodes column 5 onwards ')
ee(:,2:5) = e(2:5:length(e),1:4); 

ff(:,1) = 1:length(ee);
ff(:,2:4) = e(4:5:length(e),1:3);
ff(:,5:7) = e(5:5:length(e),1:3);

disp('Renumbering nodes, elements & connectivity sequentially')
ee(:,1) = 1:length(ee);
n_rn_map = nn(:,1); % store mapping
nn(:,1) = 1:length(nn);
disp('Connectivity mapping...')
for e_idx = 1:length(ee)
    for n_idx = 2:size(ee,2)
        ee(e_idx,n_idx) = find(n_rn_map==ee(e_idx,n_idx));
    end
end


%% -- plotting
disp(' ')

[n_cc,cc] = find_elem_centroids(ee,nn);

skip = 20;
quiver3hs(cc(1:skip:end,2:4),ff(1:skip:end,2:4))
%hold on
%quiver3hs(cc(1:skip:end,2:4),ff(1:skip:end,5:7),'r')


%% -- coarsening

%% -- write out for abaqus input file
disp(' ')

disp('Writing out for Abaqus...')
disp('Nodes')
nf = strcat('output/','triceps_nodes.inp');
%fid = fopen(nf, 'w');
dlmwrite(nf,nn,'precision',8)


disp('Elements')
nf = strcat('output/','triceps_elems.inp');
dlmwrite(nf,ee,'precision','%d')

disp('Distribution')
nf = strcat('output/','triceps_dist.inp');
dlmwrite(nf,ff,'precision',10)








