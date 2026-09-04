# PI vs Super-Twisting SMC — Inner Current Loop Comparison

Comparison framework for the two inner current-loop controllers now present in
`Models/GridFormingConverter.slx`.

## 1. What is in the model

The d-axis and q-axis current controllers each contain a **Manual Switch** that
selects between two parallel branches:

| Switch input | Branch | Blocks |
|---|---|---|
| 1 | **PI** | `Kp` (IdPGain/IqPGain), `Ki` (IdIGain/IqIGain) → Discrete-Time Integrator → `Sum7` → `Saturation1` |
| 2 | **STSMC** | `Gain6`, `Gain2`, `Gain3`, `Gain1` → `Sum1` |

Block paths:

```
GridFormingConverter/Grid-Forming Converter/Grid-Forming Converter Control/
    VoltageCurrentControl/Controller/d-axis current control/Manual Switch
    VoltageCurrentControl/Controller/q-axis current control/Manual Switch
```

### Super-twisting control law

With the tracking error `e = i_ref − i_meas`, the STSMC branch implements

$$u = L_{smc}\,\frac{di^{*}}{dt} \;+\; R_{idsmc}\,i \;+\; k_{smc1}\,|e|^{1/2}\,\mathrm{sign}(e) \;+\; k_{smc2}\!\int\!\mathrm{sign}(e)\,dt$$

| Block | Gain | Role |
|---|---|---|
| `Gain6` | `L_smc` | feed-forward on the reference derivative |
| `Gain2` | `R_idsmc` | equivalent-control (resistive) term |
| `Gain3` | `k_smc1` | proportional super-twisting term |
| `Gain1` | `k_smc2` | integral super-twisting term |

Gains live in `Script_Data/STSMC_PARAMETERS.m`:

```matlab
L_smc   = base.impedance/(2*pi*base.frequency);        % = base.inductance
R_idsmc = base.basePhaseVoltage/base.basePhaseCurrent; % = base.impedance
k_smc1  = -0.25;
k_smc2  = -0.25;
```

> `k_smc = -15.764` is defined but **not wired to any block** in this model
> revision. Only `k_smc1` and `k_smc2` drive the super-twisting terms.

## 2. Running the comparison

```matlab
% Open the project first so the paths resolve
openProject('PowerConverterCircuitAndControlDesignWithSimscape.prj');

% All 13 scenarios, PI and STSMC, results written to J:
results = ComparePIvsSMC();
```

> The upstream `README.md` refers to `GridFormingConverterWithSimscape.prj`.
> That file does not exist in the repository - the project is
> `PowerConverterCircuitAndControlDesignWithSimscape.prj`.

Useful options:

```matlab
% A single scenario, faster turnaround
results = ComparePIvsSMC('Scenarios', {'Temporary three-phase fault'});

% Another output location (if J: is unavailable)
results = ComparePIvsSMC('OutputRoot', 'C:\GFM_Results');

% Droop instead of VSM, weaker grid
results = ComparePIvsSMC('ActivePowerMethod', 'Droop', 'SCR', 1.5);
```

## 3. Scenarios covered

1. Normal operation
2. Change in active power reference
3. Change in reactive power reference
4. Change in grid voltage
5. Change in local load
6. Change in grid frequency 1 Hz/s, +0.5 Hz
7. Change in grid frequency 2 Hz/s, +2 Hz
8. Change in grid frequency 2 Hz/s, +2 Hz and 1 Hz/s till −5 Hz
9. Change in grid phase by 10°
10. Change in grid phase by 60°
11. Permanent three-phase fault
12. Temporary three-phase fault
13. Islanding condition

Each scenario runs twice (PI, STSMC) → **26 simulations** for a full sweep.

## 4. Outputs

Written to `<OutputRoot>\<DD_MM_YYYY_HHhMM>\`:

| File | Content |
|---|---|
| `<Scenario>_PI_vs_SMC.png` | Six-panel overlay at 900 dpi: P, Q, frequency, Vd, current magnitude, tracking error |
| `Summary_SettlingTime.png` | Settling time, all scenarios, PI vs STSMC |
| `Summary_Overshoot.png` | Overshoot comparison |
| `Summary_PeakCurrent.png` | Peak current comparison |
| `Summary_CurrentTHD.png` | Current THD comparison |
| `ComparisonTable.csv` / `.xlsx` | One row per scenario × controller |
| `ComparisonResults.mat` | Raw metrics for post-processing |

### Table columns

| Column | Meaning |
|---|---|
| `Scenario`, `Controller` | Run identification (`PI` / `SMC`) |
| `Pss_pu`, `Qss_pu` | Steady-state active / reactive power |
| `Overshoot_pct` | Peak overshoot of P after the disturbance |
| `SettlingTime_s` | Time to enter and stay in a ±2 % band |
| `IAE`, `ITAE` | Integral error indices on P tracking |
| `PeakCurrent_pu` | Max √(Id²+Iq²) — current stress |
| `VoltageDip_pu` | Largest drop of Vd below its pre-disturbance value |
| `FreqDeviation_Hz` | Largest excursion from 50 Hz |
| `CurrentTHD_pct` | THD of phase-a current, last 5 fundamental periods |
| `Outcome` | Pass/fail verdict from `FindTestOutCome` |
| `Status` | `completed`, or the error message if the run failed |

## 5. Files

| File | Role |
|---|---|
| `Script_Data/ComparePIvsSMC.m` | Main driver — runs the sweep, plots, tables |
| `Script_Data/SetCurrentController.m` | Toggles both Manual Switches between PI and STSMC |
| `Script_Data/ComputeControlMetrics.m` | Metric extraction, including a toolbox-free THD |
| `Script_Data/STSMC_PARAMETERS.m` | Super-twisting gains |

## 6. Notes before the first run

- **Manual Switch convention.** `SetCurrentController.m` assumes `sw='0'`
  passes input 1 (PI) and `sw='1'` passes input 2 (STSMC). Confirm once by
  opening the d-axis controller and checking which branch is highlighted; if
  the convention is inverted in your release, swap `PI_SETTING` and
  `SMC_SETTING` at the top of that file.
- **Windows path limit.** A full sweep generates deep build folders. If you hit
  the 260-character error, run `ConfigureShortPaths` first.
- **Runtime.** 26 simulations; the wide-frequency scenario alone runs 20 s of
  simulated time. Budget accordingly, and start with a single scenario to
  validate the setup.
