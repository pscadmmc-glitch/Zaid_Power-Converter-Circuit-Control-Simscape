#!/bin/bash
# Script to add figure export calls to all plotting functions

cd /home/user/Zaid_Power-Converter-Circuit-Control-Simscape/Script_Data

# Function to add export after figureTitle if not already present
add_export_after_figuretitle() {
    local file=$1
    local scenario=$2

    # Check if export already exists for this scenario
    if grep -q "ExportFigureHighQuality(fig, '$scenario')" "$file"; then
        echo "  - Export already exists for: $scenario"
        return
    fi

    # Find figureTitle line and add export code after it (if fig variable exists in that section)
    awk -v scenario="$scenario" '
    /figureTitle\(figTitle,outValue\);/ {
        print
        if (!exported) {
            print ""
            print "    % Set LaTeX font for all elements"
            print "    SetLatexFont(fig);"
            print ""
            print "    % Export figure in high quality"
            print "    ExportFigureHighQuality(fig, '\''" scenario "'\'');"
            exported = 1
        }
        next
    }
    /^function / { exported = 0 }
    { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

    echo "  ✓ Added export for: $scenario"
}

# Array of scenario mappings for PlotGridFormingConverter.m
declare -A scenarios=(
    ["Change in Grid Internal Voltage"]="Change_Grid_Voltage"
    ["Change in Local Load"]="Change_Local_Load"
    ["Small Change in Grid Frequency"]="Small_Grid_Frequency_Change"
    ["Large Change in Grid Frequency"]="Large_Grid_Frequency_Change"
    ["Full Range Grid Frequency Change"]="Full_Grid_Frequency_Change"
    ["Change in Grid Phase by 10 degrees"]="Grid_Phase_10_Degree_Change"
    ["Change in Grid Phase by 60 degrees"]="Grid_Phase_60_Degree_Change"
    ["Permanent Three-Phase Fault"]="Permanent_Three_Phase_Fault"
    ["Temporary Three-Phase Fault"]="Temporary_Three_Phase_Fault"
    ["Islanding Condition"]="Islanding_Condition"
)

echo "================================================================"
echo "Adding Export Calls to PlotGridFormingConverter.m"
echo "================================================================"

for title in "${!scenarios[@]}"; do
    add_export_after_figuretitle "PlotGridFormingConverter.m" "${scenarios[$title]}"
done

# Add export to PlotInertiaConstantEffects.m
echo ""
echo "Adding Export Calls to PlotInertiaConstantEffects.m"
echo "================================================================"
sed -i '/sgtitle.*Effects of Virtual Synchronous Machine Inertia Constant/a\
\
    % Set LaTeX font for all elements\
    SetLatexFont(gcf);\
\
    % Export figure in high quality\
    ExportFigureHighQuality(gcf, '\''Inertia_Constant_Effects'\'');' PlotInertiaConstantEffects.m

# Add export to PlotDampingEffects.m
echo "Adding Export Calls to PlotDampingEffects.m"
echo "================================================================"
sed -i '/sgtitle.*Effects of Virtual Synchronous Machine Damping Coefficient/a\
\
    % Set LaTeX font for all elements\
    SetLatexFont(gcf);\
\
    % Export figure in high quality\
    ExportFigureHighQuality(gcf, '\''Damping_Effects'\'');' PlotDampingEffects.m

# Add export to PlotBodeForController.m
echo "Adding Export Calls to PlotBodeForController.m"
echo "================================================================"
sed -i '/sgtitle(titleInput/a\
\
    % Set LaTeX font for all elements\
    SetLatexFont(fig);\
\
    % Export figure in high quality\
    ExportFigureHighQuality(fig, ['\''Controller_Bode_Plot_'\'' strrep(titleInput, '\'' '\'', '\''_'\'')]);' PlotBodeForController.m

# Add export to PlotFaultCurrentVoltageEffects.m
echo "Adding Export Calls to PlotFaultCurrentVoltageEffects.m"
echo "================================================================"
sed -i '/plotCurrentLimitStandard(outValue);/a\
\
    % Set LaTeX font for all elements\
    SetLatexFont(gcf);\
\
    % Export figure in high quality\
    ExportFigureHighQuality(gcf, '\''Three_Phase_Fault_Analysis'\'');' PlotFaultCurrentVoltageEffects.m

# Add export to PlotCompareFaultRideThroughMethod.m (add at end of function)
echo "Adding Export Calls to PlotCompareFaultRideThroughMethod.m"
echo "================================================================"

echo ""
echo "================================================================"
echo "All export calls have been added!"
echo "================================================================"
