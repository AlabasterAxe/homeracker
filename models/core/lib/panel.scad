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
 *   lacing (vector of 4 ints, default=[0, 0, 0, 0]):
 *       Tab generation mode for each side: [Top, Bottom, Left, Right]
 *       0: Continuous Strip (Solid, covers gaps).
 *       1: Odd Interlace (Starts at 1st slot, skips one).
 *       2: Even Interlace (Starts at 2nd slot, skips one).
 *       Used when two panels share a support rod to interleave tabs.
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
 *   - Default: Merged into a continuous strip (lacing=0).
 *   - Laced: Discrete tabs for interleaving (lacing=1 or 2).
 *   - Extend from the panel edge to the Outer Connector Edge.
 *   - Mitered at 45 degrees (Bottom-Front edge) to allow abutting panels to join neatly.
 */
module panel(rows = 1, cols = 1, tabs = [true, true, true, true], lacing = [0, 0, 0, 0]) {

  // Calculate dimensions to fit between connectors
  // Grid Span = (Units + 1) * BASE_UNIT.
  // Panel Dimension = Grid Span - CONNECTOR_SIDE_LENGTH - TOLERANCE (for 0.1mm gap each side).
  panel_width = (cols + 1) * BASE_UNIT - CONNECTOR_SIDE_LENGTH - TOLERANCE;
  panel_height = (rows + 1) * BASE_UNIT - CONNECTOR_SIDE_LENGTH - TOLERANCE;
  panel_thickness = BASE_STRENGTH;

  // Tab configuration
  // We need to reach the Support Axis.
  // Distance from Panel Center to Panel Edge is fixed by dimensions above.

  // Distance from Support Axis to Panel Edge:
  // Axis is at `Grid Span / 2` from center.
  // Panel Edge is at `Grid Span / 2 - (Connector + Tolerance)/2`.
  // So `dist_to_hole` (Panel Edge -> Axis) = `(Connector + Tolerance)/2`.
  dist_to_hole = (CONNECTOR_SIDE_LENGTH + TOLERANCE) / 2;

  // Tab Overlap Logic
  // To ensure a clean junction with the chamfered panel edge, we extend the tab *into* the panel.
  overlap = BASE_CHAMFER;

  // Extension Logic
  // The tab must extend from the Hole (Axis) to the Outer Edge of the Connector.
  // Distance from Axis to Connector Outer Edge = `CONNECTOR_SIDE_LENGTH / 2`.
  // Total Extension from Panel Edge = `dist_to_hole + Distance(Axis -> Outer Edge)`.
  extension = dist_to_hole + CONNECTOR_SIDE_LENGTH / 2;

  real_tab_length = extension + overlap;

  // Translation Offset
  // We want the "Edge" of the tab (extension start) to catch the Panel Edge.
  // Panel Edge Y = panel_height/2.
  // Tab Center Y = Panel Edge + Extension/2 - Overlap/2.
  shift_y = (extension - overlap) / 2;

  // Number of tabs calculation
  // Tabs = Size (in units) - 2.
  // This corresponds to the number of exposed support holes between connector arms.
  n_tabs_x = max(0, cols - 2);
  n_tabs_y = max(0, rows - 2);

  color(HR_CHARCOAL)
    union() {
      // Main Panel Body
      cuboid([panel_width, panel_height, panel_thickness], chamfer=BASE_CHAMFER / 2, edges=TOP);

      // Tabs
      // Top (+Y)
      if (tabs[0] && n_tabs_x > 0) {
        translate([0, panel_height / 2 + shift_y, 0])
          panel_render_tab_side(n_tabs_x, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing[0]);
      }

      // Bottom (-Y)
      if (tabs[1] && n_tabs_x > 0) {
        translate([0, -(panel_height / 2 + shift_y), 0])
          rotate([0, 0, 180])
            panel_render_tab_side(n_tabs_x, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing[1]);
      }

      // Left (-X)
      if (tabs[2] && n_tabs_y > 0) {
        translate([-(panel_width / 2 + shift_y), 0, 0])
          rotate([0, 0, 90])
            panel_render_tab_side(n_tabs_y, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing[2]);
      }

      // Right (+X)
      if (tabs[3] && n_tabs_y > 0) {
        translate([panel_width / 2 + shift_y, 0, 0])
          rotate([0, 0, -90])
            panel_render_tab_side(n_tabs_y, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing[3]);
      }
    }
}

module panel_render_tab_side(n_tabs, length, thickness, dist_to_hole, overlap, mode) {
  if (mode > 0) {
    panel_tab_laced(n_tabs, length, thickness, dist_to_hole, overlap, mode);
  } else {
    panel_tab_strip(n_tabs, length, thickness, dist_to_hole, overlap);
  }
}

module panel_tab_strip(n_tabs, length, thickness, dist_to_hole, overlap) {
  // A single continuous strip replacing multiple individual tabs.
  // Width is calculated to cover all 'n_tabs' units with tolerance.
  total_width = n_tabs * BASE_UNIT - TOLERANCE;

  // Hole Position
  hole_pos_y = -length / 2 + overlap + dist_to_hole;

  difference() {
    // Continuous block (Base)
    cuboid([total_width, length, thickness], chamfer=BASE_CHAMFER / 2, edges=TOP, except=FRONT);

    // Lock Pin Holes
    xcopies(spacing=BASE_UNIT, n=n_tabs)
      translate([0, hole_pos_y, 0])
        cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, thickness + 1], chamfer=-LOCKPIN_HOLE_CHAMFER * 1.5);

    // Miter Cut
    panel_miter_cutter(total_width, length, thickness);
  }
}

module panel_tab_laced(n_tabs, length, thickness, dist_to_hole, overlap, mode) {
  // Laced (Interleaved) tabs.
  // Generates discrete tabs based on index parity.
  // mode 1: Odd (Indices 0, 2, 4...).
  // mode 2: Even (Indices 1, 3, 5...).

  spacing = BASE_UNIT;

  // Width of a single tab leg
  // We want it slightly toleranced to not scrape neighbors.
  tab_width = BASE_UNIT - TOLERANCE;

  for (i = [0:n_tabs - 1]) {
    // Parity Check
    // Index 0 is "1st tab".
    // Mode 1 (Odd): keep 0, 2, 4...
    // Mode 2 (Even): keep 1, 3, 5...
    keep = (mode == 1 && (i % 2 == 0)) || (mode == 2 && (i % 2 == 1));

    if (keep) {
      // Position Calculation
      // Centered distribution of N items.
      // P_i = (i - (N-1)/2) * S.
      pos_x = (i - (n_tabs - 1) / 2) * spacing;

      translate([pos_x, 0, 0])
        panel_single_tab(tab_width, length, thickness, dist_to_hole, overlap);
    }
  }
}

module panel_single_tab(width, length, thickness, dist_to_hole, overlap) {
  // Single Discrete Tab Geometry.

  hole_pos_y = -length / 2 + overlap + dist_to_hole;

  difference() {
    // Base Tab
    // Note: except=FRONT prevents chamfer on junction side.
    cuboid([width, length, thickness], chamfer=BASE_CHAMFER / 2, edges=TOP, except=FRONT);

    // Hole
    translate([0, hole_pos_y, 0])
      cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, thickness + 1], chamfer=-LOCKPIN_HOLE_CHAMFER * 1.5);

    // Miter Cut
    panel_miter_cutter(width, length, thickness);
  }
}

module panel_miter_cutter(width, length, thickness) {
  // Shared Miter Cut Logic
  // Removes triangular prism from Bottom-Tip.
  // Origin of cut relative to center:
  // Tip Edge is at Y = length/2, Z = -thickness/2.
  // We extrude a triangle in X direction.
  // Vertices relative to Tip Edge (L/2, -T/2):
  // 1. (0,0) - Bottom Tip.
  // 2. (0, T) - Top Tip.
  // 3. (-T, 0) - Bottom Inner.

  translate([-(width + 1) / 2, length / 2, -thickness / 2])
    rotate([90, 0, 90])
      linear_extrude(width + 1)
        polygon([[0, 0], [0, thickness], [-thickness, 0]]);
}
