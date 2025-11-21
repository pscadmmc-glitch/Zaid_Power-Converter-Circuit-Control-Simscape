#!/usr/bin/env python3
"""
Script to add figure export calls to all plotting functions
"""

import re
import os

def add_export_to_file(filepath, export_mappings):
    """
    Add SetLatexFont and ExportFigureHighQuality calls to plotting functions.

    Args:
        filepath: Path to the MATLAB file
        export_mappings: List of tuples (figure_name_pattern, scenario_name)
    """
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    original_content = content

    # For each export mapping, find the figure and add export calls before its closing end
    for fig_pattern, scenario_name in export_mappings:
        # Pattern to find figure with name and add export before 'end'
        # Look for figure creation followed by subplot code, then find the closing 'end'
        pattern = rf"(fig\s*=\s*figure\('Name',\s*'{fig_pattern}'.*?)(end\s*$)"

        def add_export(match):
            before_end = match.group(1)
            end_statement = match.group(2)

            # Check if export already exists
            if 'ExportFigureHighQuality' in before_end:
                return match.group(0)  # Already has export

            # Add export calls before 'end'
            export_code = f"""
    % Set LaTeX font for all elements
    SetLatexFont(fig);

    % Export figure in high quality
    ExportFigureHighQuality(fig, '{scenario_name}');
"""
            return before_end + export_code + "    " + end_statement

        content = re.sub(pattern, add_export, content, flags=re.MULTILINE | re.DOTALL)

    # Write back if changed
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False


def main():
    """Main function"""
    script_dir = '/home/user/Zaid_Power-Converter-Circuit-Control-Simscape/Script_Data'

    # Define export mappings for PlotGridFormingConverter.m
    grid_forming_mappings = [
        ('GridFormingConverterReactivePowerChange', 'Change_Reactive_Power_Reference'),
        ('GridFormingConverterGridVoltageChange', 'Change_Grid_Voltage'),
        ('GridFormingConverterLocalLoadChange', 'Change_Local_Load'),
        ('GridFormingConverterSmallGridFreqChange', 'Small_Grid_Frequency_Change'),
        ('GridFormingConverterLargeGridFreqChange', 'Large_Grid_Frequency_Change'),
        ('GridFormingConverterFullGridFreqChange', 'Full_Grid_Frequency_Change'),
        ('GridFormingConverter10DegGridPhaseChange', 'Grid_Phase_10_Degree_Change'),
        ('GridFormingConverter60DegGridPhaseChange', 'Grid_Phase_60_Degree_Change'),
        ('GridFormingConverterPermanentFault', 'Permanent_Three_Phase_Fault'),
        ('GridFormingConverterTemporaryFault', 'Temporary_Three_Phase_Fault'),
        ('GridFormingConverterIslanding', 'Islanding_Condition'),
    ]

    print("=" * 70)
    print("Adding Figure Export Calls to Plotting Functions")
    print("=" * 70)

    # Update PlotGridFormingConverter.m
    filepath = os.path.join(script_dir, 'PlotGridFormingConverter.m')
    if os.path.exists(filepath):
        if add_export_to_file(filepath, grid_forming_mappings):
            print(f"✓ Added exports to: PlotGridFormingConverter.m")
        else:
            print(f"- No changes: PlotGridFormingConverter.m")

    # Update other files
    other_files = {
        'PlotInertiaConstantEffects.m': [
            ('GridFormingConverterIntertiaEffect', 'Inertia_Constant_Effects')
        ],
        'PlotDampingEffects.m': [
            ('GridFormingConverterDampingEffect', 'Damping_Effects')
        ],
        'PlotBodeForController.m': [
            ('GridFormingConverterControllerBodePlot', 'Controller_Bode_Plot')
        ],
        'PlotFaultCurrentVoltageEffects.m': [
            ('GridFormingConverterThreePhaseFault', 'Three_Phase_Fault'),
            ('GridFormingConverterThreePhaseFaultStandard', 'Three_Phase_Fault_Standard')
        ],
        'PlotCompareFaultRideThroughMethod.m': [
            ('GridFormingConverterCompareFaultRideMethod', 'Compare_Fault_Ride_Methods')
        ],
    }

    for filename, mappings in other_files.items():
        filepath = os.path.join(script_dir, filename)
        if os.path.exists(filepath):
            if add_export_to_file(filepath, mappings):
                print(f"✓ Added exports to: {filename}")
            else:
                print(f"- No changes: {filename}")

    print("\n" + "=" * 70)
    print("Export addition complete!")
    print("=" * 70)


if __name__ == '__main__':
    main()
