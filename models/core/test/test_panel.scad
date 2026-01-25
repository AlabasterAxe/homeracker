// Test assembly for Panel Primitive
//
// Visualizes a 1x1 panel mounted on a basic frame.

include <BOSL2/std.scad>
include <../main.scad>
include <../lib/constants.scad>

// 1. Create a frame
// 4 Connectors (2D 2-Way Corner style)
// 4 Supports (1 unit length)

// Support length (units)
S_LEN = 1;
// Distance between connector centers = S_LEN * BASE_UNIT + 2 * (BASE_UNIT/2 + Something? No)
// Connector center to arm start = BASE_UNIT (core_to_arm_translation)??
// Let's re-read connector placement logic.
// Connector core is centered.
// Arm attaches.
// Support fits INTO the arm? Or arm fits into support?
// Support has holes. Connector has pins?
// No, Connector has arms. Support is a block.
// Arms have "Inner" (void).
// So Supports fit INTO Connector Arms.
// The Arm extends `BASE_UNIT` from the core center (approx).
// Wait, `core_to_arm_translation = BASE_UNIT`.
// The arm cutout is centered at `BASE_UNIT`.
// The Support slides in.
// How deep?
// The hole in the support is at `BASE_UNIT/2` from the end?
// The hole in the connector arm is at `BASE_UNIT` from core center.
// So if the holes align:
// Support End is at `BASE_UNIT` (hole location) + `BASE_UNIT/2` (dist to end) = 1.5 * BASE_UNIT from core center?
// Or: Connector Hole is at Global X = BASE_UNIT.
// Support Hole is at Local X = BASE_UNIT/2.
// To align, Support must be translated so Local X aligns with Global X.
// If Support is between two connectors.
// Left Connector at 0. Right Connector at D.
// Left Connector Hole at +BASE_UNIT.
// Support starts at ?
// Support Length = S_LEN * BASE_UNIT.
// Holes at 0.5, 1.5, ...
// The first hole (0.5) needs to align with Left Connector Hole (+BASE_UNIT).
// So Support Start is at +BASE_UNIT - 0.5*BASE_UNIT = +0.5*BASE_UNIT.
// Support End is at Start + Length = 0.5*BASE_UNIT + S_LEN*BASE_UNIT.
// Right Connector Hole needs to align with Last Support Hole.
// Last Support Hole is at Start + (S_LEN - 0.5)*BASE_UNIT.
// = 0.5*BASE_UNIT + S_LEN*BASE_UNIT - 0.5*BASE_UNIT = S_LEN*BASE_UNIT.
// Right Connector core center?
// Right Connector Hole is at Center - BASE_UNIT.
// So Center - BASE_UNIT = S_LEN*BASE_UNIT.
// Center = (S_LEN + 1) * BASE_UNIT.
// So spacing between connector centers is `(S_LEN + 1) * BASE_UNIT`.

MODULE_SPACING = (S_LEN + 1) * BASE_UNIT;

module assembly() {
  // 4 Connectors
  translate([0, 0, 0]) connector(dimensions=2, directions=2); // Bottom-Left
  translate([MODULE_SPACING, 0, 0]) rotate([0, 0, 90]) connector(dimensions=2, directions=2); // Bottom-Right
  translate([MODULE_SPACING, MODULE_SPACING, 0]) rotate([0, 0, 180]) connector(dimensions=2, directions=2); // Top-Right
  translate([0, MODULE_SPACING, 0]) rotate([0, 0, -90]) connector(dimensions=2, directions=2); // Top-Left

  // 4 Supports
  // Bottom
  translate([BASE_UNIT / 2, 0, 0]) rotate([0, 90, 0]) support(units=S_LEN);
  // Top
  translate([BASE_UNIT / 2, MODULE_SPACING, 0]) rotate([0, 90, 0]) support(units=S_LEN);
  // Left
  translate([0, BASE_UNIT / 2, 0]) rotate([-90, 0, 0]) support(units=S_LEN);
  // Right
  translate([MODULE_SPACING, BASE_UNIT / 2, 0]) rotate([-90, 0, 0]) support(units=S_LEN);

  // The Panel
  // It should cover the hole in the middle.
  // Center of the hole is at [MODULE_SPACING/2, MODULE_SPACING/2].
  // Z-height? 
  // Connectors height: +/- connector_outer_side_length/2 = +/- 9.6mm.
  // Support height: 15mm (centered). +/- 7.5mm.
  // Panel sits ON TOP of supports?
  // Max Z of support = 7.5mm.
  // So Panel Bottom = 7.5mm.
  // Panel Center Z = 7.5 + thickness/2 = 7.5 + 1 = 8.5mm.

  translate([MODULE_SPACING / 2, MODULE_SPACING / 2, BASE_UNIT / 2 + BASE_STRENGTH / 2])
    color("purple")
      panel(rows=S_LEN, cols=S_LEN);

  // Lock Pins (Visualizing one)
  // Inserting into Bottom Support, Top Face.
  // Hole location: [MODULE_SPACING/2, 0, 7.5].
  // Aligning with Panel Tab.
  // Pin goes vertically down?
  // Supports have holes Y-copies (along length). And optionally X-holes.
  // Standard support: `lock_pin_hole()` is created `ycopies`.
  // The `lock_pin_hole` module creates a hole centered at origin?
  // It creates `prismoid` etc.
  // In `support()`: `ycopies... lock_pin_hole()`.
  // `ycopies` spreads along Y.
  // The support is oriented along Y by default.
  // `lock_pin_hole` Z axis is the hole axis?
  // `lock_pin_hole` creates a hole along Z axis (height).
  // So yes, vertical holes are present.

  // Check if Panel Tab Hole aligns.
  // Panel is at `MODULE_SPACING/2` (Center of assembly).
  // Bottom Tab is at `-panel_height/2 - tab_length/2`.
  // `panel_height` = S_LEN * 15.
  // `tab_length` = 15.
  // Support is at Y=0.
  // Panel Center Y = `MODULE_SPACING/2` = (S_LEN+1)*15 / 2.
  // Bottom Tab Y relative to Panel Center = -(S_LEN*15/2 + 7.5) = - (S_LEN*7.5 + 7.5).
  // Global Y of Tab Hole = (S_LEN+1)*7.5 - (S_LEN+1)*7.5 = 0.
  // Perfect. It aligns with Y=0 (Center of Support).
}

assembly();
