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

/* [Tabs] */
// Top Tab
Top_Tab = true;
// Bottom Tab
Bottom_Tab = true;
// Left Tab
Left_Tab = true;
// Right Tab
Right_Tab = true;

module make_panel() {
  panel(rows=Rows, cols=Cols, tabs=[Top_Tab, Bottom_Tab, Left_Tab, Right_Tab]);
}

make_panel();
