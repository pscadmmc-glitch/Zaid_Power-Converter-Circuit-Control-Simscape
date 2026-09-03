function results = ComparePIvsSMC(varargin)
%COMPAREPIVSSMC Benchmark the PI and super-twisting SMC inner current loops.
%
%   results = ComparePIvsSMC() runs every operating scenario twice - once
%   with the PI current controller and once with the super-twisting sliding
%   mode controller - then writes an overlay figure per scenario and a
%   summary comparison table.
%
%   results = ComparePIvsSMC('Name', Value, ...) accepts:
%
%     'OutputRoot'         folder that receives the results
%                          (default 'J:\GFM_PI_vs_SMC_Comparison')
%     'Scenarios'          cellstr subset of scenarios to run
%                          (default: all 13)
%     'ActivePowerMethod'  'Virtual Synchronous Machine' (default) or 'Droop'
%     'CurrentLimitMethod' 'Virtual Impedance' (default), 'Current Limiting'
%                          or 'Combining Both Method'
%     'SCR'                short-circuit ratio (default 2.5)
%     'XbyR'               grid X/R ratio (default 5)
%
%   Each run produces, inside a timestamped subfolder:
%     <Scenario>_PI_vs_SMC.png     six-panel overlay, 900 dpi
%     Summary_*.png                cross-scenario metric comparison
%     ComparisonTable.csv/.xlsx    all metrics, one row per scenario/controller
%     ComparisonResults.mat        raw metrics for further processing
%
%   Example:
%     results = ComparePIvsSMC('Scenarios', {'Normal operation'});

%% ---------------------------------------------------------------- options
opts = parseOptions(varargin{:});

allScenarios = { ...
    'Normal operation'; ...
    'Change in active power reference'; ...
    'Change in reactive power reference'; ...
    'Change in grid voltage'; ...
    'Change in local load'; ...
    'Change in grid frequency 1Hz/s, +0.5Hz'; ...
    'Change in grid frequency 2Hz/s, +2Hz'; ...
    'Change in grid frequency 2Hz/s, +2Hz and 1Hz/s till -5Hz'; ...
    'Change in grid phase by 10 degrees'; ...
    'Change in grid phase by 60 degrees'; ...
    'Permanent three-phase fault'; ...
    'Temporary three-phase fault'; ...
    'Islanding condition'};

if isempty(opts.Scenarios)
    scenarioList = allScenarios;
else
    scenarioList = cellstr(opts.Scenarios);
    unknown = setdiff(scenarioList, allScenarios);
    if ~isempty(unknown)
        error('ComparePIvsSMC:badScenario', ...
            'Unknown scenario: %s', strjoin(unknown, ', '));
    end
end

controllers = {'PI', 'SMC'};

%% ------------------------------------------------------------ output dir
nowStamp = datetime('now');
stamp = sprintf('%02d_%02d_%04d_%02dh%02d', ...
    nowStamp.Day, nowStamp.Month, nowStamp.Year, ...
    nowStamp.Hour, nowStamp.Minute);
outputDir = fullfile(opts.OutputRoot, stamp);

[ok, msg] = mkdir(outputDir);
if ~ok
    error('ComparePIvsSMC:noOutputDir', ...
        ['Cannot create "%s": %s\n' ...
         'Check that the drive exists and is writable, or pass another ' ...
         'folder with ''OutputRoot''.'], outputDir, msg);
end
fprintf('Results folder: %s\n\n', outputDir);

%% ------------------------------------------------------------ model setup
modelName = 'GridFormingConverter';
wasLoaded = bdIsLoaded(modelName);
if ~wasLoaded
    load_system(modelName);
end
cleanup = onCleanup(@() closeIfNeeded(modelName, wasLoaded));

% Remember the switch positions so the model is left untouched.
originalPI = getSwitchState(modelName);

%% ------------------------------------------------------------------ runs
nScenario = numel(scenarioList);
nRun = nScenario*numel(controllers);
records = cell(nRun, 1);
runIdx = 0;

for s = 1:nScenario
    scenario = scenarioList{s};
    fprintf('[%2d/%2d] %s\n', s, nScenario, scenario);

    runData = struct('PI', [], 'SMC', []);

    for c = 1:numel(controllers)
        controller = controllers{c};
        fprintf('        %-4s ... ', controller);

        try
            [outData, disturbanceTime] = runScenario( ...
                modelName, scenario, controller, opts);

            metrics = ComputeControlMetrics(outData, disturbanceTime);
            metrics.Scenario   = scenario;
            metrics.Controller = controller;
            metrics.Status     = 'completed';

            runData.(controller) = struct( ...
                'outData', outData, ...
                'disturbanceTime', disturbanceTime, ...
                'metrics', metrics);

            fprintf('OK  (P=%.3f pu, ts=%.3f s, THD=%.2f%%)\n', ...
                metrics.Pss, metrics.SettlingTime, metrics.CurrentTHD);

        catch err
            metrics = emptyMetrics();
            metrics.Scenario   = scenario;
            metrics.Controller = controller;
            metrics.Status     = err.message;
            fprintf('FAILED (%s)\n', err.message);
        end

        runIdx = runIdx + 1;
        records{runIdx} = metrics;
    end

    % Overlay figure for this scenario
    if ~isempty(runData.PI) && ~isempty(runData.SMC)
        fig = plotScenarioComparison(runData, scenario);
        savePng(fig, outputDir, [sanitize(scenario) '_PI_vs_SMC']);
        close(fig);
    end
end

%% --------------------------------------------------------------- results
comparisonTable = buildTable(records);

writetable(comparisonTable, fullfile(outputDir, 'ComparisonTable.csv'));
try
    writetable(comparisonTable, fullfile(outputDir, 'ComparisonTable.xlsx'));
catch
    warning('ComparePIvsSMC:noExcel', 'Excel export unavailable, CSV written.');
end

summaryFigs = plotSummary(comparisonTable);
names = {'Summary_SettlingTime', 'Summary_Overshoot', ...
         'Summary_PeakCurrent', 'Summary_CurrentTHD'};
for i = 1:numel(summaryFigs)
    savePng(summaryFigs(i), outputDir, names{i});
    close(summaryFigs(i));
end

results = struct( ...
    'table',      comparisonTable, ...
    'outputDir',  outputDir, ...
    'scenarios',  {scenarioList}, ...
    'options',    opts);

save(fullfile(outputDir, 'ComparisonResults.mat'), 'results');

% Restore the original switch position
SetCurrentController(modelName, originalPI);

fprintf('\n===== PI vs STSMC comparison =====\n');
disp(comparisonTable);
fprintf('\nSaved to: %s\n', outputDir);
end

%% ======================================================================
function [outData, disturbanceTime] = runScenario(modelName, scenario, controller, opts)
% Configure and simulate one scenario with one controller.

SetCurrentController(modelName, controller);

% Converter parameters (the .m version is Simulink-callback safe)
run('GridFormingConverterInputParameters.m');

% Super-twisting gains depend on base, so they load afterwards
run('STSMC_PARAMETERS.m');

testCondition.activePowerMethod  = opts.ActivePowerMethod;
testCondition.currentLimitMethod = opts.CurrentLimitMethod;
testCondition.SCR                = opts.SCR;
testCondition.XbyR               = opts.XbyR;
testCondition.testCondition      = scenario;

% Populates simulationTime, disturbanceTime and the disturbance profiles
run('GridFormingConverterTestCondition.m');

simIn = Simulink.SimulationInput(modelName);
simIn = setVariable(simIn, 'testCondition', testCondition);
simIn = setVariable(simIn, 'gridInverter',  gridInverter);
simIn = setVariable(simIn, 'L_smc',   L_smc);
simIn = setVariable(simIn, 'R_idsmc', R_idsmc);
simIn = setVariable(simIn, 'k_smc1',  k_smc1);
simIn = setVariable(simIn, 'k_smc2',  k_smc2);

outData = sim(simIn);

% Keep the disturbance inside the simulated window
tEnd = outData.LogsoutGridFormingConverter.get('Pmeas').Values.Time(end);
if tEnd < disturbanceTime
    disturbanceTime = 0.9*tEnd;
end
end

%% ======================================================================
function fig = plotScenarioComparison(runData, scenario)
% Six-panel overlay of the PI and STSMC responses.

fig = figure('Name', ['PI vs SMC - ' scenario], 'Visible', 'off');
set(fig, 'Position', [200, 100, 1100, 850]);

piLog  = runData.PI.outData.LogsoutGridFormingConverter;
smcLog = runData.SMC.outData.LogsoutGridFormingConverter;
tStart = 0.8*runData.PI.disturbanceTime;

panels = { ...
    'Pmeas', '$\mathrm{Power}$ (pu)',     'GFM Output Active Power'; ...
    'Qmeas', '$\mathrm{Power}$ (pu)',     'GFM Output Reactive Power'; ...
    'Freq',  '$\mathrm{Frequency}$ (Hz)', 'GFM Frequency'; ...
    'Vgd',   '$\mathrm{Voltage}$ (pu)',   'GFM Output Voltage ($V_d$)'};

for k = 1:4
    subplot(3, 2, k);
    [tp, yp] = fetch(piLog,  panels{k,1});
    [ts, ys] = fetch(smcLog, panels{k,1});
    plot(tp, yp, 'LineWidth', 2); hold all
    plot(ts, ys, '--', 'LineWidth', 2);
    grid on; box on
    xlim([tStart max(tp(end), ts(end))]);
    xlabel('$\mathrm{Time}$ (s)', 'Interpreter', 'latex');
    ylabel(panels{k,2}, 'Interpreter', 'latex');
    title(panels{k,3}, 'Interpreter', 'latex');
    legend('PI', 'STSMC', 'Interpreter', 'latex', 'Location', 'best');
end

% Current magnitude
subplot(3, 2, 5);
[tp, ip] = currentMagnitude(piLog);
[ts, is] = currentMagnitude(smcLog);
plot(tp, ip, 'LineWidth', 2); hold all
plot(ts, is, '--', 'LineWidth', 2);
grid on; box on
xlim([tStart max(tp(end), ts(end))]);
xlabel('$\mathrm{Time}$ (s)', 'Interpreter', 'latex');
ylabel('$\mathrm{Current}$ (pu)', 'Interpreter', 'latex');
title('GFM Output Current Magnitude ($I_s$)', 'Interpreter', 'latex');
legend('PI', 'STSMC', 'Interpreter', 'latex', 'Location', 'best');

% Tracking error on active power
subplot(3, 2, 6);
[tp, ep] = trackingError(piLog);
[ts, es] = trackingError(smcLog);
plot(tp, ep, 'LineWidth', 2); hold all
plot(ts, es, '--', 'LineWidth', 2);
grid on; box on
xlim([tStart max(tp(end), ts(end))]);
xlabel('$\mathrm{Time}$ (s)', 'Interpreter', 'latex');
ylabel('$|P^{*}-P^{m}|$ (pu)', 'Interpreter', 'latex');
title('Active Power Tracking Error', 'Interpreter', 'latex');
legend('PI', 'STSMC', 'Interpreter', 'latex', 'Location', 'best');

sgtitle(scenario, 'FontSize', 13, 'Color', [0, 100, 0]/256, ...
    'Interpreter', 'none');

SetLatexFont(fig);
end

%% ======================================================================
function figs = plotSummary(tbl)
% Bar charts comparing PI and STSMC across every scenario.

metricsToPlot = { ...
    'SettlingTime', 'Settling Time (s)',       'Settling Time: PI vs STSMC'; ...
    'Overshoot',    'Overshoot (\%)',          'Overshoot: PI vs STSMC'; ...
    'PeakCurrent',  'Peak Current (pu)',       'Peak Current: PI vs STSMC'; ...
    'CurrentTHD',   'THD (\%)',                'Current THD: PI vs STSMC'};

scenarios = unique(tbl.Scenario, 'stable');
figs = gobjects(size(metricsToPlot, 1), 1);

for m = 1:size(metricsToPlot, 1)
    field = metricsToPlot{m,1};
    values = nan(numel(scenarios), 2);

    for s = 1:numel(scenarios)
        for c = 1:2
            ctrl = {'PI', 'SMC'};
            row = strcmp(tbl.Scenario, scenarios{s}) & ...
                  strcmp(tbl.Controller, ctrl{c});
            if any(row)
                values(s, c) = tbl.(field)(find(row, 1));
            end
        end
    end

    figs(m) = figure('Name', field, 'Visible', 'off');
    set(figs(m), 'Position', [200, 100, 1150, 620]);
    bar(values);
    grid on; box on
    set(gca, 'XTick', 1:numel(scenarios), 'XTickLabel', shorten(scenarios), ...
        'XTickLabelRotation', 35, 'TickLabelInterpreter', 'none');
    ylabel(metricsToPlot{m,2}, 'Interpreter', 'latex');
    title(metricsToPlot{m,3}, 'Interpreter', 'latex');
    legend('PI', 'STSMC', 'Interpreter', 'latex', 'Location', 'best');
end
end

%% ======================================================================
function tbl = buildTable(records)
records = vertcat(records{:});

tbl = table( ...
    string({records.Scenario}'), ...
    string({records.Controller}'), ...
    [records.Pss]', ...
    [records.Qss]', ...
    [records.Overshoot]', ...
    [records.SettlingTime]', ...
    [records.IAE]', ...
    [records.ITAE]', ...
    [records.PeakCurrent]', ...
    [records.VoltageDip]', ...
    [records.FreqDeviation]', ...
    [records.CurrentTHD]', ...
    string({records.Outcome}'), ...
    string({records.Status}'), ...
    'VariableNames', {'Scenario', 'Controller', 'Pss_pu', 'Qss_pu', ...
    'Overshoot_pct', 'SettlingTime_s', 'IAE', 'ITAE', 'PeakCurrent_pu', ...
    'VoltageDip_pu', 'FreqDeviation_Hz', 'CurrentTHD_pct', 'Outcome', 'Status'});
end

%% ======================================================================
function savePng(fig, outputDir, name)
set(fig, 'Visible', 'off');
exportgraphics(fig, fullfile(outputDir, [name '.png']), ...
    'Resolution', 900, 'ContentType', 'image');
end

function [t, y] = fetch(log, name)
e = log.get(name);
if isempty(e)
    t = [0; 1]; y = [0; 0]; return
end
t = e.Values.Time(:);
y = reshape(e.Values.Data, 1, []).';
end

function [t, mag] = currentMagnitude(log)
[t, id] = fetch(log, 'Igd');
[~, iq] = fetch(log, 'Igq');
mag = sqrt(id.^2 + iq.^2);
end

function [t, err] = trackingError(log)
[t, p]   = fetch(log, 'Pmeas');
[tr, pr] = fetch(log, 'Pref');
err = abs(p - interp1(tr, pr, t, 'previous', 'extrap'));
end

function s = sanitize(name)
s = regexprep(name, '[^\w\s-]', '');
s = regexprep(s, '\s+', '_');
end

function short = shorten(scenarios)
short = cell(size(scenarios));
for i = 1:numel(scenarios)
    s = scenarios{i};
    if numel(s) > 28
        s = [s(1:25) '...'];
    end
    short{i} = s;
end
end

function m = emptyMetrics()
m = struct('Pss', NaN, 'Qss', NaN, 'Overshoot', NaN, 'SettlingTime', NaN, ...
    'IAE', NaN, 'ITAE', NaN, 'PeakCurrent', NaN, 'VoltageDip', NaN, ...
    'FreqDeviation', NaN, 'CurrentTHD', NaN, 'Outcome', 'not run');
end

function state = getSwitchState(modelName)
p = [modelName '/Grid-Forming Converter/Grid-Forming Converter Control/' ...
     'VoltageCurrentControl/Controller/d-axis current control/Manual Switch'];
if strcmp(get_param(p, 'sw'), '0')
    state = 'PI';
else
    state = 'SMC';
end
end

function closeIfNeeded(modelName, wasLoaded)
if ~wasLoaded && bdIsLoaded(modelName)
    close_system(modelName, 0);
end
end

function opts = parseOptions(varargin)
p = inputParser;
addParameter(p, 'OutputRoot', 'J:\GFM_PI_vs_SMC_Comparison', @(x)ischar(x)||isstring(x));
addParameter(p, 'Scenarios', {}, @(x)iscell(x)||ischar(x)||isstring(x));
addParameter(p, 'ActivePowerMethod', 'Virtual Synchronous Machine', @(x)ischar(x)||isstring(x));
addParameter(p, 'CurrentLimitMethod', 'Virtual Impedance', @(x)ischar(x)||isstring(x));
addParameter(p, 'SCR', 2.5, @isnumeric);
addParameter(p, 'XbyR', 5, @isnumeric);
parse(p, varargin{:});
opts = p.Results;
opts.OutputRoot = char(opts.OutputRoot);
opts.ActivePowerMethod = char(opts.ActivePowerMethod);
opts.CurrentLimitMethod = char(opts.CurrentLimitMethod);
end
