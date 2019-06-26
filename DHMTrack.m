function DHMTrack()
%  DHM Track
%
%  Written by A. Hook 30-08-2017
%
%  General steps performed on selected data files:
%       - Converts h5 object file to .mat array (h5posnExtract.m)
%       - detects tracks based upon outputed objects (tracking.m)
%       - allows for manual inspection of the detect tracks (inspection.m)
%       - track sets saved during inspection process can then be viewed and
%         made into figures (graphing.m)
%       - gif animations can also be made (makeGif.m)
%
%
%   Object files if in the .mat format need to be structured as follows:
%       N frames each with a number of objects n
%       each object has either 4(3D) or 11(2D) columns
%           columns correspond to:
%               1  - x location
%               2  - y location
%               3  - z location             (zeros for 2D)
%               4  - volume of object       (3D only)
%              5-8 - empty
%               9  - bacteria length        (2D only)
%               10 - bacteria width         (2D only)
%               11 - bacteria orientation   (2D only)
%
%   Track files are structured need to be structured similar to object files:
%       N tracks each with a number of points n
%       each track point has 8(3D) or 11(2D) columns
%           columns correspond to:
%               1  - x location
%               2  - y location
%               3  - z location             (zeros for 2D)
%               4  - volume of object       (3D only)
%               5  - speed
%               6  - time
%               7  - 
%               8  - acceleration
%               9  - bacteria length        (2D only)
%               10 - bacteria width         (2D only)
%               11 - bacteria orientation   (2D only)
%
%  Modified Fall 2018 Andrew Woodward
%

clearvars -except frequency; 
%clc
%close all
warning('off','all')

%% Add subfolders to path
try
    added_path1 = [pwd,'/primaryFunctions'];
    addpath(added_path1);
    added_path2 = [pwd,'/utilities']; 
    addpath(added_path2);
    added_path3 = [pwd,'/utilities/export_fig'];
    addpath(added_path3);
    
    %% Welcome dialog box
    icon = imread('icon.png');
    f = msgbox('Please choose the object or track files to be analyzed','Welcome to DHMTrack','custom',icon);
    posn = get(f, 'Position');
    set(f, 'Position', posn+[0 0 20 5])
    waitfor(f);
catch
    disp('initialization error: ensure DHMTracking.m is in correct directory with subfolders');
    return
end

%% INPUT FILES
% Input file is h5 objects file
% Will allow for multiple object files to be added
Loops = 'Yes';
a=1;
extension = '';
while strcmp(Loops,'Yes') == 1 %Allow selection of multiple files
    if a == 1
        [FileName,PathName] = uigetfile({'*.*','*.*';'*.*','All Files (*.*)'},strcat('Pick a File (',num2str(a),')'));
        if FileName == 0
            a=a-1;
        else
            [title,extension] = strtok(FileName, '.');
            % Produce filename sequence for outputs
            filename{a,1} = strcat(PathName,strtok(FileName,'.'));
            filename{a,2} = strcat(PathName,strtok(FileName,'.'),'Data\objects.mat');
            filename{a,3} = strcat(PathName,strtok(FileName,'.'),'Data\Tracks.mat');
            filename{a,4} = strcat(PathName,strtok(FileName,'.'),'Data\Video\');
            filename{a,5} = strcat(PathName,strtok(FileName,'.'),'Data\Fig.png');
            filename{a,6} = extension;
        end
    else %Use previous inputs as guide
        [FileName,PathName] = uigetfile({'*.*','*.*';'*.*','All Files (*.*)'},strcat('Pick a File (',num2str(a),')'),PathName); 
        if FileName == 0
            a=a-1;
        else
            [title,extension] = strtok(FileName, '.');
            filename{a,1} = strcat(PathName,strtok(FileName,'.'));
            filename{a,2} = strcat(PathName,strtok(FileName,'.'),'Data\objects.mat');
            filename{a,3} = strcat(PathName,strtok(FileName,'.'),'Data\Tracks.mat');
            filename{a,4} = strcat(PathName,strtok(FileName,'.'),'Data\Video\');
            filename{a,5} = strcat(PathName,strtok(FileName,'.'),'Data\Fig.png');
            filename{a,6} = extension;
        end
    end 
    Loops = questdlg('Load another dataset?');
    if strcmp(Loops,'Cancel')==1
        return
    end
    a=a+1;
end
clear a f FileName Loops

%% PROCESSING LOOP
for i = 1:size(filename,1)
    
    mkdir(strcat(strtok(filename{i,1},'.'),'Data\'));
    ACQUISITION_TIME = {'20'};
    
    if strcmp(filename{i,6},'.mat') > 0
        %% file is a .mat file
        % determine whether it is an objects or a tracks file
        Tracks = load([filename{i,1} filename{i,6}]); 
        try
            if regexp(filename{i,1}, '.*\\[^\\]+\\([oO][bB][jJ][eE][cC][tT][sS][1-9]?)$') == 1
                if isfield(Tracks,'OBJECTS') > 0
                    OBJECTS = Tracks.OBJECTS; 
                elseif isfield(Tracks,'data') > 0
                    OBJECTS = Tracks.data;
                else
                    ME = MException('DHMTracking2:noSuchVariable','Variable OBJECTS or data not found');
                    throw(ME)
                end
                                              
                %% TRACKING VARIABLES
                % UI for entering the variable used by tracking
                prompt = {'Acquisition time (ms)','Minimum Volume','Maximum Volume','Maximum Speed','Minimum Track Steps','Minimum Track Distance','Minimum Angle Change','Minimum Delta Volume','Percent Delta Volume', 'Maximum # Look Ahead Frames'};
                title = strcat('Input File: ', {' '}, regexp(filename{i,1}, '(?<=\\)[^\\]+$', 'match'));
                title = title{1};
                dims = [1 40];
                if isfield(Tracks,'trackSettings')
                    trackSettings = Tracks.trackSettings; % import the tracking settings
                    definput = {trackSettings{1},trackSettings{2},trackSettings{3},trackSettings{4},trackSettings{5},trackSettings{6},trackSettings{7},trackSettings{8},trackSettings{9},trackSettings{10}};
                else
                    definput = {ACQUISITION_TIME{1},'0','200','100','15','0','180','100','100','4'}; % default inputs
                end
                answer = inputdlg_track(prompt,title,dims,definput);
                if isempty(answer)~=1
                    ACQUISITION_TIME = answer(1);
                    for j=1:size(answer,1)
                        answers(j) = str2double(answer(j));
                    end
                    
                    %% START TRACKING
                    % detects the tracks from the raw input frame/object data
                    Tracks = tracking(OBJECTS,answers(1),answers(2),answers(3),answers(4),answers(5),answers(6),answers(7),answers(8),answers(9),answers(10));
                else
                    disp('canceling');
                    exitDlg = questdlg('Cancel current object file or exit all?','Exit options', 'Cancel current only', 'Exit from all', 'Cancel current only');
                    if strcmp(exitDlg,'Exit from all')==1
                        % exit the execution of all the remaining set of files
                        break;
                    end
                end
            else
                Inspect = Tracks; % keep a copy to preserve the inspectSettings
                if isfield(Tracks,'Export') > 0
                    Tracks = Tracks.Export; % depending on the import file may be called export or tracks
                elseif isfield(Tracks,'Tracks') > 0
                    Tracks = Tracks.Tracks;
                else
                    ME = MException('DHMTracking2:noSuchVariable','Variable Export or Tracks not found');
                    throw(ME)
                end
            end
            
            %% INSPECTION Variables
            % UI for entering the variable used by inspection.m
            prompt = {'Manual Track Inspection (true = 1)','Track Dimension', 'Minimum Track Steps', 'Minimum Swimming Track Displacement', 'Maximum Distance for Automated', 'Maximum Time for Automated', 'Acquisition time (ms)', 'X axis pixel size', 'Y axis pixel size'};
            title = strcat('Input File: ', {' '}, regexp(filename{i,1}, '(?<=\\)[^\\]+$', 'match'));
            title = title{1};
            dims = [1 40];
            if isfield(Tracks,'inspectSettings')
                inspectSettings = Inspect.inspectSettings;
                definput = {inspectSettings{1},inspectSettings{2},inspectSettings{3},inspectSettings{4},inspectSettings{5},inspectSettings{6},inspectSettings{7},inspectSettings{8},inspectSettings{9}};
            else
                definput = {'1','3','0','10', '20', '0.6',ACQUISITION_TIME{1},'220','220'}; % default inputs
            end
            answer = inputdlg_inspect(prompt,title,dims,definput);
            if isempty(answer)~=1
                inspectSettings = answer;
                for j=1:size(answer,1)
                    answers(j) = str2double(answer(j));
                    inspectSettings{j} = answer(j);
                end
                
                %% INSPECTION of tracks
                % output of the tracks detected with tracking
                % allows for user verification and linking or removing tracks
                isCancel = 3;
                if exist('Tracks','var')==1
                    AllTracks = SpeedAcce(Tracks); % Calculate instantaneous speed and acceleration
                    if size(Tracks{1},1)>0
                        try
                            [isCancel, filenameList] = inspection(AllTracks,inspectSettings,filename{i,2}(1:end-11),answers(1),answers(2),answers(3),answers(4), answers(5), answers(6), answers(7),answers(8),answers(9)); % graphing and user verification performed here
                        catch
                            f = msgbox('The program encountered an a problem when trying to run inspection.m','Unexpected error');
                            waitfor(f);
                            isCancel = 1;
                        end
                    end
                end
                if isCancel == 3
                    f = msgbox('The program encountered an error: no tracks detected','Unexpected error');
                    waitfor(f);
                    exitDlg = questdlg('Cancel current or exit all?','Exit options', 'Cancel current only', 'Exit from all', 'Cancel current only');
                    if strcmp(exitDlg,'Exit from all')==1
                        % exit the execution of all the remaining set of files
                        break;
                    end
                elseif isCancel == 1
                    % need to exit
                    disp('canceling');
                    exitDlg = questdlg('Cancel current or exit all?','Exit options', 'Cancel current only', 'Exit from all', 'Cancel current only');
                    if strcmp(exitDlg,'Exit from all')==1
                        % exit the execution of all the remaining set of files
                        break;
                    end
                else                   
                    %% GRAPHING
                    % interface for setting colour options and producing figures and gifs
                    graphing(answers(7), filenameList);
                    
                    if size(filename,1)>1
                        clear OBJECTS Tracks
                        close all
                    end
                end
            else
                disp('canceling');
                exitDlg = questdlg('Cancel current object file or exit all?','Exit options', 'Cancel current only', 'Exit from all', 'Cancel current only');
                if strcmp(exitDlg,'Exit from all')==1
                    % exit the execution of all the remaining set of files
                    break;
                end
            end
            
        catch
            str = strcat('The program encountered a problem. Check the input file:', {' '}, regexp(filename{i,1}, '(?<=\\)[^\\]+$', 'match'), filename{i,6});
            f = msgbox(str,'Unexpected error');
            waitfor(f);
            answer = {};
        end
        
    else
        %% input file is an objects file
        % Conversion of h5 file to .mat array
        OBJECTS = h5posnExtract(filename{i,1});
        
        %% Data sift
        % Sift based upon volume to get all frames with similar number of objects
        OBJECTS = datasift(OBJECTS,20,30);
        %save(filename{i,2}, 'OBJECTS')
        
        %% INPUT TRACKING VARIABLES
        % UI for entering the variable used by tracking
        prompt = {'Acquisition time (ms)','Minimum Volume','Maximum Volume','Maximum Speed','Minimum Track Steps','Minimum Track Distance','Minimum Angle Change','Minimum Delta Volume','Percent Delta Volume', 'Maximum # Look Ahead Frames'};
        title = strcat('Input File: ', {' '}, regexp(filename{i,1}, '(?<=\\)[^\\]+$', 'match'));
        title = title{1};
        dims = [1 40];
        definput = {ACQUISITION_TIME{1},'0','200','100','15','0','180','100','100','4'}; % default inputs
        answer = inputdlg_track(prompt,title,dims,definput);
        if isempty(answer)~=1
            trackSettings = answer; % create a track settings variable for future reference
            save(filename{i,2}, 'OBJECTS', 'trackSettings');
            ACQUISITION_TIME = answer(1);
            for j=1:size(answer,1)
                answers(j) = str2double(answer(j));
            end
            
            %% Tracking
            % detects the tracks from the raw input frame/object data
            Tracks = tracking(OBJECTS,answers(1),answers(2),answers(3),answers(4),answers(5),answers(6),answers(7),answers(8),answers(9),answers(10));
            
            %% Input Inspection Variables
            % UI for entering the variable used by inspection.m
            clear answer answers prompt title dims definput
            prompt = {'Manual Track Inspection (true == 1)','Track Dimension', 'Minimum Track Steps', 'Minimum Swimming Track Displacement', 'Maximum Distance for Automated', 'Maximum Time for Automated', 'Acquisition time (ms)', 'X axis pixel size', 'Y axis pixel size'};
            title = strcat('Input File: ', {' '}, regexp(filename{i,1}, '(?<=\\)[^\\]+$', 'match'));
            title = title{1};
            dims = [1 40];
            definput = {'1','3','0','10', '20', '0.6',ACQUISITION_TIME{1},'220','220'}; % default inputs
            answer = inputdlg_inspect(prompt,title,dims,definput);
            if isempty(answer)~=1
                inspectSettings = answer;
                for j=1:size(answer,1)
                    answers(j) = str2double(answer(j));
                end
                
                %% Inspection of tracks
                % output of the tracks detected with tracking
                % allows for user verification and linking or removing tracks
                if exist('Tracks','var')==1
                    AllTracks = SpeedAcce(Tracks); % Calculate instantaneous speed and acceleration
                    if size(Tracks{1},1)>0
                        [isCancel, filenameList]=inspection(AllTracks,inspectSettings,filename{i,2}(1:end-11),answers(1),answers(2),answers(3),answers(4), answers(5), answers(6), answers(7),answers(8),answers(9)); % graphing and user verification performed here
                    end
                end
                
                if isCancel == 1
                    % need to exit
                    disp('canceling');
                    exitDlg = questdlg('Cancel current or exit all?','Exit options', 'Cancel current only', 'Exit from all', 'Cancel current only');
                    if strcmp(exitDlg,'Exit from all')==1
                        % exit the execution of all the remaining set of files
                        break;
                    end
                else
                    %% Graphing
                    % interface for setting colour options and producing figures and gifs
                    graphing(answers(7), filenameList);
                    
                    if size(filename,1)>1
                        clear OBJECTS Tracks 
                        close all
                    end
                    
                end
            else
                disp('canceling');
                exitDlg = questdlg('Cancel current object file or exit all?','Exit options', 'Cancel current only', 'Exit from all', 'Cancel current only');
                if strcmp(exitDlg,'Exit from all')==1
                    % exit the execution of all the remaining set of files
                    break;
                end
            end
        else
            disp('canceling');
            exitDlg = questdlg('Cancel current object file or exit all?','Exit options', 'Cancel current only', 'Exit from all', 'Cancel current only');
            if strcmp(exitDlg,'Exit from all')==1
                % exit the execution of all the remaining set of files
                break;
            end
        end
    end
end

%% Exiting Procedure
disp('Exiting DHMTrack');

% Remove paths that were added
rmpath(added_path1);
rmpath(added_path2);
rmpath(added_path3);

clear i PathName
warning('on','all')
end