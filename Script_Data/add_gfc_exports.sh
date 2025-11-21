#!/bin/bash
# Add export calls to remaining PlotGridFormingConverter.m subfunctions

FILE="PlotGridFormingConverter.m"

echo "================================================================"
echo "Adding Export Calls to PlotGridFormingConverter.m Subfunctions"
echo "================================================================"

# Array of title patterns and their scenario names
declare -a SCENARIOS=(
    "Change in Grid Internal Voltage:Change_Grid_Voltage"
    "Change in Local Load:Change_Local_Load"
    "Small Change in Grid Frequency:Small_Grid_Frequency_Change"
    "Large Change in Grid Frequency:Large_Grid_Frequency_Change"
    "Full Range Grid Frequency Change:Full_Grid_Frequency_Change"
    "Change in Grid Phase by 10 degrees:Grid_Phase_10_Degree_Change"
    "Change in Grid Phase by 60 degrees:Grid_Phase_60_Degree_Change"
    "Permanent Three-Phase Fault:Permanent_Three_Phase_Fault"
    "Temporary Three-Phase Fault:Temporary_Three_Phase_Fault"
    "Islanding Condition:Islanding_Condition"
)

for scenario in "${SCENARIOS[@]}"; do
    IFS=':' read -r title name <<< "$scenario"

    # Check if already exists
    if grep -q "ExportFigureHighQuality(fig, '$name')" "$FILE"; then
        echo "  - Already exists: $name"
        continue
    fi

    # Use perl to add the export block after figureTitle for this specific title
    perl -i -0777 -pe "
        s/(figTitle = '$title';\\s*figureTitle\\(figTitle,outValue\\);)\\s*(end)/\$1\\n\\n    % Set LaTeX font for all elements\\n    SetLatexFont(fig);\\n\\n    % Export figure in high quality\\n    ExportFigureHighQuality(fig, '$name');\\n\$2/g
    " "$FILE"

    echo "  ✓ Added: $name"
done

echo ""
echo "================================================================"
echo "All PlotGridFormingConverter.m exports added!"
echo "================================================================"
