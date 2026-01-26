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
 */
module panel(rows = 1, cols = 1, tabs = [true, true, true, true], lacing = [0, 0, 0, 0]) {

  // Calculate dimensions
  panel_width = (cols + 1) * BASE_UNIT - CONNECTOR_SIDE_LENGTH - TOLERANCE;
  panel_height = (rows + 1) * BASE_UNIT - CONNECTOR_SIDE_LENGTH - TOLERANCE;
  panel_thickness = BASE_STRENGTH;

  // Dist from Support Axis to Panel Edge
  dist_to_hole = (CONNECTOR_SIDE_LENGTH + TOLERANCE) / 2;

  // Tab Overlap Logic (into Panel)
  overlap = BASE_CHAMFER;

  // Extension Logic
  extension = dist_to_hole + CONNECTOR_SIDE_LENGTH / 2;

  real_tab_length = extension + overlap;

  // Translation Offset
  shift_y = (extension - overlap) / 2;
  shift_y_female = -(shift_y + overlap);

  n_tabs_x = max(0, cols - 2);
  n_tabs_y = max(0, rows - 2);

  color(HR_CHARCOAL)
    union() {
      // Main Panel Body
      difference() {
          cuboid([panel_width, panel_height, panel_thickness], chamfer=BASE_CHAMFER / 2, edges=TOP);
          
          // Gap Cutters for Lacing (Female Slots)
          // Subtracts the Reverse Miter form from the panel edge at gap positions.
          if (tabs[0] && n_tabs_x > 0 && lacing[0] > 0) {
            translate([0, panel_height/2 + shift_y_female, 0]) 
                panel_tab_side_cutter(n_tabs_x, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing[0]);
          }
          if (tabs[1] && n_tabs_x > 0 && lacing[1] > 0) {
            translate([0, -(panel_height/2 + shift_y_female), 0]) 
                rotate([0,0,180])
                panel_tab_side_cutter(n_tabs_x, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing[1]);
          }
          if (tabs[2] && n_tabs_y > 0 && lacing[2] > 0) {
            translate([-(panel_width/2 + shift_y_female), 0, 0]) 
                rotate([0,0,90])
                panel_tab_side_cutter(n_tabs_y, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing[2]);
          }
          if (tabs[3] && n_tabs_y > 0 && lacing[3] > 0) {
            translate([panel_width/2 + shift_y_female, 0, 0]) 
                rotate([0,0,-90])
                panel_tab_side_cutter(n_tabs_y, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing[3]);
          }
      }

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
  total_width = n_tabs * BASE_UNIT - TOLERANCE;
  hole_pos_y = -length / 2 + overlap + dist_to_hole;

  difference() {
    cuboid([total_width, length, thickness], chamfer=BASE_CHAMFER / 2, edges=TOP, except=FRONT);

    xcopies(spacing=BASE_UNIT, n=n_tabs)
      translate([0, hole_pos_y, 0])
        cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, thickness + 1], chamfer=-LOCKPIN_HOLE_CHAMFER * 1.5);

    panel_miter_cutter(total_width, length, thickness);
  }
}

module panel_tab_laced(n_tabs, length, thickness, dist_to_hole, overlap, mode) {
  spacing = BASE_UNIT;
  tab_width = BASE_UNIT - TOLERANCE;

  for (i = [0:n_tabs - 1]) {
    keep = (mode == 1 && (i % 2 == 0)) || (mode == 2 && (i % 2 == 1));

    if (keep) {
      pos_x = (i - (n_tabs - 1) / 2) * spacing;
      translate([pos_x, 0, 0])
        panel_single_tab(tab_width, length, thickness, dist_to_hole, overlap);
    }
  }
}

module panel_tab_side_cutter(n_tabs, length, thickness, dist_to_hole, overlap, mode) {
    // Generates the cutters for the Gaps.
    // Cutters are shapes that are subtracted from the panel.
    // They should remove the material where the "Opposing Tab" enters.
    // Opposing Tab has `panel_miter_cutter` applied (Male Miter).
    // Female Slot should have Reverse Miter.
    // Note: The cutter position logic is identical to tab placement, but for `!keep`.
    
    spacing = BASE_UNIT;
    tab_width = BASE_UNIT - TOLERANCE; // Or just BASE_UNIT for clearance? User assumes perfect fit.

    for (i = [0:n_tabs - 1]) {
        keep = (mode == 1 && (i % 2 == 0)) || (mode == 2 && (i % 2 == 1));

        if (!keep) {
            pos_x = (i - (n_tabs - 1) / 2) * spacing;
            translate([pos_x, 0, 0]) 
              rotate([0, 180, 0])
                panel_miter_cutter(tab_width, length, thickness);
        }
    }
}

module panel_single_tab(width, length, thickness, dist_to_hole, overlap) {
  hole_pos_y = -length / 2 + overlap + dist_to_hole;

  difference() {
    cuboid([width, length, thickness], chamfer=BASE_CHAMFER / 2, edges=TOP, except=FRONT);

    translate([0, hole_pos_y, 0])
      cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, thickness + 1], chamfer=-LOCKPIN_HOLE_CHAMFER * 1.5);

    panel_miter_cutter(width, length, thickness);
  }
}

module panel_miter_cutter(width, length, thickness) {
  // Shared Miter Cut Logic (Male)
  // Removes triangular prism from Bottom-Tip.
  // Vertices relative to Tip Edge (L/2, -T/2):
  // 1. (0,0) - Bottom Tip.
  // 2. (0, T) - Top Tip.
  // 3. (-T, 0) - Bottom Inner.
  
  translate([-(width + 1) / 2, length / 2, -thickness / 2])
    rotate([90, 0, 90])
      linear_extrude(width + 1)
        polygon([[0, 0], [0, thickness], [-thickness, 0]]);
}
