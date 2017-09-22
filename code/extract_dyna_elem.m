function [eNumber,dyna_elem] = extract_dyna_elem(fname)

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