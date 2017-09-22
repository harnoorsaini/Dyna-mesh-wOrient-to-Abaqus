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

% KEY
V0 = 'TA_dyna';
V1 = 'ep2d_mddw12_right_TA';
V2 = 'ep2d_mddw12_right_TA_isolated';
%%% \/\/ CURRENT CHOICE \/\/ %%%
V3 = '270717_ep2d_mddw12_right_TA_isolated';
%%% /\/\ CURRENT CHOICE /\/\ %%%
V4 = '040817_ep2d_mddw12_right_TA';


PA_change_deg  = 15;
fname = V3;
change_angle = 1;
write = 0;
aponeurosis_offset = 82.61;
elemchangename = 'elem_include/270717_ep2d_mddw12_right_TA_isolated.txt';

%% 
if read_original 
    % read and store elements from LS-DYNA mesh
    [eNumber, dyna_elem] = extract_dyna_elem(fname);
    
    % store original coordinates and orientations
    dyna_elem_original = dyna_elem;
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% CHANGE FIBRE ORIENATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% START%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if change_angle 

    
    [dyna_elem,fib_angles,fib_angles_new] = modify_pennation_angle(aponeurosis_offset, PA_change_deg, ...
        elemchangename,dyna_elem);

end

histogram(fib_angles,50)
hold on
histogram(fib_angles_new,50)

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




