function ExportFigureHighQuality(figHandle, scenarioName)
% ExportFigureHighQuality - Export figure in multiple high-quality formats
%
% Syntax: ExportFigureHighQuality(figHandle, scenarioName)
%
% Inputs:
%    figHandle - Figure handle to export
%    scenarioName - Name of the scenario (will be sanitized for filename)
%
% Outputs:
%    Exports figure as PNG (900 DPI), SVG, and FIG formats
%    Saves to: Exported_Figures/[scenarioName]_[timestamp].[format]
%
% Example:
%    fig = figure('Name', 'Test');
%    plot(1:10);
%    ExportFigureHighQuality(fig, 'Normal Operation');
%
% Copyright 2023 The MathWorks, Inc.

    % Get current date and time
    currentDateTime = datetime('now');
    dateStr = sprintf('%02d_%02d_%04d_%02dh%02d', ...
        currentDateTime.Day, ...
        currentDateTime.Month, ...
        currentDateTime.Year, ...
        currentDateTime.Hour, ...
        currentDateTime.Minute);

    % Sanitize scenario name for filename (remove special characters)
    scenarioName = regexprep(scenarioName, '[^\w\s-]', '');
    scenarioName = regexprep(scenarioName, '\s+', '_');

    % Create export directory if it doesn't exist
    exportDir = fullfile(pwd, 'Exported_Figures');
    if ~exist(exportDir, 'dir')
        mkdir(exportDir);
    end

    % Generate base filename
    baseFileName = sprintf('%s_%s', scenarioName, dateStr);

    % Full file paths
    pngFile = fullfile(exportDir, [baseFileName '.png']);
    svgFile = fullfile(exportDir, [baseFileName '.svg']);
    figFile = fullfile(exportDir, [baseFileName '.fig']);

    % Export PNG at 900 DPI
    fprintf('Exporting figure: %s\n', baseFileName);
    exportgraphics(figHandle, pngFile, 'Resolution', 900, 'ContentType', 'image');

    % Export SVG (vector format)
    saveas(figHandle, svgFile, 'svg');

    % Export FIG (MATLAB format)
    savefig(figHandle, figFile);

    fprintf('  -> PNG: %s\n', pngFile);
    fprintf('  -> SVG: %s\n', svgFile);
    fprintf('  -> FIG: %s\n', figFile);
end
