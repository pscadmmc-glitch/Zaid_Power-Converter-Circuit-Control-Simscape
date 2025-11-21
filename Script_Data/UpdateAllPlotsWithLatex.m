%% Script to Update All Plotting Files with LaTeX Formatting
% This script automatically updates all plotting functions to use LaTeX
% formatting and high-quality figure export
%
% Copyright 2023 The MathWorks, Inc.

%% Define files to update
files = {
    'PlotGridFormingConverter.m'
    'PlotInertiaConstantEffects.m'
    'PlotDampingEffects.m'
    'PlotBodeForController.m'
    'PlotFaultCurrentVoltageEffects.m'
    'PlotCompareFaultRideThroughMethod.m'
};

%% Define replacement patterns
% These are the common patterns to replace

replacements = {
    % xlabel replacements
    "xlabel('time (s)')", "xlabel('$\mathrm{Time}$ (s)', 'Interpreter', 'latex')"
    "xlabel('Frequency (rad/s)')", "xlabel('$\mathrm{Frequency}$ (rad/s)', 'Interpreter', 'latex')"
    "xlabel('Frequency (Hz)')", "xlabel('$\mathrm{Frequency}$ (Hz)', 'Interpreter', 'latex')"
    "xlabel('time (s)');", "xlabel('$\mathrm{Time}$ (s)', 'Interpreter', 'latex');"

    % ylabel replacements
    "ylabel('Power (pu)')", "ylabel('$\mathrm{Power}$ (pu)', 'Interpreter', 'latex')"
    "ylabel('Voltage (pu)')", "ylabel('$\mathrm{Voltage}$ (pu)', 'Interpreter', 'latex')"
    "ylabel('Current (pu)')", "ylabel('$\mathrm{Current}$ (pu)', 'Interpreter', 'latex')"
    "ylabel('Frequency (Hz)')", "ylabel('$\mathrm{Frequency}$ (Hz)', 'Interpreter', 'latex')"
    "ylabel('Phase (degree)')", "ylabel('$\mathrm{Phase}$ (degree)', 'Interpreter', 'latex')"
    "ylabel('Magnitude (dB)')", "ylabel('$\mathrm{Magnitude}$ (dB)', 'Interpreter', 'latex')"
    "ylabel('Phase (deg)')", "ylabel('$\mathrm{Phase}$ (deg)', 'Interpreter', 'latex')"
    "ylabel('Power (pu)');", "ylabel('$\mathrm{Power}$ (pu)', 'Interpreter', 'latex');"
    "ylabel('Voltage (pu)');", "ylabel('$\mathrm{Voltage}$ (pu)', 'Interpreter', 'latex');"
    "ylabel('Current (pu)');", "ylabel('$\mathrm{Current}$ (pu)', 'Interpreter', 'latex');"
    "ylabel('Frequency (Hz)');", "ylabel('$\mathrm{Frequency}$ (Hz)', 'Interpreter', 'latex');"
    "ylabel('GFM Output Voltage (pu)')", "ylabel('$\mathrm{GFM\ Output\ Voltage}$ (pu)', 'Interpreter', 'latex')"
    "ylabel('GFM Output Current (pu)')", "ylabel('$\mathrm{GFM\ Output\ Current}$ (pu)', 'Interpreter', 'latex')"
    "ylabel('Fault Trigger)')", "ylabel('$\mathrm{Fault\ Trigger}$)', 'Interpreter', 'latex')"
    "ylabel('Grid Voltage (pu)')", "ylabel('$\mathrm{Grid\ Voltage}$ (pu)', 'Interpreter', 'latex')"
    "ylabel('Fault Trigger')", "ylabel('$\mathrm{Fault\ Trigger}$', 'Interpreter', 'latex')"
    "ylabel('Trip Signal (pu)')", "ylabel('$\mathrm{Trip\ Signal}$ (pu)', 'Interpreter', 'latex')"
    "ylabel('Peak Current (pu)')", "ylabel('$\mathrm{Peak\ Current}$ (pu)', 'Interpreter', 'latex')"

    % Figure creation
    "figure('Name'", "fig = figure('Name'"
    "set(gcf,", "set(fig,"
};

%% Process each file
for i = 1:length(files)
    fileName = files{i};
    filePath = fullfile(pwd, fileName);

    if ~isfile(filePath)
        fprintf('Warning: File not found: %s\n', filePath);
        continue;
    end

    fprintf('Processing: %s\n', fileName);

    % Read file
    fid = fopen(filePath, 'r');
    if fid == -1
        fprintf('  Error: Could not open file\n');
        continue;
    end
    content = fread(fid, '*char')';
    fclose(fid);

    % Apply replacements
    for j = 1:size(replacements, 1)
        oldStr = replacements{j, 1};
        newStr = replacements{j, 2};
        content = strrep(content, oldStr, newStr);
    end

    % Write back
    fid = fopen(filePath, 'w');
    if fid == -1
        fprintf('  Error: Could not write file\n');
        continue;
    end
    fwrite(fid, content, 'char');
    fclose(fid);

    fprintf('  -> Updated successfully\n');
end

fprintf('\n All files have been processed!\n');
fprintf('Note: Manual verification recommended for complex cases.\n');
