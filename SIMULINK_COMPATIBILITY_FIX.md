# Simulink Compatibility Fix - Live Scripts to Regular Scripts

## Problem

When opening the `GridFormingConverter.slx` Simulink model, you may encounter this error:

```
Unrecognized function or variable 'GridFormingConverterInputParameters'.
Warning:Error evaluating 'PreLoadFcn' callback of block_diagram 'GridFormingConverter'.
```

## Root Cause

The Simulink model has a **PreLoadFcn callback** that attempts to run:
```matlab
GridFormingConverterInputParameters;
```

However, `GridFormingConverterInputParameters.mlx` is a **MATLAB Live Script** (.mlx file), which **cannot be executed from Simulink callbacks**. Live scripts are designed for interactive use in the MATLAB Editor, not for programmatic execution.

## Solution

We've created regular MATLAB script (.m) versions of the live scripts:

### Created Files:
1. **GridFormingConverterInputParameters.m**
   - Regular MATLAB script version
   - Contains all parameter definitions for the GFM converter
   - Defines: `gridInverter`, `base`, `grid`, `transformer`, `TransmissionLine`, etc.
   - **CAN be called from Simulink**

2. **GridFormingConverterTestCondition.m**
   - Regular MATLAB script version
   - Configures test scenarios (13 different conditions)
   - Creates timetables for grid disturbances
   - **CAN be called from Simulink**

### File Structure:
```
Script_Data/
├── GridFormingConverterInputParameters.mlx  ← Original (for editing/documentation)
├── GridFormingConverterInputParameters.m    ← NEW (used by Simulink)
├── GridFormingConverterTestCondition.mlx    ← Original (for editing/documentation)
└── GridFormingConverterTestCondition.m      ← NEW (used by Simulink)
```

## How to Use

### Option 1: Open and Run the Model Directly
```matlab
% Navigate to the model directory
cd Models

% Open the model - it will now load without errors
open_system('GridFormingConverter')

% Run a simulation
sim('GridFormingConverter')
```

### Option 2: Use the Plotting Functions (Recommended)
```matlab
% Navigate to scripts directory
cd Script_Data

% Set up test conditions
testCondition.activePowerMethod = 'Virtual Synchronous Machine';
testCondition.currentLimitMethod = 'Virtual Impedance';
testCondition.testCondition = 'Normal operation';
testCondition.SCR = 2.5;
testCondition.XbyR = 5;

% Run the plotting function (automatically loads parameters and runs model)
outputTable = PlotGridFormingConverter(testCondition, 1);
```

### Option 3: Run From Live Script
```matlab
% Open the main live script
edit GridFormingConverterMain.mlx

% Run it section by section in the Live Editor
```

## What Changed

### Before (Broken):
```
Simulink PreLoadFcn → GridFormingConverterInputParameters; → ERROR
                      ↓
                      Tries to call .mlx file (not supported)
```

### After (Fixed):
```
Simulink PreLoadFcn → GridFormingConverterInputParameters; → SUCCESS
                      ↓
                      Calls .m file (fully supported)
```

## Technical Details

### Why Live Scripts Don't Work in Callbacks:
1. **Live scripts (.mlx)** are XML-based documents containing:
   - Code
   - Rich text formatting
   - Inline outputs
   - Equations (LaTeX)
   - Images

2. **Simulink callbacks** expect:
   - Plain MATLAB code (.m files)
   - Functions that can be evaluated in the base workspace
   - Fast execution without GUI interaction

### What's in the .m Files:
Both files contain **identical functionality** to their .mlx counterparts:

**GridFormingConverterInputParameters.m:**
- Converter specifications (500 kVA, 50 Hz, 415V)
- Base parameter calculations
- Grid, transformer, transmission line parameters
- Filter design
- Controller parameters (VSM, Droop, Current limiting, Voltage/Current controllers)
- All values in SI units and per-unit

**GridFormingConverterTestCondition.m:**
- SCR (Short Circuit Ratio) and X/R ratio calculations
- 13 test scenarios:
  1. Normal operation
  2. Active power reference change
  3. Reactive power reference change
  4. Grid voltage change
  5. Local load change
  6. Small frequency change (±0.5 Hz)
  7. Large frequency change (±2 Hz)
  8. Full frequency range (47-52 Hz)
  9. 10° phase jump
  10. 60° phase jump
  11. Permanent three-phase fault
  12. Temporary three-phase fault
  13. Islanding condition
- Timetable creation for Simulink "From Workspace" blocks

## Maintaining Both Versions

### When to Edit .mlx Files:
- When you want rich documentation
- When adding equations or explanations
- When creating reports

### When to Edit .m Files:
- When changing parameters used by Simulink
- When modifying test scenarios
- When debugging simulation issues

### Keeping Them in Sync:
If you modify the .mlx files, you need to update the .m files with the same parameter changes.

**Manual sync:**
```matlab
% 1. Edit GridFormingConverterInputParameters.mlx
% 2. Export to .m format:
%    - File → Export → MATLAB Code (.m)
%    - Save as GridFormingConverterInputParameters.m
```

**Or use MATLAB's built-in conversion:**
```matlab
% Convert live script to regular script
matlab.internal.liveeditor.openAndConvert('GridFormingConverterInputParameters.mlx', ...
    'GridFormingConverterInputParameters.m');
```

## Verification

To verify the fix worked:

```matlab
% Test 1: Load parameters
clear all
run('Script_Data/GridFormingConverterInputParameters.m')
whos gridInverter  % Should show struct with fields

% Test 2: Open model (should load without errors)
open_system('Models/GridFormingConverter')

% Test 3: Run a quick simulation
testCondition.testCondition = 'Normal operation';
run('Script_Data/GridFormingConverterTestCondition.m')
sim('Models/GridFormingConverter')
```

## Troubleshooting

### Error: "Undefined function or variable 'testCondition'"
**Solution:** Run `GridFormingConverterInputParameters.m` first, then set `testCondition` fields.

### Error: "Undefined function or variable 'gridInverter'"
**Solution:** The .m files create variables in the **base workspace**. Make sure you're running them, not just opening them.

### Error: "Unknown test condition"
**Solution:** Check that `testCondition.testCondition` matches one of the 13 scenario names exactly (case-sensitive).

### Model still won't load
**Solution:**
```matlab
% Clear everything and start fresh
clear all
close all
bdclose all

% Load parameters explicitly
cd Script_Data
GridFormingConverterInputParameters

% Now open model
cd ../Models
open_system('GridFormingConverter')
```

## Summary

✅ **Problem solved:** Simulink can now execute the parameter initialization scripts
✅ **Backward compatible:** Original .mlx files retained for documentation
✅ **No workflow changes:** Plotting functions work exactly as before
✅ **Better compatibility:** .m files work in all MATLAB versions and environments

---

**Last Updated:** November 21, 2025
**Commit:** 55685c0
**Files Added:**
- `Script_Data/GridFormingConverterInputParameters.m`
- `Script_Data/GridFormingConverterTestCondition.m`
