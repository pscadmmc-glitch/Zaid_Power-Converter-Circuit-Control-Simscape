%% Configure Simulink to Use Shorter Cache Path
% This script configures Simulink to store build files in a shorter path
% to avoid Windows 260-character path limit
%
% Run this script ONCE before opening the GridFormingConverter model
%
% Copyright 2023 The MathWorks, Inc.

fprintf('==============================================================\n');
fprintf('Configuring Simulink Cache for Short Paths\n');
fprintf('==============================================================\n\n');

%% Create short cache directory
shortCachePath = 'C:\SimCache';

if ~exist(shortCachePath, 'dir')
    mkdir(shortCachePath);
    fprintf('✓ Created cache directory: %s\n', shortCachePath);
else
    fprintf('✓ Cache directory already exists: %s\n', shortCachePath);
end

%% Configure Simulink file generation
try
    Simulink.fileGenControl('set', ...
        'CacheFolder', shortCachePath, ...
        'CodeGenFolder', fullfile(shortCachePath, 'CodeGen'), ...
        'createDir', true);

    fprintf('✓ Configured Simulink cache folder\n');
    fprintf('  Cache Folder: %s\n', shortCachePath);
    fprintf('  Code Gen Folder: %s\n', fullfile(shortCachePath, 'CodeGen'));

catch ME
    warning('Could not configure via fileGenControl: %s', ME.message);
    fprintf('  Will configure model-specific settings instead\n');
end

%% Set preferences for this MATLAB session
try
    % Set the code generation folder preference
    setpref('Simulink', 'CodeGenFolder', fullfile(shortCachePath, 'CodeGen'));
    fprintf('✓ Set MATLAB preferences for code generation\n');
catch
    % Preferences not available in all versions
end

%% Configure the GridFormingConverter model specifically
modelName = 'GridFormingConverter';

% Check if model exists
modelPath = fullfile(pwd, '..', 'Models', [modelName '.slx']);
if ~exist(modelPath, 'file')
    modelPath = fullfile(pwd, 'Models', [modelName '.slx']);
end

if exist(modelPath, 'file')
    fprintf('\n');
    fprintf('Configuring model: %s\n', modelName);

    % Load model (don't open GUI)
    load_system(modelPath);

    % Set code generation folder
    try
        set_param(modelName, 'CodeGenFolder', fullfile(shortCachePath, 'CodeGen'));
        fprintf('✓ Set CodeGenFolder for model\n');
    catch
        % Not all versions support this parameter
    end

    % Set cache folder
    try
        set_param(modelName, 'CacheFolder', shortCachePath);
        fprintf('✓ Set CacheFolder for model\n');
    catch
        % Not all versions support this parameter
    end

    % Set simulation cache folder
    try
        set_param(modelName, 'SimulationCacheFolder', fullfile(shortCachePath, 'SimCache'));
        fprintf('✓ Set SimulationCacheFolder for model\n');
    catch
        % Not all versions support this parameter
    end

    % Save model with new settings
    try
        save_system(modelName);
        fprintf('✓ Saved model with new cache settings\n');
    catch ME
        warning('Could not save model: %s', ME.message);
        fprintf('  You may need to save manually after opening\n');
    end

    % Close model
    close_system(modelName, 0);

else
    warning('GridFormingConverter model not found at: %s', modelPath);
    fprintf('  Please run this script from the Script_Data folder\n');
end

%% Create cleanup script
cleanupScript = fullfile(pwd, 'CleanSimCache.m');
fid = fopen(cleanupScript, 'w');
fprintf(fid, '%% Clean Simulink Cache\n');
fprintf(fid, '%% Run this to free up disk space after simulations\n\n');
fprintf(fid, 'if exist(''C:\\SimCache'', ''dir'')\n');
fprintf(fid, '    rmdir(''C:\\SimCache'', ''s'');\n');
fprintf(fid, '    fprintf(''✓ Cleaned Simulink cache\\n'');\n');
fprintf(fid, 'else\n');
fprintf(fid, '    fprintf(''No cache to clean\\n'');\n');
fprintf(fid, 'end\n');
fclose(fid);
fprintf('\n✓ Created cleanup script: %s\n', cleanupScript);

%% Summary
fprintf('\n');
fprintf('==============================================================\n');
fprintf('Configuration Complete!\n');
fprintf('==============================================================\n');
fprintf('\nNext steps:\n');
fprintf('1. Open your model: open_system(''Models/GridFormingConverter'')\n');
fprintf('2. Run your simulation normally\n');
fprintf('3. Build files will be stored in: %s\n', shortCachePath);
fprintf('\nTo clean cache later, run: CleanSimCache\n');
fprintf('\n');
fprintf('NOTE: This is a workaround. For best results, move your\n');
fprintf('repository to a shorter path like C:\\GFM\\PowerConverter\n');
fprintf('==============================================================\n');
