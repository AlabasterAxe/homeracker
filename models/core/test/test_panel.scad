// Test assembly for Panel Primitive
//
// Visualizes a Full Frame Configuration
// - 4 Connectors (Corners)
// - 4 Supports (Length 5)
// - 1 Panel (5x5, fitting the gap)

include <BOSL2/std.scad>
include <../main.scad>
include <../lib/constants.scad>

// Configuration
S_LEN = 5;

// Spacing Calculation
MODULE_SPACING = (S_LEN + 1) * BASE_UNIT;

module assembly() {

  // 1. Four Connectors (Corners)
  // Bottom-Left
  translate([0, 0, 0])
    rotate([-90, 0, 0])
      connector(dimensions=2, directions=2);

  // Bottom-Right
  translate([MODULE_SPACING, 0, 0])
    rotate([-90, 0, 90])
      connector(dimensions=2, directions=2);

  // Top-Right
  translate([MODULE_SPACING, MODULE_SPACING, 0])
    rotate([-90, 0, 180])
      connector(dimensions=2, directions=2);

  // Top-Left
  translate([0, MODULE_SPACING, 0])
    rotate([90, -180, 90])
      connector(dimensions=2, directions=2);

  // 2. Four Supports
  // Bottom (X-Axis)
  translate([MODULE_SPACING / 2, 0, 0])
    rotate([90, 90, 0])
      support(units=S_LEN, x_holes=true);

  // Top (X-Axis)
  translate([MODULE_SPACING / 2, MODULE_SPACING, 0])
    rotate([90, 90, 0])
      support(units=S_LEN, x_holes=true);

  // Left (Y-Axis)
  translate([0, MODULE_SPACING / 2, 0])
    rotate([0, 0, 0])
      support(units=S_LEN, x_holes=true);

  // Right (Y-Axis)
  translate([MODULE_SPACING, MODULE_SPACING / 2, 0])
    rotate([0, 0, 0])
      support(units=S_LEN, x_holes=true);

  // 3. The Panel
  // Sits in the "Gap".
  // Panel Body aligned between connectors.
  // Tabs aligned with supports.

  // Panel Y-Position:
  // Flush with support top face.
  // Support Top Face is at distance `BASE_UNIT/2` from its center axis.
  // Panel sits on top? 
  // Wait, in previous step I set Y translation to `-(BASE_UNIT/2 + BASE_STRENGTH/2)`?
  // That was for the rotated view where Support X was at Y=0?
  // Let's stick to the coordinate system here.
  // Supports are at Z=0 (Center). Z-thickness is BASE_UNIT (15mm).
  // Top Face is Z = +7.5mm.
  // Connector Top Face is Z = ~9.6mm.
  // Panel should sit on Z=7.5mm.
  // Panel Center Z = 7.5 + Thickness/2 = 7.5 + 1 = 8.5mm.

  translate([MODULE_SPACING / 2, MODULE_SPACING / 2, BASE_UNIT / 2 + BASE_STRENGTH / 2])
    color("purple")
      panel(rows=S_LEN, cols=S_LEN, tabs=[true, true, true, true]);
}

assembly();
