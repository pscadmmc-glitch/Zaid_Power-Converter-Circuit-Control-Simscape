function SetLatexFont(figHandle)
% SetLatexFont - Set LaTeX interpreter for all text elements in figure
%
% Syntax: SetLatexFont(figHandle)
%
% Inputs:
%    figHandle - Figure handle to format
%
% This function sets the interpreter to 'latex' for all text objects
% including titles, labels, legends, and annotations in the figure.
%
% Copyright 2023 The MathWorks, Inc.

    % Set default interpreter to LaTeX for this figure
    set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
    set(groot, 'defaultTextInterpreter', 'latex');
    set(groot, 'defaultLegendInterpreter', 'latex');
    set(groot, 'defaultColorbarTickLabelInterpreter', 'latex');

    % Find all axes in the figure
    allAxes = findall(figHandle, 'Type', 'axes');

    for i = 1:length(allAxes)
        ax = allAxes(i);

        % Set interpreter for axis labels
        set(ax, 'TickLabelInterpreter', 'latex');

        % Set interpreter for xlabel
        if ~isempty(ax.XLabel)
            set(ax.XLabel, 'Interpreter', 'latex');
        end

        % Set interpreter for ylabel
        if ~isempty(ax.YLabel)
            set(ax.YLabel, 'Interpreter', 'latex');
        end

        % Set interpreter for zlabel
        if ~isempty(ax.ZLabel)
            set(ax.ZLabel, 'Interpreter', 'latex');
        end

        % Set interpreter for title
        if ~isempty(ax.Title)
            set(ax.Title, 'Interpreter', 'latex');
        end

        % Set interpreter for subtitle (if exists)
        try
            if ~isempty(ax.Subtitle)
                set(ax.Subtitle, 'Interpreter', 'latex');
            end
        catch
            % Subtitle might not exist in older MATLAB versions
        end
    end

    % Find all legend objects
    allLegends = findall(figHandle, 'Type', 'Legend');
    for i = 1:length(allLegends)
        set(allLegends(i), 'Interpreter', 'latex');
    end

    % Find all text objects
    allText = findall(figHandle, 'Type', 'Text');
    for i = 1:length(allText)
        set(allText(i), 'Interpreter', 'latex');
    end

    % Find all annotations
    allAnnotations = findall(figHandle, 'Type', 'Annotation');
    for i = 1:length(allAnnotations)
        try
            set(allAnnotations(i), 'Interpreter', 'latex');
        catch
            % Some annotation types might not support Interpreter
        end
    end
end
