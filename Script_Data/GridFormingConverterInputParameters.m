%% Grid-Forming Converter Input Parameters
% This script specifies the design parameters for the GridFormingConverter model.
% Copyright 2023 The MathWorks, Inc.

%% Grid-Forming Converter Specification
gridInverter.apparentPower   = 500;  % kVA, Apparent power
gridInverter.frequency       = 50;   % Hz, Grid frequency
gridInverter.DCVoltage       = 1100; % V, DC bus voltage
gridInverter.lineRMSVoltage  = 415;  % V, Line RMS voltage at the point of interconnection
gridInverter.measurementSampleTime = 100e-6; % s, Power measurement time constant

%% Base Parameters
% Estimating the base values
base.power = gridInverter.apparentPower; % kVA
base.frequency = gridInverter.frequency; % Hz
base.lineVoltage = gridInverter.lineRMSVoltage; % V
base.basePhasePower = base.power*1e3/3; % kVA
base.basePhaseVoltage = base.lineVoltage/sqrt(3); % V
base.voltage = base.basePhaseVoltage*sqrt(2); % V
base.basePhaseCurrent = base.basePhasePower/base.basePhaseVoltage; % A
base.current = base.basePhaseCurrent*sqrt(2); % A

base.impedance = base.basePhaseVoltage/base.basePhaseCurrent; % Ohm
base.inductance = base.impedance/(2*pi*base.frequency); % H
base.capacitance = 1/(base.impedance*2*pi*base.frequency); % F

%% Grid Parameters
grid.gridVoltageLL  = 11000; % V, Grid line RMS voltage
grid.gridResistance = 3;     % Ohm, Grid source resistance
grid.gridInductance = 0.05;  % H, Grid source inductance

%% Transformer Parameters
transformer.powerRating = gridInverter.apparentPower; % kVA, Transformer power rating
transformer.primaryRMSVoltage = gridInverter.lineRMSVoltage; % V, Transformer primary line RMS voltage
transformer.secondaryRMSVoltage = grid.gridVoltageLL; % V, Transformer secondary line RMS voltage

transformer.efficiency = 95; % Percentage efficiency
transformer.voltageRegulation = 6; % Percentage voltage regulation

transformer.turnsratio = transformer.primaryRMSVoltage/transformer.secondaryRMSVoltage; % Transformer turns ratio
transformer.primaryCurrentRating = transformer.powerRating*1e3/(sqrt(3)*transformer.primaryRMSVoltage);
transformer.secondaryCurrentRating = transformer.turnsratio*transformer.primaryCurrentRating;

% Estimating primary resistance of the transformer based on efficiency
primaryBaseImpedance = (transformer.primaryRMSVoltage)^2/(transformer.powerRating*1e3); % Ohm, Primary base impedance
transformer.PrimaryResistance = 0.6*(transformer.powerRating*1e3*(100-transformer.efficiency)/100)/...
(3*transformer.primaryCurrentRating^2); % 60 percent of the overall loss assumed to be in the primary winding
transformer.PrimaryResistancePU = transformer.PrimaryResistance/primaryBaseImpedance; % pu, Primary resistance

% Estimating secondary resistance of the transformer based on efficiency
secondaryBaseImpedance = (transformer.secondaryRMSVoltage)^2/(transformer.powerRating*1e3);  % pu, Secondary base impedance
transformer.SecondaryResistance = 0.4*(transformer.powerRating*1e3*(100-transformer.efficiency)/100)/...
    (3*transformer.secondaryCurrentRating^2); % 40 percent of overall loss assumed to be in the secondary winding
transformer.SecondaryResistancePU = transformer.SecondaryResistance/secondaryBaseImpedance; % pu, Secondary resistance

% Estimating reactance of the transformer based on voltage regulation
% 40 percent of overall voltage regulation considered in the primary leakage reactance
transformer.PrimaryReactancePU = 0.4*transformer.primaryRMSVoltage*(transformer.voltageRegulation/100)/...
    (transformer.primaryCurrentRating*primaryBaseImpedance); % pu, Transformer primary reactance

% 60 percent of overall voltage regulation considered in the secondary leakage reactance
transformer.SecondaryReactancePU = 0.6*transformer.secondaryRMSVoltage*(transformer.voltageRegulation/100)/...
    (transformer.secondaryCurrentRating*secondaryBaseImpedance); % pu, Transformer secondary reactance

%% Transmission Line Parameters
TransmissionLine.Length = 2; % km, Transmission line length
% Transmission line resistance estimated by assuming copper wire and current density of 3A/mm2
TransmissionLine.R = TransmissionLine.Length*1e3*1.77*1e-8*1e6/(transformer.secondaryCurrentRating/3); % Ohm
TransmissionLine.L = 5e-3; % H, Transmission line inductance

%% GFM Filter Inductor Design
gridInverter.ratedrmsCurrent = gridInverter.apparentPower*1e3/(sqrt(3)*gridInverter.lineRMSVoltage); % A, Filter rated current
gridInverter.L = (0.1*gridInverter.lineRMSVoltage/(gridInverter.ratedrmsCurrent*gridInverter.frequency*2*pi*sqrt(3))); % H, Filter inductance
gridInverter.lineResistance = 0.1; % Ohm, Filter resistance

%% Droop Active Power Control Parameters
gridInverter.droopControl.freqSlopeMp = 0.01; % pu, Hz/W, Power droop value
gridInverter.droopControl.lpfTimeConst = 0.015; % s, Low pass filter time constant

% Lead-lag parameter for three phase power measurement
gridInverter.droopControl.T2 = 0.006; % s, Denominator time constant
gridInverter.droopControl.T1 = 0.005; % s, Numerator time constant
gridInverter.droopControl.sampleTime = 100e-6; % s, Sampling time

gridInverter.freqMeasTimeConst = 150e-3; % s, Frequency measurement time constant

%% Virtual Synchronous Machine (VSM) Active Power Control Parameters
gridInverter.vsm.inertiaConstant = 1; % s, Mechanical time constant
gridInverter.vsm.dampingCoefficent = 1.056; % pu/Hz, Damping coefficient
gridInverter.vsm.freqDroop  = 10; % pu, W(pu)/Hz(pu) VSM Frequency droop
gridInverter.vsm.PmeasTimeConst = 1e-3; % s, Power measurement filter time constant
gridInverter.vsm.maxDampingPower = 0.7; % pu
gridInverter.vsm.minDampingPower = -0.6; % pu
gridInverter.vsm.samplingTime = gridInverter.droopControl.sampleTime; % s
gridInverter.vsm.dampingPowerOption = 'Grid Frequency Measurement'; % Selecting the damping frequency option

%% Reactive Power Droop Control
gridInverter.Qcontrol.voltageDroop = 0.3; % pu, V/VAR
gridInverter.Qcontrol.QmeasTimeConst = 1e-3; % s, Power measurement time constant
gridInverter.Qcontrol.voltageReference = 1.0; % pu
gridInverter.Qcontrol.lowVoltageSupportGain = 1.5; % pu.A/V, it adds more reactive current (Iq), during the low voltage condition

%% Virtual Impedance Parameters
gridInverter.currentLimit.virImpResistanceCoeff = 0.1875; % pu, Resistance
gridInverter.currentLimit.virImpXbyR = 13.2; % X/R ratio
gridInverter.currentLimit.viCurrentLimit = 1.2; % A, Maximum current
gridInverter.currentLimit.viFilterTimeConst = 1e-3; % s, Filter time constant

%% Current Limiting Parameters
gridInverter.currentLimit.maxSaturationCurrent = 1.4; % pu
gridInverter.currentLimit.maxSaturationDelay = 1e-3; % s

%% Virtual Impedance and Current Limiting Parameters
gridInverter.currentLimit.satCurrentRunTime = 1e-3; % s % Current saturation run time

%% Current Controller Parameters
gridInverter.controller.CurrentControlSampleTime = 100e-6; % s, Controller sampling time
gridInverter.controller.ctControllerKp = 1.5; % Proportional gain
gridInverter.controller.ctControllerKi = 10; % Integral gain

%% Voltage Controller Parameters
gridInverter.controller.VoltageControlSampleTime = 100e-6; % s, Controller sampling time
gridInverter.controller.voltControllerKp = 0.3; % Proportional gain
gridInverter.controller.voltControllerKi = 20; % Integral gain
gridInverter.controller.VoltageControllerLPF = 1e-3; % s, Low pass filter time constant

%% Short Circuit Ratio Computation
% This will be overridden by GridFormingConverterTestCondition if used
if ~exist('testCondition','var') || ~isfield(testCondition,'SCR')
    testCondition.SCR = 2.5; % Default SCR value
end
if ~exist('testCondition','var') || ~isfield(testCondition,'XbyR')
    testCondition.XbyR = 5; % Default X/R ratio
end
