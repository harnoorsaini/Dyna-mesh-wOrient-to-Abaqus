function [dyna_elem,fib_angle_to_y,fib_angle_to_y_new] = modify_pennation_angle(offset, PA_change_deg, elemchangename,dyna_elem)

    
    % coordinate system - projection of vector onto the Y-Z plane
    %
    %  Z|
    %   | 
    %   | 
    %   | 
    %   |_ _ _ _ _ Y
    % 
    % for dyna_elem matrix
    idx_x = 2;
    idx_y = 3;
    idx_z = 4;    
    
    % extract y- & z- coordinates & normalise them
    yz_coord = dyna_elem(:,idx_y:idx_z);
    for i = 1:size(yz_coord)
        yz_coord(i,:) = yz_coord(i,:)/norm(yz_coord(i,:));
    end
    
    
    % aponeuorsis angle defined to Z-angle; find the corresponding aponeurosis angle
    % to y-axis
    offset_to_y = 90 - offset;
    
    % find the angle of all fibres to the aponeurosis
    % cos(theta) = A/H; and since |H| = 1, theta = acos(A)
    fib_angle_to_y = acos(yz_coord(:,1));
    fib_angle_to_y_offset = fib_angle_to_y - deg2rad(offset_to_y);
   
    if offset > 0;
        disp '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
        disp 'THE ORIGINAL ANGLE HAS BEEN ADJUSTED'      
        disp '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    end

    % convert the change in PA angle to radians
    PA_change = deg2rad(PA_change_deg);

    % ONLY change elements in the below defined list
    if ~exist(elemchangename, 'file')
        error('elem change file does not exist');
    end
    change_elems = csvread(elemchangename);
    change_elems = reshape(change_elems ,[size(change_elems ,1)*size(change_elems ,2),1]);

    str_L_idx = 1;
    str_R_idx = 1;
    for i = 1:size(change_elems,1)-1
        % set current element ID (note that dyna_elem row number
        % corresponds to the element number)
       elem_idx = change_elems(i);
       if elem_idx > 0
           % store current y & z coordinates of the fibre orientation
           y_curr = yz_coord(elem_idx,1);
           z_curr = yz_coord(elem_idx,2);
           %
           % if the angle-to-y < 0 -> right side of apo -> decrease
           if fib_angle_to_y_offset(elem_idx) < 0
              % store original angle
              store_R_angle(str_R_idx) = fib_angle_to_y_offset(elem_idx);
              % negative rotation on y-z direction
              yz_coord(elem_idx,1) = y_curr*cos(-PA_change)-z_curr*sin(-PA_change);
              yz_coord(elem_idx,2) = y_curr*sin(-PA_change)+z_curr*cos(-PA_change);
              
              % find the new rotated PA angle R
              fib_angle_to_y_new = acos(yz_coord(elem_idx,1));
              
              % if the z-coordinate now is positive; then the new PA  =
              if yz_coord(elem_idx,2) > 0
                store_R_angle_new(str_R_idx) = deg2rad(offset_to_y) - fib_angle_to_y_new;
              % else if the z-coordinate is negative, then the apo angle
              % needs to be added on
              elseif yz_coord(elem_idx,2) < 0
                store_R_angle_new(str_R_idx) = deg2rad(offset_to_y) + fib_angle_to_y_new;
              end
                  
              str_R_idx = str_R_idx + 1;  
              % > 0 -> left side -> increase
           elseif fib_angle_to_y_offset(elem_idx) > 0 
              store_L_angle(str_L_idx) = fib_angle_to_y_offset(elem_idx);
              yz_coord(elem_idx,1) = y_curr*cos(PA_change)-z_curr*sin(PA_change);
              yz_coord(elem_idx,2) = y_curr*sin(PA_change)+z_curr*cos(PA_change);
              
              % new PA angle L
              fib_angle_to_y_new = acos(yz_coord(elem_idx,1));
              if yz_coord(elem_idx,1) > 0
                store_L_angle_new(str_L_idx) = fib_angle_to_y_new - deg2rad(offset_to_y);
              elseif yz_coord(elem_idx,1) < 0
                store_L_angle_new(str_L_idx) = fib_angle_to_y_new + deg2rad(90) - deg2rad(offset_to_y);  
              end
              
              str_L_idx = str_L_idx + 1; 
           end
           
           % udpate the coordinate values in original element stack
           dyna_elem(elem_idx,idx_y)=yz_coord(elem_idx,1);
           dyna_elem(elem_idx,idx_z)=yz_coord(elem_idx,2);
           
           % renormalise coordinates
           dyna_elem(elem_idx,idx_x:idx_z) = dyna_elem(elem_idx,idx_x:idx_z)/norm(dyna_elem(elem_idx,idx_x:idx_z)); 
          
       end    
    end

    fib_angle_to_y_new = acos(yz_coord(:,1));
    
    Avg_PA = (abs(rad2deg(mean(store_R_angle))) + abs(rad2deg(mean(store_L_angle))) )/ 2;
    Avg_PA_new = (abs(rad2deg(mean(store_R_angle_new))) + abs(rad2deg(mean(store_L_angle_new))) )/ 2;
