%% Super-Twisting Sliding Mode Controller (STSMC) Parameters
% Gains for the super-twisting inner current loop that runs in parallel
% with the original PI current controller in:
%   .../VoltageCurrentControl/Controller/d-axis current control
%   .../VoltageCurrentControl/Controller/q-axis current control
%
% Control law implemented in both axes (e = i_ref - i_meas):
%
%   u = L_smc*d(i_ref)/dt + R_idsmc*i + k_smc1*|e|^(1/2)*sign(e)
%                                     + k_smc2*integral(sign(e))
%
%   Gain6 -> L_smc      (feed-forward on the reference derivative)
%   Gain2 -> R_idsmc    (equivalent-control / resistive term)
%   Gain3 -> k_smc1     (proportional super-twisting term)
%   Gain1 -> k_smc2     (integral super-twisting term)
%
% Requires the base structure from GridFormingConverterInputParameters.

% Equivalent-control terms derived from the converter base quantities
L_smc    = base.impedance/(2*pi*base.frequency);        % H
R_idsmc  = base.basePhaseVoltage/base.basePhaseCurrent; % Ohm

% Super-twisting gains
k_smc1 = -0.25;   % |e|^(1/2)*sign(e) gain
k_smc2 = -0.25;   % integral(sign(e)) gain

% Legacy gain kept for reference. It is NOT wired to any block in the
% current model revision - k_smc1/k_smc2 are the active super-twisting gains.
k_smc  = -15.764;
