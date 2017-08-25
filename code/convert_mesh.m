    % Convert LS-DYNA 3D Tetrahedral mesh with material orientation to Abaqus
% Harnoor Saini
%
% Step 0) Run fibre mapping workflow (E. Ramasamy) - output is by default
% "mappedmesh.k"
%
% Step 1) Import *.k part using LS-PrePost and export as *.nastran file and 
%         place in folder "nastran_output"
%
% Step 2) Import *.nastran file in Abaqus/CAE and write out *.inp file. The
%         fibre orientation information will be missing.
%
% Step 3) Place the *.inp file from 3) into the folder
%         "abaqus_inp_no_orient"
% 
% The resulting *.inp file will be generated and placed in folder "output"
%

read_original = 1;


if read_original
    close all
    clear
    read_original = 1;
end

write = 0;


% KEY
V0 = 'TA_dyna';
V1 = 'ep2d_mddw12_right_TA';
V2 = 'ep2d_mddw12_right_TA_isolated';
%%% \/\/ CURRENT CHOICE \/\/ %%%
V3 = '270717_ep2d_mddw12_right_TA_isolated';
%%% /\/\ CURRENT CHOICE /\/\ %%%
V4 = '040817_ep2d_mddw12_right_TA';

fname = V3;
change_angle = 1;
PA_change_deg = 2;

%% 
if read_original 

    % open original DYNA file and read lines
    disp 'Reading LS-DYNA file...'
    lsname = strcat(fname,'.k');
    lsdirname = strcat('mesh_files/',lsname);
    if ~exist(lsdirname, 'file')
        error('LS-DYNA file does not exist');
    end

    dyna_mesh = importdyna_mesh(lsdirname);

    % extract orientation information
    % skip over all nodes
    nodes = 1;
    lnum = 1;
    lskip = 0;

    % read in nodes 
    while nodes
        if isnan(dyna_mesh{lnum,1})
            % skip header
            lnum = lnum + 1;
        else
            nNumber = dyna_mesh{lnum,1};
            dyna_nodes(nNumber,1) = nNumber;
            lnum = lnum + 1;        
            if isnan(dyna_mesh{lnum,1})
                % end of nodes
                nodes = 0;
            end
        end
    end

    % read in elements
    elem_lineNum = lnum+2;
    dyna_elem((nNumber-2)*3,6) = zeros; % always the case... ?
    aDone = 0;
    while lnum < size(dyna_mesh,1)+1
        if isnan(dyna_mesh{lnum,1})
            % skip text rows
            lnum = lnum + 1;
        elseif mod(dyna_mesh{lnum,1}/1,1) == 0
            % element number
            eNumber = dyna_mesh{lnum,1};
            dyna_elem(eNumber,1) = eNumber;
            lnum = lnum + 1;
        else
            if ~aDone
                dyna_elem(eNumber,2) = dyna_mesh{lnum,1};
                dyna_elem(eNumber,3) = dyna_mesh{lnum,2};
                dyna_elem(eNumber,4) = dyna_mesh{lnum,3};
                aDone = 1;
            else
                dyna_elem(eNumber,5) = dyna_mesh{lnum,1};
                dyna_elem(eNumber,6) = dyna_mesh{lnum,2};
                dyna_elem(eNumber,7) = dyna_mesh{lnum,3};           
                aDone = 0;
            end

            lnum = lnum + 1;
        end
    end

    dyna_elem_original = dyna_elem;

end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% CHANGE FIBRE ORIENATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% START%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if change_angle 

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

    
    offset = 82.61;
    % -
    offset_to_y = 90 - offset;
    % -
    
    % cos(theta) = A/H; and since |H| = 1, theta = acos(A)
    % -
    fib_angle_to_y = acos(yz_coord(:,1));
    fib_angle_to_z = acos(yz_coord(:,2));
    fib_angle_to_y_offset = fib_angle_to_y - deg2rad(offset_to_y);
    % -
    angles_rad = acos(dyna_elem(:,idx_x:idx_z));
    angles_rad(:,3) = angles_rad(:,3)-deg2rad(offset);
    
    if offset > 0;
        disp '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
        disp 'THE ORIGINAL ANGLE HAS BEEN ADJUSTED'      
        disp '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    end


    PA_change = deg2rad(PA_change_deg);

    % ONLY change elements in the below defined list
    elemchangename = 'elem_include/270717_ep2d_mddw12_right_TA_isolated.txt';
    if ~exist(elemchangename, 'file')
        error('elem change file does not exist');
    end
    change_elems = csvread(elemchangename);
    change_elems = reshape(change_elems ,[size(change_elems ,1)*size(change_elems ,2),1]);

    str_L_idx = 1;
    str_R_idx = 1;
    for i = 1:size(change_elems,1)-1
       elem_idx = change_elems(i);
       if elem_idx > 0
           % -
           y_curr = yz_coord(elem_idx,1);
           z_curr = yz_coord(elem_idx,2);
           % < 0 -> right side -> decrease
           if fib_angle_to_y_offset(elem_idx) < 0
              store_R_angle(str_R_idx) = fib_angle_to_y_offset(elem_idx);
              yz_coord(elem_idx,1) = y_curr*cos(-PA_change)-z_curr*sin(-PA_change);
              yz_coord(elem_idx,2) = y_curr*sin(-PA_change)+z_curr*cos(-PA_change);
              
              % new PA angle R
              fib_angle_to_y_new = acos(yz_coord(elem_idx,1));
              if yz_coord(elem_idx,2) > 0
                store_R_angle_new(str_R_idx) = fib_angle_to_y_new - deg2rad(offset_to_y);
              elseif yz_coord(elem_idx,2) < 0
                store_R_angle_new(str_R_idx) = fib_angle_to_y_new + deg2rad(offset_to_y);
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
                store_L_angle_new(str_L_idx) = fib_angle_to_y_new + deg2rad(offset_to_y);  
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
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% CHANGE FIBRE ORIENATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% END %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%

if write

    % open abaqus no orient input file
    disp 'Reading ABAQUS no orientation file...'

    abaname = strcat(fname,'.inp');
    abadirname_in = strcat('abaqus_inp_no_orient/',abaname);
    if ~exist(abadirname_in, 'file')
        error('Abaqus no-orient file does not exist');
    end
    fid = fopen(abadirname_in);
    buffer = textscan( fid, '%s', 'Delimiter','\n', 'CollectOutput',true );
    fclose(fid);


    % insert ortientation keyword after element set defintion
    buffSize = size(buffer{1},1);
    buffer_out{1}{buffSize+7+eNumber,1} = []; 
    k = 0;
    disp 'Inserting orientations into ABAQUS no orient file...'
    for i = 1:buffSize-1
        tmpStr = ' ';
        tmpLine = buffer{1}{i};
        if k > i 
                if size(tmpLine,2) > 12
                    tmpStr = tmpLine(1:13);
                end
                if strcmp(tmpStr,'*End Assembly')
                    buffer_out{1}{k,1} = '*Distribution Table, name=TA_TEST_DISCFIELD-1_Table';
                    k = k+1; 
                    buffer_out{1}{k,1} = 'coord3d, coord3d';
                    k = k+1;
                end
            buffer_out{1}{k,1} =  buffer{1}{i+1};
            k = k+1;
        else
            buffer_out{1}{i,1} = buffer{1}{i};
        end
        if size(tmpLine,2) > 21
            tmpStr = tmpLine(1:22);
        end
        if strcmp(tmpStr,'*Elset, elset=PSOLID_1')
            buffer_out{1}{i+1,1} = buffer{1}{i+1};
            k = i+2;
            buffer_out{1}{k,1} = '*Orientation, name=Ori-TA_TEST_DISCFIELD-1, system=RECTANGULAR';
            k = k+1;
            buffer_out{1}{k,1} = 'TA_TEST_DISCFIELD-1';
            k = k+1;
            buffer_out{1}{k,1} = '1, 0.';
            k = k+1;
            buffer_out{1}{k,1} = '*Solid Section, elset=PSOLID_1, orientation=Ori-PART-1_TA_TEST_DISCFIELD-1, material=MATERIAL_PSOLID_1';
            k = k+1;
            buffer_out{1}{k,1} = ',';
            k = k+1;        
            buffer_out{1}{k,1} = '*Distribution, name=TA_TEST_DISCFIELD-1, location=ELEMENT, Table=TA_TEST_DISCFIELD-1_Table';
            k = k+1;
            buffer_out{1}{k,1} = ',           1.,           0.,           0.,           0.,           1.,           0.';
            k = k+1;
            for j = 1:eNumber
                tmpLine = num2str(dyna_elem(j,1));
                for p = 2:size(dyna_elem,2)
                    tmpStr = num2str(dyna_elem(j,p));
                    tmpLine = sprintf('%s, %s',tmpLine,tmpStr);
                end
                buffer_out{1}{k,1} = tmpLine;
                k = k+1;
            end
        end
    end

    % output distribution field of fibre orientation for Abaqus
    disp 'Writing out ABAQUS with orientation input file...'
    buffSize_out = size(buffer_out{1},1);
    tempTable = cell2table(buffer_out{1});

    if change_angle
        abaname = [fname '_' int2str(round(offset)) '_' int2str(round(PA_change_deg)) '_v2' '.inp'];
    else
        abaname = [fname '.inp'];
    end

    abadirname_out =  strcat('output/',abaname);
    fid = fopen(abadirname_out,'w');

    for i = 1:buffSize_out
        tmpLine = tempTable{i,1};
        if tmpLine{1}
            tmpStr = strcat(tmpLine{1},'\n');
            fprintf(fid,tmpStr);
        end
    end
    fclose(fid);

end

fprintf('Completed.\n')




