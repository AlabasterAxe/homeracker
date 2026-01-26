// HomeRacker - Panel Part
//
// Customizable panel for the HomeRacker system.
// Open this file in OpenSCAD and use the Customizer to configure.
//
// MIT License
// Copyright (c) 2025 Patrick Pötz

use <../lib/panel.scad>

/* [Dimensions] */
// Number of rows (height units)
Rows = 1; // [1:20]

// Number of columns (width units)
Cols = 1; // [1:20]

/* [Edge Styles] */
Top_Style = "tab"; // [none, tab, laced_odd, laced_even]
Bottom_Style = "tab"; // [none, tab, laced_odd, laced_even]
Left_Style = "tab"; // [none, tab, laced_odd, laced_even]
Right_Style = "tab"; // [none, tab, laced_odd, laced_even]

/* [Edge Holes] */
Top_Holes = true;
Bottom_Holes = true;
Left_Holes = true;
Right_Holes = true;

/* [Edge Connectors] */
// Enable if using standard corner connectors. Disable to extend tabs fully (Connectorless).
Top_Connectors = true;
Bottom_Connectors = true;
Left_Connectors = true;
Right_Connectors = true;

module make_panel() {
  panel(
    rows=Rows, 
    cols=Cols, 
    edge_styles=[Top_Style, Bottom_Style, Left_Style, Right_Style],
    edge_holes=[Top_Holes, Bottom_Holes, Left_Holes, Right_Holes],
    edge_cutouts=[
        [Top_Connectors, Top_Connectors],
        [Bottom_Connectors, Bottom_Connectors],
        [Left_Connectors, Left_Connectors],
        [Right_Connectors, Right_Connectors]
    ]
  );
}

make_panel();
