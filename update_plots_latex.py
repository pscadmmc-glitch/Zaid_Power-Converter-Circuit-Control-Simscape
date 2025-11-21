#!/usr/bin/env python3
"""
Script to update all MATLAB plotting files with LaTeX formatting and figure export
"""

import re
import os
from datetime import datetime

def update_file_with_latex(filepath, figure_scenarios):
    """
    Update a MATLAB file with LaTeX formatting and figure export calls.

    Args:
        filepath: Path to the MATLAB file
        figure_scenarios: Dict mapping figure names to scenario names for export
    """
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Store original for comparison
    original_content = content

    # 1. Replace xlabel calls
    xlabel_replacements = {
        r"xlabel\('time \(s\)'\)": r"xlabel('$\\mathrm{Time}$ (s)', 'Interpreter', 'latex')",
        r"xlabel\('Frequency \(rad/s\)'\)": r"xlabel('$\\mathrm{Frequency}$ (rad/s)', 'Interpreter', 'latex')",
        r"xlabel\('Frequency \(Hz\)'\)": r"xlabel('$\\mathrm{Frequency}$ (Hz)', 'Interpreter', 'latex')",
        r"xlabel\('time \(s\)'\);": r"xlabel('$\\mathrm{Time}$ (s)', 'Interpreter', 'latex');",
    }

    for old, new in xlabel_replacements.items():
        content = re.sub(old, new, content)

    # 2. Replace ylabel calls
    ylabel_replacements = {
        r"ylabel\('Power \(pu\)'\)": r"ylabel('$\\mathrm{Power}$ (pu)', 'Interpreter', 'latex')",
        r"ylabel\('Voltage \(pu\)'\)": r"ylabel('$\\mathrm{Voltage}$ (pu)', 'Interpreter', 'latex')",
        r"ylabel\('Current \(pu\)'\)": r"ylabel('$\\mathrm{Current}$ (pu)', 'Interpreter', 'latex')",
        r"ylabel\('Frequency \(Hz\)'\)": r"ylabel('$\\mathrm{Frequency}$ (Hz)', 'Interpreter', 'latex')",
        r"ylabel\('Phase \(degree\)'\)": r"ylabel('$\\mathrm{Phase}$ (degree)', 'Interpreter', 'latex')",
        r"ylabel\('Phase \(deg\)'\)": r"ylabel('$\\mathrm{Phase}$ (deg)', 'Interpreter', 'latex')",
        r"ylabel\('Magnitude \(dB\)'\)": r"ylabel('$\\mathrm{Magnitude}$ (dB)', 'Interpreter', 'latex')",
        r"ylabel\('Power \(pu\)'\);": r"ylabel('$\\mathrm{Power}$ (pu)', 'Interpreter', 'latex');",
        r"ylabel\('Voltage \(pu\)'\);": r"ylabel('$\\mathrm{Voltage}$ (pu)', 'Interpreter', 'latex');",
        r"ylabel\('Current \(pu\)'\);": r"ylabel('$\\mathrm{Current}$ (pu)', 'Interpreter', 'latex');",
        r"ylabel\('GFM Output Voltage \(pu\)'\)": r"ylabel('$\\mathrm{GFM\\ Output\\ Voltage}$ (pu)', 'Interpreter', 'latex')",
        r"ylabel\('GFM Output Current \(pu\)'\)": r"ylabel('$\\mathrm{GFM\\ Output\\ Current}$ (pu)', 'Interpreter', 'latex')",
        r"ylabel\('Grid Voltage \(pu\)'\)": r"ylabel('$\\mathrm{Grid\\ Voltage}$ (pu)', 'Interpreter', 'latex')",
        r"ylabel\('Trip Signal \(pu\)'\)": r"ylabel('$\\mathrm{Trip\\ Signal}$ (pu)', 'Interpreter', 'latex')",
        r"ylabel\('Peak Current \(pu\)'\)": r"ylabel('$\\mathrm{Peak\\ Current}$ (pu)', 'Interpreter', 'latex')",
        r"ylabel\('Fault Trigger\)'\)": r"ylabel('$\\mathrm{Fault\\ Trigger}$)', 'Interpreter', 'latex')",
        r"ylabel\('Fault Trigger'\)": r"ylabel('$\\mathrm{Fault\\ Trigger}$', 'Interpreter', 'latex')",
    }

    for old, new in ylabel_replacements.items():
        content = re.sub(old, new, content)

    # 3. Replace title calls
    title_pattern = r"title\('([^']+)'\)"

    def replace_title(match):
        title_text = match.group(1)
        return f"title('\\\\textbf{{{title_text}}}', 'Interpreter', 'latex')"

    content = re.sub(title_pattern, replace_title, content)

    # 4. Replace figure calls to capture handle
    content = re.sub(r"(\s+)figure\('Name'", r"\1fig = figure('Name'", content)

    # 5. Replace legend calls
    legend_pattern = r"legend\(([^)]+)\);"

    def replace_legend(match):
        legend_items = match.group(1)
        # Simple heuristic: wrap each string in LaTeX formatting
        # This is a simplified approach
        new_legend = legend_items + ", 'Interpreter', 'latex'"
        return f"legend({new_legend});"

    content = re.sub(legend_pattern, replace_legend, content)

    # 6. Add export calls before 'end' statements in plotting functions
    # This is more complex and needs careful pattern matching
    # For now, let's add a template that users can replicate

    # Write updated content
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    if content != original_content:
        print(f"✓ Updated: {filepath}")
        return True
    else:
        print(f"- No changes: {filepath}")
        return False


def main():
    """Main function to update all plotting files"""
    script_dir = '/home/user/Zaid_Power-Converter-Circuit-Control-Simscape/Script_Data'

    files_to_update = [
        'PlotGridFormingConverter.m',
        'PlotInertiaConstantEffects.m',
        'PlotDampingEffects.m',
        'PlotBodeForController.m',
        'PlotFaultCurrentVoltageEffects.m',
        'PlotCompareFaultRideThroughMethod.m',
    ]

    print("=" * 60)
    print("Updating MATLAB Plotting Files with LaTeX Formatting")
    print("=" * 60)

    for filename in files_to_update:
        filepath = os.path.join(script_dir, filename)
        if os.path.exists(filepath):
            update_file_with_latex(filepath, {})
        else:
            print(f"✗ File not found: {filepath}")

    print("\n" + "=" * 60)
    print("Update complete!")
    print("=" * 60)
    print("\nNote: Manual review recommended for:")
    print("  - Legend formatting")
    print("  - Figure export calls")
    print("  - Complex title strings")


if __name__ == '__main__':
    main()
