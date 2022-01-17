function [num_cc,cc] = find_elem_centroids(...
    ee,nn)

num_ee = length(ee);
nn_p_ee = size(ee,2)-1;
label_idx =1;
x_idx=2;
y_idx=3;
z_idx=4;

% finds the centroid of the element (center of mass)
cc = zeros(num_ee,4);
x = zeros(1,nn_p_ee);
y = zeros(1,nn_p_ee);
z = zeros(1,nn_p_ee);

for elem_idx = 1:num_ee
    for node_idx = 2:nn_p_ee+1
        x(node_idx-1) = nn(ee(elem_idx,node_idx),x_idx);
        y(node_idx-1) = nn(ee(elem_idx,node_idx),y_idx);
        z(node_idx-1) = nn(ee(elem_idx,node_idx),z_idx);
    end
        
    %CENTROIDs(elem_idx,label_idx) = ELEMs(elem_idx,label_idx);
    cc(elem_idx,label_idx) = ee(elem_idx,1);    
    cc(elem_idx,x_idx) = sum(x)/nn_p_ee;
    cc(elem_idx,y_idx) = sum(y)/nn_p_ee;
    cc(elem_idx,z_idx) = sum(z)/nn_p_ee;    
    
    %trisurf(K,v(:,1),v(:,2),...
    %   v(:,3),'FaceAlpha',0.5); axis equal
    %hold on
    %scatter3hs(interal_ELEM_ID_IP_COORDS(interal_ELEM_ID_IP_COORDS(:,1)==internal_ELEM_ID_inside(elem_idx,1),2:4),'+r')
    %scatter3hs(CENTROIDs(elem_idx,2:4),'.b')
end

num_cc = size(cc,1);
