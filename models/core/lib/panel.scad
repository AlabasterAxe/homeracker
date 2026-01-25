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
 *   
 *   Geometry:
 *   - The panel fits in the gap between Connectors.
 *   - Width/Height = (Grid Span) - Connector Size - TOLERANCE.
 *   - Thickness = BASE_STRENGTH (2mm).
 *   
 *   Tabs:
 *   - Extend from the panel edge to the Support Axis.
 *   - Hole is placed exactly on the Support Axis.
 */
module panel(rows = 1, cols = 1, tabs = [true, true, true, true]) {

  // Calculate dimensions to fit between connectors
  // Grid Span = (Units + 1) * BASE_UNIT.
  // Panel Dimension = Grid Span - CONNECTOR_SIDE_LENGTH - TOLERANCE.
  panel_width = (cols + 1) * BASE_UNIT - CONNECTOR_SIDE_LENGTH - TOLERANCE;
  panel_height = (rows + 1) * BASE_UNIT - CONNECTOR_SIDE_LENGTH - TOLERANCE;
  panel_thickness = BASE_STRENGTH;

  // Tab configuration
  // We need to reach the Support Axis.
  // Distance from Panel Center to Support Axis = Grid Span / 2.
  // Distance from Panel Center to Panel Edge = Panel Dimension / 2.
  // Edge-to-Axis = Grid/2 - Panel/2 
  //              = Grid/2 - (Grid - Connector - Tolerance)/2
  //              = (Connector + Tolerance) / 2.

  dist_to_hole = (CONNECTOR_SIDE_LENGTH + TOLERANCE) / 2;

  // Tab Length: Must cover the distance + some surrounding material for the hole.
  // Let's make it extend `dist_to_hole + BASE_UNIT/2`.
  // This gives a nice amount of material (7.5mm) past the hole.
  tab_length = dist_to_hole + BASE_UNIT / 2;
  tab_width = BASE_UNIT;

  color(HR_CHARCOAL)
    union() {
      // Main Panel Body
      cuboid([panel_width, panel_height, panel_thickness], chamfer=BASE_CHAMFER / 2, edges=TOP);

      // Tabs
      // Top (+Y)
      if (tabs[0]) {
        translate([0, panel_height / 2 + tab_length / 2, 0])
          panel_tab(tab_width, tab_length, panel_thickness, dist_to_hole);
      }

      // Bottom (-Y)
      if (tabs[1]) {
        translate([0, -(panel_height / 2 + tab_length / 2), 0])
          rotate([0, 0, 180])
            panel_tab(tab_width, tab_length, panel_thickness, dist_to_hole);
      }

      // Left (-X)
      if (tabs[2]) {
        translate([-(panel_width / 2 + tab_length / 2), 0, 0])
          rotate([0, 0, 90])
            panel_tab(tab_width, tab_length, panel_thickness, dist_to_hole);
      }

      // Right (+X)
      if (tabs[3]) {
        translate([panel_width / 2 + tab_length / 2, 0, 0])
          rotate([0, 0, -90])
            panel_tab(tab_width, tab_length, panel_thickness, dist_to_hole);
      }
    }
}

module panel_tab(width, length, thickness, dist_to_hole) {
  // Tab geometry.
  // `length` is the total length of the tab cuboid.
  // Tab is centered at `tab_length/2` from panel edge.
  // Panel edge is at `-length/2` in local coords.
  // We want the hole at `dist_to_hole` from Panel Edge.
  // Hole Pos = -length/2 + dist_to_hole.

  hole_pos_y = -length / 2 + dist_to_hole;

  difference() {
    cuboid([width, length, thickness], chamfer=BASE_CHAMFER / 2, edges=TOP);

    // Lock Pin Hole
    translate([0, hole_pos_y, 0])
      cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, thickness + 1], chamfer=-LOCKPIN_HOLE_CHAMFER);
  }
}
