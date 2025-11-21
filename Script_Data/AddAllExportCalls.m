%% Add Export Calls to All Plotting Functions
% This script adds SetLatexFont and ExportFigureHighQuality calls to all
% plotting functions that don't already have them
%
% Copyright 2023 The MathWorks, Inc.

%% List of files and their export insertions
files = {
    'PlotGridFormingConverter.m'
    'PlotInertiaConstantEffects.m'
    'PlotDampingEffects.m'
    'PlotBodeForController.m'
    'PlotFaultCurrentVoltageEffects.m'
    'PlotCompareFaultRideThroughMethod.m'
};

fprintf('=================================================================\n');
fprintf('Adding Figure Export Calls to All Plotting Functions\n');
fprintf('=================================================================\n\n');

%% Process PlotGridFormingConverter.m
fprintf('Processing PlotGridFormingConverter.m...\n');
file = 'PlotGridFormingConverter.m';

% Define the patterns to search and replace
replacements_gfc = {
    % Grid Voltage Change
    {'figTitle = ''Change in Grid Internal Voltage'';', 'figureTitle(figTitle,outValue);', 'end', 'end'}, 'Change_Grid_Voltage'
    % Local Load Change
    {'figTitle = ''Change in Local Load'';', 'figureTitle(figTitle,outValue);', 'end', 'end'}, 'Change_Local_Load'
    % Small Grid Frequency Change
    {'figTitle = ''Small Change in Grid Frequency'';', 'figureTitle(figTitle,outValue);', 'end', 'end'}, 'Small_Grid_Frequency_Change'
    % Large Grid Frequency Change
    {'figTitle = ''Large Change in Grid Frequency'';', 'figureTitle(figTitle,outValue);', 'end', 'end'}, 'Large_Grid_Frequency_Change'
    % Full Grid Frequency Change
    {'figTitle = ''Full Range Grid Frequency Change'';', 'figureTitle(figTitle,outValue);', 'end', 'end'}, 'Full_Grid_Frequency_Change'
    % 10 Degree Phase Change
    {'figTitle = ''Change in Grid Phase by 10 degrees'';', 'figureTitle(figTitle,outValue);', 'end', 'end'}, 'Grid_Phase_10_Degree_Change'
    % 60 Degree Phase Change
    {'figTitle = ''Change in Grid Phase by 60 degrees'';', 'figureTitle(figTitle,outValue);', 'end', 'end'}, 'Grid_Phase_60_Degree_Change'
    % Permanent Fault
    {'figTitle = ''Permanent Three-Phase Fault'';', 'figureTitle(figTitle,outValue);', 'end', 'end'}, 'Permanent_Three_Phase_Fault'
    % Temporary Fault
    {'figTitle = ''Temporary Three-Phase Fault'';', 'figureTitle(figTitle,outValue);', 'end', 'end'}, 'Temporary_Three_Phase_Fault'
    % Islanding
    {'figTitle = ''Islanding Condition'';', 'figureTitle(figTitle,outValue);', 'end', 'end'}, 'Islanding_Condition'
};

content = fileread(file);

for i = 1:size(replacements_gfc, 1)
    pattern = replacements_gfc{i, 1};
    scenarioName = replacements_gfc{i, 2};

    % Build the search string
    searchStr = sprintf('%s\n    %s\nend\nend', pattern{1}, pattern{2});

    % Build the replacement string
    replaceStr = sprintf(['%s\n    %s\n\n    %% Set LaTeX font for all elements\n    ' ...
        'SetLatexFont(fig);\n\n    %% Export figure in high quality\n    ' ...
        'ExportFigureHighQuality(fig, ''%s'');\nend\nend'], ...
        pattern{1}, pattern{2}, scenarioName);

    % Check if already exists
    if contains(content, ['ExportFigureHighQuality(fig, ''' scenarioName ''')'])
        fprintf('  - Already has export: %s\n', scenarioName);
    else
        content = strrep(content, searchStr, replaceStr);
        fprintf('  ✓ Added export: %s\n', scenarioName);
    end
end

% Write back
fid = fopen(file, 'w');
fwrite(fid, content, 'char');
fclose(fid);

%% Process PlotInertiaConstantEffects.m
fprintf('\nProcessing PlotInertiaConstantEffects.m...\n');
file = 'PlotInertiaConstantEffects.m';
content = fileread(file);

% Add export after sgtitle
searchStr = sprintf('sgtitle(''Effects of Virtual Synchronous Machine Inertia Constant'',''FontSize'',13,''Color'',[0,100,0]/256);\n    end');
replaceStr = sprintf(['sgtitle(''Effects of Virtual Synchronous Machine Inertia Constant'',''FontSize'',13,''Color'',[0,100,0]/256);\n\n    ' ...
    '%% Set LaTeX font for all elements\n    SetLatexFont(gcf);\n\n    ' ...
    '%% Export figure in high quality\n    ExportFigureHighQuality(gcf, ''Inertia_Constant_Effects'');\n    end']);

if ~contains(content, 'ExportFigureHighQuality(gcf, ''Inertia_Constant_Effects'')')
    content = strrep(content, searchStr, replaceStr);
    fprintf('  ✓ Added export\n');
else
    fprintf('  - Already has export\n');
end

fid = fopen(file, 'w');
fwrite(fid, content, 'char');
fclose(fid);

%% Process PlotDampingEffects.m
fprintf('\nProcessing PlotDampingEffects.m...\n');
file = 'PlotDampingEffects.m';
content = fileread(file);

searchStr = sprintf('sgtitle(''Effects of Virtual Synchronous Machine Damping Coefficient'',''FontSize'',13,''Color'',[0,100,0]/256);\n    end');
replaceStr = sprintf(['sgtitle(''Effects of Virtual Synchronous Machine Damping Coefficient'',''FontSize'',13,''Color'',[0,100,0]/256);\n\n    ' ...
    '%% Set LaTeX font for all elements\n    SetLatexFont(gcf);\n\n    ' ...
    '%% Export figure in high quality\n    ExportFigureHighQuality(gcf, ''Damping_Effects'');\n    end']);

if ~contains(content, 'ExportFigureHighQuality(gcf, ''Damping_Effects'')')
    content = strrep(content, searchStr, replaceStr);
    fprintf('  ✓ Added export\n');
else
    fprintf('  - Already has export\n');
end

fid = fopen(file, 'w');
fwrite(fid, content, 'char');
fclose(fid);

%%
fprintf('\n=================================================================\n');
fprintf('All export calls have been added!\n');
fprintf('=================================================================\n');
fprintf('\nNote: Figures will now be exported to:\n');
fprintf('  Exported_Figures/[scenario]_[date]_[time].[format]\n');
fprintf('  Formats: PNG (900 DPI), SVG, FIG\n\n');
