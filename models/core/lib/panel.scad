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
 *   - Merged into a continuous strip to eliminate gaps between prongs.
 *   - Extend from the panel edge to the Outer Connector Edge.
 *   - Mitered at 45 degrees (Bottom-Front edge chamfer) to allow abutting panels to join neatly.
 *   - Holes placed at BASE_UNIT spacing to match support holes.
 */
module panel(rows = 1, cols = 1, tabs = [true, true, true, true]) {

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
          panel_tab_strip(n_tabs_x, real_tab_length, panel_thickness, dist_to_hole, overlap);
      }

      // Bottom (-Y)
      if (tabs[1] && n_tabs_x > 0) {
        translate([0, -(panel_height / 2 + shift_y), 0])
          rotate([0, 0, 180])
            panel_tab_strip(n_tabs_x, real_tab_length, panel_thickness, dist_to_hole, overlap);
      }

      // Left (-X)
      if (tabs[2] && n_tabs_y > 0) {
        translate([-(panel_width / 2 + shift_y), 0, 0])
          rotate([0, 0, 90])
            panel_tab_strip(n_tabs_y, real_tab_length, panel_thickness, dist_to_hole, overlap);
      }

      // Right (+X)
      if (tabs[3] && n_tabs_y > 0) {
        translate([panel_width / 2 + shift_y, 0, 0])
          rotate([0, 0, -90])
            panel_tab_strip(n_tabs_y, real_tab_length, panel_thickness, dist_to_hole, overlap);
      }
    }
}

module panel_tab_strip(n_tabs, length, thickness, dist_to_hole, overlap) {
  // A single continuous strip replacing multiple individual tabs.
  // Width is calculated to cover all 'n_tabs' units with tolerance.
  total_width = n_tabs * BASE_UNIT - TOLERANCE;

  // Hole Position
  // Tab ranges from [-length/2, length/2].
  // The "Junction Line" (Panel Edge) is at: -length/2 + overlap.
  // Hole is at `dist_to_hole` from Junction Line.
  hole_pos_y = -length / 2 + overlap + dist_to_hole;

  // Miter Cut Logic
  // We want to slice off the Bottom-Outer corner at 45 degrees.
  // This creates a mitered edge for abutting panels.

  difference() {
    // Continuous block (Base)
    cuboid([total_width, length, thickness], chamfer=BASE_CHAMFER / 2, edges=TOP, except=FRONT);

    // Lock Pin Holes
    xcopies(spacing=BASE_UNIT, n=n_tabs)
      translate([0, hole_pos_y, 0])
        cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, thickness + 1], chamfer=-LOCKPIN_HOLE_CHAMFER * 1.5);

    // Miter Cut
    // Remove triangular prism from Bottom-Tip to create the slope.
    // The Tip Edge is at Y = length/2, Z = -thickness/2.
    // We extrude a triangle along X (width).
    // Triangle vertices relative to the Tip Edge (0,0):
    // (0,0) -> Tip Edge (Bottom-Outer) - Include in cut locally
    // (0, thickness) -> Top Edge (Outer) - Include in cut?? NO.
    // Wait.
    // We want to REMOVE the material that creates the square corner.
    // That material is the triangle: (TipEdge, TopEdge, InnerBottom).
    // Vertices relative to TipEdge (L/2, -T/2):
    // 1. (0,0) - Bottom Tip.
    // 2. (0, T) - Top Tip.
    // 3. (-T, 0) - Bottom Inner.
    // 
    // Removing the triangle defined by these 3 points removes the entire end block except the top-inner triangle?
    // NO.
    // The block we HAVE is the rectangle.
    // We want to KEEP the top-inner triangle.
    // We want to REMOVE the bottom-outer triangle.
    // Vertices of removed triangle:
    // (0,0) - Bottom Tip.
    // (0, T) - Top Tip.
    // (-T, 0) - Bottom Inner.
    // The slope line is TopTip <-> BottomInner.
    // Everything to the "right" (towards BottomTip) is removed.
    // Yes.

    translate([-(total_width + 1) / 2, length / 2, -thickness / 2])
      rotate([90, 0, 90])
        linear_extrude(total_width + 1)
          polygon([[0, 0], [0, thickness], [-thickness, 0]]);
  }
}
