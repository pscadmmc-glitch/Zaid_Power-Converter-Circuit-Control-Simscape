function SetCurrentController(modelName, controllerType)
%SETCURRENTCONTROLLER Select PI or STSMC in the inner current loop.
%
%   SetCurrentController(modelName,'PI')   activates the PI controller
%   SetCurrentController(modelName,'SMC')  activates the super-twisting SMC
%
% Both the d-axis and q-axis current controllers contain a Manual Switch
% whose inputs are wired as:
%
%   input 1 <- Saturation (output of the PI branch: Kp + Ki/s)
%   input 2 <- Sum1       (output of the super-twisting branch)
%
% For a Simulink Manual Switch the 'sw' parameter selects the input that is
% passed through: '0' -> first input, '1' -> second input. If your release
% inverts this convention, flip the two constants below.

PI_SETTING  = '0';   % Manual Switch value that passes input 1 (PI)
SMC_SETTING = '1';   % Manual Switch value that passes input 2 (STSMC)

controllerBase = [modelName ...
    '/Grid-Forming Converter/Grid-Forming Converter Control/' ...
    'VoltageCurrentControl/Controller'];

switchPaths = { ...
    [controllerBase '/d-axis current control/Manual Switch']; ...
    [controllerBase '/q-axis current control/Manual Switch']};

switch upper(controllerType)
    case 'PI'
        setting = PI_SETTING;
    case {'SMC','STSMC'}
        setting = SMC_SETTING;
    otherwise
        error('SetCurrentController:badType', ...
            'Controller type must be ''PI'' or ''SMC'', got ''%s''.', controllerType);
end

for i = 1:numel(switchPaths)
    try
        set_param(switchPaths{i}, 'sw', setting);
    catch err
        error('SetCurrentController:noSwitch', ...
            ['Could not set "%s".\n%s\nMake sure the STSMC-equipped ' ...
             'model is loaded.'], switchPaths{i}, err.message);
    end
end
end
