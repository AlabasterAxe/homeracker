// HomeRacker - Core Panel
//
// This model is part of the HomeRacker - Core system.
//
// MIT License
// Copyright (c) 2025 Patrick Pötz
//

include <BOSL2/std.scad>
include <constants.scad>

/**
 * HomeRacker Panel Module
 *
 * Parameters:
 *   rows (int, default=1): Number of support units in height (Y-axis grid).
 *   cols (int, default=1): Number of support units in width (X-axis grid).
 *   tabs (vector of 4 bools, default=[true, true, true, true]): 
 *       Which tabs to generate: [Top (+Y), Bottom (-Y), Left (-X), Right (+X)]
 *       Note: Direction mapping is relative to the panel center.
 *
 * Produces:
 *   A flat panel to cover gaps between supports.
 *   Thickness is BASE_STRENGTH (2mm).
 *   Tabs extend to mount onto supports using lock pins.
 */
module panel(rows = 1, cols = 1, tabs = [true, true, true, true]) {

  panel_width = cols * BASE_UNIT;
  panel_height = rows * BASE_UNIT;
  panel_thickness = BASE_STRENGTH;

  // Tab configuration
  tab_length = BASE_UNIT; // Extends 1 unit over the support
  // The hole in the support is at the center of the unit.
  // If the support is length 1, the hole is at 7.5mm.
  // The tab starts at the edge of the panel.
  // To align with the hole (which is at BASE_UNIT/2 from the start of the support),
  // The hole in the tab should be at BASE_UNIT/2 from the panel edge.

  hole_offset = BASE_UNIT / 2;

  // The tab width - should it be full BASE_UNIT? 
  // Supports are BASE_UNIT wide (15mm).
  // Let's make tabs BASE_UNIT wide for now.
  tab_width = BASE_UNIT;

  color(HR_CHARCOAL)
    union() {
      // Main Panel Body
      cuboid([panel_width, panel_height, panel_thickness], chamfer=BASE_CHAMFER / 2, edges=TOP);

      // Tabs
      // Top (+Y)
      if (tabs[0]) {
        translate([0, panel_height / 2 + tab_length / 2, 0])
          panel_tab();
      }

      // Bottom (-Y)
      if (tabs[1]) {
        translate([0, -(panel_height / 2 + tab_length / 2), 0])
          rotate([0, 0, 180])
            panel_tab();
      }

      // Left (-X)
      if (tabs[2]) {
        translate([-(panel_width / 2 + tab_length / 2), 0, 0])
          rotate([0, 0, 90])
            panel_tab();
      }

      // Right (+X)
      if (tabs[3]) {
        translate([panel_width / 2 + tab_length / 2, 0, 0])
          rotate([0, 0, -90])
            panel_tab();
      }
    }
}

module panel_tab() {
  // A tab is size [tab_width, tab_length, thickness]
  // With a lock pin hole at [0, 0] (relative to tab center? No.)
  // We want the hole to be at distance `hole_offset` from the panel edge.
  // My tab positioning logic in main module centers the tab at `panel_edge + tab_length/2`.
  // So the tab center is at `tab_length/2` from the panel edge.
  // The panel edge is at `-tab_length/2` in local coords.
  // The hole needs to be at `panel_edge + hole_offset` 
  // = `-tab_length/2 + hole_offset`.
  // Since `tab_length` = `BASE_UNIT` and `hole_offset` = `BASE_UNIT/2`,
  // `-BASE_UNIT/2 + BASE_UNIT/2` = 0.
  // So the hole is exactly at the center of the tab! Convenient.

  width = BASE_UNIT;
  length = BASE_UNIT;
  thickness = BASE_STRENGTH;

  difference() {
    cuboid([width, length, thickness], chamfer=BASE_CHAMFER / 2, edges=TOP);
    // Lock Pin Hole
    // Supports use `lock_pin_hole()` which creates a complex shape.
    // We just need a square hole that fits the pin.
    // The pin is 4x4mm.
    // Let's use `cuboid` hole + chamfer.

    cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, thickness + 1], chamfer=-LOCKPIN_HOLE_CHAMFER);
  }
}
