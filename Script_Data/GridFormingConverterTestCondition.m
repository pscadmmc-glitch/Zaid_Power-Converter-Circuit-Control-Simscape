%% Grid-Forming Converter Test Condition Setup
% This script configures test condition variables for different scenarios
% Copyright 2023 The MathWorks, Inc.

%% Simulation and Disturbance Time
if ~exist('simulationTime','var')
    simulationTime = 4; % s, Total simulation time
end
if ~exist('disturbanceTime','var')
    disturbanceTime = 2; % s, Time when disturbance occurs
end

%% Compute Short Circuit Ratio and X/R Ratio Scale Factors
% Calculate grid impedance for desired SCR and X/R ratio
if ~isfield(testCondition,'SCR')
    testCondition.SCR = 2.5; % Default
end
if ~isfield(testCondition,'XbyR')
    testCondition.XbyR = 5; % Default
end

% Base impedance at grid side
baseImpedanceGrid = (grid.gridVoltageLL/sqrt(3))^2/(gridInverter.apparentPower*1e3/3);

% Total grid impedance (grid + transformer + transmission line)
shortCircuit.gridSourceImpedance = grid.gridResistance + 1i*grid.gridInductance*2*pi*base.frequency;
shortCircuit.transformerImpedance = transformer.SecondaryResistance + 1i*transformer.SecondaryReactancePU*baseImpedanceGrid*2*pi*base.frequency;
shortCircuit.transmissionLineImpedance = TransmissionLine.R + 1i*TransmissionLine.L*2*pi*base.frequency;
shortCircuit.overallGridImpedance = shortCircuit.gridSourceImpedance + shortCircuit.transformerImpedance + shortCircuit.transmissionLineImpedance;

% Calculate scaling factors for SCR
requiredSCR = testCondition.SCR;
existingSCR = abs((grid.gridVoltageLL/sqrt(3))^2/(gridInverter.apparentPower*1e3/3*abs(shortCircuit.overallGridImpedance)));
scrFactorRg = existingSCR/requiredSCR;
scrFactorXg = scrFactorRg;

% Adjust for X/R ratio
realPart = real(shortCircuit.overallGridImpedance);
imaginaryPart = imag(shortCircuit.overallGridImpedance);
existingXbyR = imaginaryPart/realPart;

if testCondition.XbyR ~= existingXbyR
    scrFactorXg = scrFactorRg*testCondition.XbyR*realPart/imaginaryPart;
end

%% Setting Up the Model
% Set the current limiting and active power method
set_param([bdroot,'/Grid-Forming Converter/Grid-Forming Converter Control'],'freqOption',gridInverter.vsm.dampingPowerOption);
set_param([bdroot,'/Grid-Forming Converter/Grid-Forming Converter Control'],'powerControl',testCondition.activePowerMethod);
set_param([bdroot,'/Grid-Forming Converter/Grid-Forming Converter Control'],'currentLimit',testCondition.currentLimitMethod);

%% Default Test Condition Parameters
testCondition.faultResistance = 0.5; % Ohm, Default fault resistance

% Default profiles (will be overridden by specific test conditions)
gfmRealPowerRefProfileVal = [0 0.5 0.5 0.8 0.8];
gfmRealPowerRefProfileTime = [0 1 disturbanceTime-1e-3 disturbanceTime simulationTime];

gfmReactivePowerRefProfileVal = [0 0 0 0 0];
gfmReactivePowerRefProfileTime = [0 1 disturbanceTime-1e-3 disturbanceTime simulationTime];

gridVoltageProfileVal = [1 1 1];
gridVoltageProfileTime = [0 disturbanceTime simulationTime];

gridFrequencyProfileVal = [50 50 50];
gridFrequencyProfileTime = [0 disturbanceTime simulationTime];

gridPhaseProfileVal = [0 0 0];
gridPhaseProfileTime = [0 disturbanceTime simulationTime];

localLoadRealProfileVal = [0.7 0.7 0.7];
localLoadRealProfileTime = [0 disturbanceTime simulationTime];

localLoadReactiveProfileVal = [0 0 0];
localLoadReactiveProfileTime = [0 disturbanceTime simulationTime];

faultTriggerVal = [0 0 0];
faultTriggerTime = [0 disturbanceTime simulationTime];

circuitBreakerTripSignalVal = [0 0 0];
circuitBreakerTripSignalTime = [0 disturbanceTime simulationTime];

%% Configure Different Test Scenarios
switch testCondition.testCondition
    case 'Normal operation'
        % Use defaults

    case 'Change in active power reference'
        gfmRealPowerRefProfileVal = [0 0.5 0.5 0.9 0.9];

    case 'Change in reactive power reference'
        gfmReactivePowerRefProfileVal = [0 0 0 0.5 0.5];

    case 'Change in grid voltage'
        gridVoltageProfileVal = [1 1 0.85 0.85 1 1];
        gridVoltageProfileTime = [0 disturbanceTime-1e-3 disturbanceTime disturbanceTime+1 disturbanceTime+1.5 simulationTime];

    case 'Change in local load'
        localLoadRealProfileVal = [0.7 0.7 0.9 0.9];
        localLoadRealProfileTime = [0 disturbanceTime-1e-3 disturbanceTime simulationTime];

    case 'Change in grid frequency 1Hz/s, +0.5Hz'
        gridFrequencyProfileVal = [50 50 50.5 50.5];
        gridFrequencyProfileTime = [0 disturbanceTime disturbanceTime+0.5 simulationTime];

    case 'Change in grid frequency 2Hz/s, +2Hz'
        gridFrequencyProfileVal = [50 50 52 52];
        gridFrequencyProfileTime = [0 disturbanceTime disturbanceTime+1 simulationTime];

    case 'Change in grid frequency 2Hz/s, +2Hz and 1Hz/s till -5Hz'
        gridFrequencyProfileVal = [50 50 52 52 47 47];
        gridFrequencyProfileTime = [0 disturbanceTime disturbanceTime+1 disturbanceTime+6 disturbanceTime+11 simulationTime];
        simulationTime = 20;

    case 'Change in grid phase by 10 degrees'
        gridPhaseProfileVal = [0 0 10 10];
        gridPhaseProfileTime = [0 disturbanceTime-1e-3 disturbanceTime simulationTime];

    case 'Change in grid phase by 60 degrees'
        gridPhaseProfileVal = [0 0 60 60];
        gridPhaseProfileTime = [0 disturbanceTime-1e-3 disturbanceTime simulationTime];

    case 'Permanent three-phase fault'
        faultTriggerVal = [0 0 1 1];
        faultTriggerTime = [0 disturbanceTime-1e-3 disturbanceTime simulationTime];
        gfmRealPowerRefProfileVal = [0 0.9 0.9 0.9 0.9];
        gfmReactivePowerRefProfileVal = [0 0 0 0 0];

    case 'Temporary three-phase fault'
        faultTriggerVal = [0 0 1 0 0];
        faultTriggerTime = [0 disturbanceTime-1e-3 disturbanceTime disturbanceTime+2 simulationTime];
        gfmRealPowerRefProfileVal = [0 0.9 0.9 0.9 0.9];
        gfmReactivePowerRefProfileVal = [0 0 0 0 0];
        simulationTime = 6;

    case 'Islanding condition'
        circuitBreakerTripSignalVal = [0 0 1 1];
        circuitBreakerTripSignalTime = [0 disturbanceTime-1e-3 disturbanceTime simulationTime];
        localLoadRealProfileVal = [0.7 0.7 0.8 0.8];
        localLoadRealProfileTime = [0 disturbanceTime-1e-3 disturbanceTime simulationTime];

    otherwise
        warning('Unknown test condition: %s. Using default values.', testCondition.testCondition);
end

%% Create Timetables for Simulink
testCondition.gridVoltageProfile = timetable(gridVoltageProfileVal', 'RowTimes', seconds(gridVoltageProfileTime'));
testCondition.gridFrequencyProfile = timetable(gridFrequencyProfileVal', 'RowTimes', seconds(gridFrequencyProfileTime'));
testCondition.gridPhaseProfile = timetable(gridPhaseProfileVal', 'RowTimes', seconds(gridPhaseProfileTime'));
testCondition.gfmRealPowerRefProfile = timetable(gfmRealPowerRefProfileVal', 'RowTimes', seconds(gfmRealPowerRefProfileTime'));
testCondition.gfmReactivePowerRefProfile = timetable(gfmReactivePowerRefProfileVal', 'RowTimes', seconds(gfmReactivePowerRefProfileTime'));
testCondition.localLoadRealProfile = timetable(localLoadRealProfileVal', 'RowTimes', seconds(localLoadRealProfileTime'));
testCondition.localLoadReactiveProfile = timetable(localLoadReactiveProfileVal', 'RowTimes', seconds(localLoadReactiveProfileTime'));
testCondition.faultTrigger = timetable(faultTriggerVal', 'RowTimes', seconds(faultTriggerTime'));
testCondition.circuitBreakerTripSignal = timetable(circuitBreakerTripSignalVal', 'RowTimes', seconds(circuitBreakerTripSignalTime'));

%% Set Simulation Stop Time
set_param(bdroot,'StopTime',num2str(simulationTime));
