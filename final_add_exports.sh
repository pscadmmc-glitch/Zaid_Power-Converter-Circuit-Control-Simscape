#!/bin/bash
# Final script to add all export calls systematically

cd /home/user/Zaid_Power-Converter-Circuit-Control-Simscape/Script_Data

echo "================================================================"
echo "Adding Export Calls to All Plotting Functions"
echo "================================================================"

# Function to add export block after a pattern
add_export_block() {
    local file=$1
    local search_pattern=$2
    local scenario_name=$3
    local fig_var=$4  # Either 'fig' or 'gcf'

    # Check if already exists
    if grep -q "ExportFigureHighQuality($fig_var, '$scenario_name')" "$file"; then
        echo "  - Already exists: $scenario_name in $file"
        return
    fi

    # Add the export block
    perl -i -pe "
        if (/$search_pattern/) {
            \$_ .= qq(
    % Set LaTeX font for all elements
    SetLatexFont($fig_var);

    % Export figure in high quality
    ExportFigureHighQuality($fig_var, '$scenario_name');
);
        }
    " "$file"

    echo "  ✓ Added: $scenario_name to $file"
}

# PlotInertiaConstantEffects.m
echo ""
echo "Processing PlotInertiaConstantEffects.m..."
add_export_block "PlotInertiaConstantEffects.m" \
    "sgtitle\('Effects of Virtual Synchronous Machine Inertia Constant'" \
    "Inertia_Constant_Effects" \
    "gcf"

# PlotDampingEffects.m
echo ""
echo "Processing PlotDampingEffects.m..."
add_export_block "PlotDampingEffects.m" \
    "sgtitle\('Effects of Virtual Synchronous Machine Damping Coefficient'" \
    "Damping_Effects" \
    "gcf"

# PlotBodeForController.m - add after sgtitle(titleInput)
echo ""
echo "Processing PlotBodeForController.m..."
if ! grep -q "ExportFigureHighQuality" PlotBodeForController.m; then
    perl -i -pe '
        if (/sgtitle\(titleInput/) {
            $_ .= qq(
    % Set LaTeX font for all elements
    SetLatexFont(fig);

    % Export figure in high quality
    controllerSafe = strrep(titleInput, " ", "_");
    controllerSafe = strrep(controllerSafe, " ", "");
    ExportFigureHighQuality(fig, ["Controller_Bode_Plot_" controllerSafe]);
);
        }
    ' PlotBodeForController.m
    echo "  ✓ Added: Controller Bode Plot exports"
else
    echo "  - Already exists: Controller Bode Plot exports"
fi

# PlotFaultCurrentVoltageEffects.m - add two exports
echo ""
echo "Processing PlotFaultCurrentVoltageEffects.m..."

# First figure - three phase fault
if ! grep -q "ExportFigureHighQuality.*Three_Phase_Fault'" PlotFaultCurrentVoltageEffects.m; then
    perl -i -pe '
        if (/sgtitle\(\[.*Three-Phase Fault Measurement/ && !/SetLatexFont/) {
            $_ .= qq(
    % Set LaTeX font for all elements
    SetLatexFont(gcf);

    % Export figure in high quality
    ExportFigureHighQuality(gcf, "Three_Phase_Fault");
);
        }
    ' PlotFaultCurrentVoltageEffects.m
    echo "  ✓ Added: Three Phase Fault export"
else
    echo "  - Already exists: Three Phase Fault export"
fi

# Second figure - standard plot
if ! grep -q "ExportFigureHighQuality.*Three_Phase_Fault_Standard'" PlotFaultCurrentVoltageEffects.m; then
    perl -i -pe '
        if (/plotCurrentLimitStandard\(outValue\);/ && !/SetLatexFont/) {
            $_ .= qq(
    % Set LaTeX font for all elements
    SetLatexFont(gcf);

    % Export figure in high quality
    ExportFigureHighQuality(gcf, "Three_Phase_Fault_Standard");
);
        }
    ' PlotFaultCurrentVoltageEffects.m
    echo "  ✓ Added: Three Phase Fault Standard export"
else
    echo "  - Already exists: Three Phase Fault Standard export"
fi

# PlotCompareFaultRideThroughMethod.m
echo ""
echo "Processing PlotCompareFaultRideThroughMethod.m..."
if ! grep -q "ExportFigureHighQuality" PlotCompareFaultRideThroughMethod.m; then
    # Add after the last subplot configuration before disp
    perl -i -pe '
        if (/disp\(.*Steady State Grid-Forming Converter Output to Compare/) {
            $_ = qq(    % Set LaTeX font for all elements
    SetLatexFont(fig);

    % Export figure in high quality
    ExportFigureHighQuality(fig, "Compare_Fault_Ride_Through_Methods");

$_);
        }
    ' PlotCompareFaultRideThroughMethod.m
    echo "  ✓ Added: Compare Fault Ride Through export"
else
    echo "  - Already exists: Compare Fault Ride Through export"
fi

echo ""
echo "================================================================"
echo "Export calls addition complete!"
echo "================================================================"
echo ""
echo "Remaining: PlotGridFormingConverter.m subfunctions"
echo "These will be added with a separate targeted script..."
