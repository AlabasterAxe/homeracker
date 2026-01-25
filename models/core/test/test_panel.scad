// Test assembly for Panel Primitive
//
// Visualizes a Single Corner Configuration
// - 1 Connector (Corner)
// - 2 Supports (Length 3)
// - 1 Panel (1x1, fitting the gap)

include <BOSL2/std.scad>
include <../main.scad>
include <../lib/constants.scad>

// Configuration
S_LEN = 3; // Minimum length for standard frame w/ connectors

// Spacing Calculation
// Support Length = 45mm.
// Insertion Depth = 7.5mm (approx bottoming out).
// Distance Center-to-Center = Length + 15mm = 60mm.
MODULE_SPACING = (S_LEN + 1) * BASE_UNIT;

module assembly() {

  // 1. Single Connector at Origin
  connector(dimensions=2, directions=2);

  // 2. Two Supports extending from it
  // X-Axis Support
  // Centered at MODULE_SPACING / 2
  translate([0, 0, MODULE_SPACING / 2])
    rotate([90, 0, 0])
      support(units=S_LEN, true);

  // Y-Axis Support
  translate([MODULE_SPACING / 2, 0, 0])
    rotate([0, 0, 90])
      support(units=S_LEN, true);

  // 4. Visualizing Lock Pin Alignment
  // Show a pin in the X-Support, 1st hole (closest to connector)? 
  // No, Panel Tabs attach to the OUTERMOST holes of the gap?
  // Let's trace:
  // Support Center 30.
  // Holes at 15, 30, 45.
  // Connector at 0. Arm extends to 22.5.
  // Hole 15 is INSIDE the connector arm?
  // 15 < 22.5. Yes! 
  // So the 1st hole is used by the Connector Lock Pin!
  // The Panel Tabs must attach to the EXPOSED holes.
  // Exposed holes: 30, 45?
  // Arm ends 22.5.
  // Hole 30 is exposed.
  // Hole 45 is exposed?
  // If next connector is at 60. Arm ends at 60-22.5 = 37.5.
  // So Hole 45 is INSIDE the next connector!
  // So ONLY Hole 30 is exposed?
  // Yes! For S_LEN=3, only the middle hole is exposed.
  // So the Panel Tab must align with Hole 30.
  // Panel Center 30.
  // 1x1 Panel. Tab is shorter?
  // Tab Hole at Panel Center +/- Offset?
  // In `panel.scad`: `translate... panel_tab()`.
  // `panel_tab` has hole at Center.
  // Panel Tab @ Bottom (-Y).
  // Tab Center Y relative to Panel Center:
  // -(panel_height/2 + tab_length/2).
  // panel_height = 15. tab_length = 15.
  // Y = -(7.5 + 7.5) = -15.
  // Global Y = 30 - 15 = 15.
  // Support Y-Center is 30. 
  // Wait.
  // Support X-Axis (at Y=0).
  // Panel Center Y=30.
  // Tab reaches down to Y=15?
  // Support is at Y=0.
  // Gap Y is 15mm?
  // Panel Center 30. Bottom Tab Hole 15.
  // Support Center 0.
  // They do NOT align. 
  // The Tab Hole is at Y=15. The Support is at Y=0.
  // Distance 15mm.
  // The Tab needs to reach Y=0.
  // Currently Tab Length = 15mm.
  // Reaches from Edge (22.5) to (7.5)?
  // Center 30. Height 15. Edge at 22.5 (30-7.5).
  // Tab starts at 22.5. Length 15.
  // Ends at 22.5 - 15 = 7.5.
  // Hole at 15.
  // Support at 0.
  // We need Tab to reach 0.
  // So Tab must be Longer? Or Panel Bigger?
  // If Panel 1x1 is 15mm gap.
  // Supported Frame is 60mm spacing.
  // Gap 45mm?
  // Inner Gap = 60 - 7.5 - 7.5 = 45mm.
  // So Panel MUST be 45mm (3x3).
  // My calculation `S_LEN - 2` gave 1.
  // It should be `S_LEN`?
  // If Panel is 3x3 (45mm).
  // Center 30.
  // Edge at 30 - 22.5 = 7.5.
  // Support Edge at 7.5.
  // So Panel touches Support!
  // But fits poorly?
  // Support surface is at Z=7.5.
  // Panel sits on Z=7.5.
  // So Panel Edge (7.5) is flush with Support Inner Edge (7.5).
  // This implies the Panel covers the ENTIRE opening.
  // AND overlaps the support?
  // If Panel Edge is 7.5.
  // Tab extends from 7.5 downwards.
  // To reach Support Center (0).
  // Tab needs to go from 7.5 to ...
  // Length 15?
  // Starts 7.5. Ends -7.5.
  // Center 0.
  // Perfect!
  // So Panel Size MUST be `rows=S_LEN`, `cols=S_LEN`.
  // NOT `S_LEN - 2`.
  // Re-verify `S_LEN=1`.
  // Panel 1x1. Width 15.
  // Spacing 30.
  // Inner Gap = 30 - 15 = 15.
  // Panel fits exactly.
  // Tab reaches 0.
  // So calculation is `PANEL_SIZE = S_LEN`.
  translate([MODULE_SPACING / 2, -(BASE_UNIT / 2 + BASE_STRENGTH / 2), MODULE_SPACING / 2])
    rotate([90, 0, 0])
      color("purple")
        panel(rows=S_LEN, cols=S_LEN);
}

assembly();
