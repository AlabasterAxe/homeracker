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
 *   edge_styles (vector of 4 strings, default=["tab",...]):
 *       Style for each edge: [Top, Bottom, Left, Right]
 *       Values: "none", "tab", "laced_odd", "laced_even"
 *   edge_holes (vector of 4 bools, default=[true, true, true, true]):
 *       Whether to include lock pin holes for each edge.
 *   edge_cutouts (vector of 4 pairs of bools):
 *       [Top[Start,End], Bottom[Start,End], Left[Start,End], Right[Start,End]]
 *       If true, leaves space (1 unit) for corner connectors.
 *       If false, extends tab strip into the corner (Full Width).
 */
module panel(
    rows = 1, 
    cols = 1, 
    edge_styles = ["tab", "tab", "tab", "tab"], 
    edge_holes = [true, true, true, true],
    edge_cutouts = [[true, true], [true, true], [true, true], [true, true]] // [Start, End] per edge
) {

    // Calculate dimensions
    // The main panel body fits between the connector centers.
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

    // Translation Offset for Tabs vs Body
    shift_y = (extension - overlap) / 2;
    shift_y_female = -(shift_y + overlap);

    color(HR_CHARCOAL)
    union() {
        // Main Panel Body
        difference() {
            cuboid([panel_width, panel_height, panel_thickness], chamfer=BASE_CHAMFER / 2, edges=TOP);
            
            // Gap Cutters for Lacing (Female Slots)
            for (i = [0:3]) {
                style = edge_styles[i];
                if (style == "laced_odd" || style == "laced_even") {
                    
                    is_vertical = (i >= 2);
                    n_units = is_vertical ? rows : cols;
                    
                    cut_start = edge_cutouts[i][0];
                    cut_end = edge_cutouts[i][1];
                    n_tabs = max(0, n_units - (cut_start?1:0) - (cut_end?1:0));
                    
                    start_index_offset = (cut_start?1:0);
                    
                    center_shift_units = ((cut_start?1:0) - (cut_end?1:0)) * 0.5;
                    center_shift_mm = center_shift_units * BASE_UNIT;
                    
                    lacing_mode = (style == "laced_odd") ? 1 : 2;

                    if (n_tabs > 0) {
                        if (i == 0) { // Top
                            color("lime")
                            translate([center_shift_mm, panel_height/2 + shift_y_female, 0])
                                panel_tab_side_cutter(n_tabs, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing_mode, start_index_offset);
                        } else if (i == 1) { // Bottom
                            color("lime")
                            translate([center_shift_mm, -(panel_height/2 + shift_y_female), 0])
                                rotate([0,0,180])
                                panel_tab_side_cutter(n_tabs, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing_mode, start_index_offset);
                        } else if (i == 2) { // Left
                            color("lime")
                            translate([-(panel_width/2 + shift_y_female), center_shift_mm, 0])
                                rotate([0,0,90])
                                panel_tab_side_cutter(n_tabs, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing_mode, start_index_offset);
                        } else if (i == 3) { // Right
                            color("lime")
                            translate([panel_width/2 + shift_y_female, center_shift_mm, 0])
                                rotate([0,0,-90])
                                panel_tab_side_cutter(n_tabs, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing_mode, start_index_offset);
                        }
                    }
                }
            }
        }

        // Render Tabs
        for (i = [0:3]) {
            style = edge_styles[i];
            
            if (style != "none") {
                is_vertical = (i >= 2);
                n_units = is_vertical ? rows : cols;
                cut_start = edge_cutouts[i][0];
                cut_end = edge_cutouts[i][1];
                n_tabs = max(0, n_units - (cut_start?1:0) - (cut_end?1:0));

                start_index_offset = (cut_start?1:0);
                center_shift_units = ((cut_start?1:0) - (cut_end?1:0)) * 0.5;
                center_shift_mm = center_shift_units * BASE_UNIT;

                // --- Calculate Geometry Parameters ---
                side_len_body = is_vertical ? panel_height : panel_width;
                
                // Standard Grid Calculations (The area covered if Cutouts are TRUE)
                // "Grid Limit" is the distance from center to the implied connector boundary.
                // Standard tabs (n-2) span roughly (n-2)*15.
                // But specifically, we want "flush with connector side".
                // We know standard tabs work fine.
                // If cutouts are FALSE, we want "flush with panel edge".
                
                // Limit for Standard Grid (Start/End of standard tab strip)
                grid_limit_units = max(0, n_units - 2) * BASE_UNIT; // Total width of standard block
                limit_grid_half = grid_limit_units / 2; 
                // Note: Standard strip is centered on the grid (which is usually 0).
                
                // Bounds relative to Panel Center (Grid Center)
                bound_min_std = -limit_grid_half;
                bound_max_std = limit_grid_half;

                // Bounds limited by Panel Body (Full Width)
                bound_min_full = -side_len_body / 2; // Matches panel edge (which includes tolerance)
                bound_max_full = side_len_body / 2;

                // Determine effective Start and End X
                // If cut_start is TRUE, we start at the Standard Grid limit.
                // If cut_start is FALSE, we extend to the Panel Edge limit.
                
                // Handle case where n_units < 2 (No standard tabs exist):
                // bound_min_std/max_std are 0.
                // If cut_start is true, min is 0. If false, min is -half_body.
                
                x_min = cut_start ? bound_min_std : bound_min_full;
                x_max = cut_end ? bound_max_std : bound_max_full;
                
                strip_width = x_max - x_min; // This width ALREADY accounts for tolerance (via panel_width or n*BU)
                
                // Note: n*BU usually needs -TOLERANCE.
                // grid_limit_units = (n-2)*BU. Does this include tolerance?
                // Standard tabs usually have thickness N*BU - TOL.
                // So bound_std should probably be slightly tighter?
                // Let's apply a universal tolerance reduction to the calculated strip width at render time.
                // panel_tab_strip (custom) will just use width directly.
                // If x_max = 22.5, x_min = -22.5. Width = 45.
                // We want 45 - TOL.
                // If x_max = 35.3 (Panel edge). Width = 70.6.
                // Panel edge already has TOL in it.
                // So if we are mixing bounds, does it work?
                // Yes, as long as we treat the final shape as "Solid Width".
                // I will apply -TOLERANCE inside panel_tab_strip_custom to the final width?
                // No, Panel Width already HAS tolerance. 
                // Standard Grid (N*BU) DOES NOT have tolerance subtracted yet in my `limit_grid_units`.
                // So if using Standard bounds, I should subtract TOL/2 from the bound?
                // Or just subtract TOL from final width if logic is mixed?
                // If I use Panel Width (already reduced) and Standard (not reduced), mixing might be weird.
                // Better: Standard Bound should be `(n-2)*BU - TOL`.
                // Bound Max = `((n-2)*BU - TOL)/2`. Min = -Max.
                // Then entire width is consistent.
                
                grid_width_with_tol = max(0, grid_limit_units - TOLERANCE);
                bound_max_std_tol = grid_width_with_tol / 2;
                bound_min_std_tol = -bound_max_std_tol;
                
                // Panel bounds (already has tolerance in definition)
                bound_max_full_tol = bound_max_full; 
                bound_min_full_tol = bound_min_full;

                final_x_min = cut_start ? bound_min_std_tol : bound_min_full_tol;
                final_x_max = cut_end ? bound_max_std_tol : bound_max_full_tol;
                
                final_width = max(0, final_x_max - final_x_min);
                final_center = (final_x_max + final_x_min) / 2;

                // --- Calculate Hole Parameters (Grid Aligned) ---
                // Holes must stay on the support grid (multiples of BASE_UNIT).
                // If cutouts are false, we likely have holes in the new areas.
                // Holes are generated based on "units".
                // Start index for holes:
                // Grid units: 0..n-1.
                // If cut_start is True, we skip unit 0.
                // Standard tabs (n-2) cover units 1..n-2. (Indices 1 to n-2).
                // If cut_start is False, we cover unit 0.
                // If cut_end is False, we cover unit n-1.
                
                hole_start_index = cut_start ? 1 : 0;
                hole_end_index = cut_end ? (n_units - 2) : (n_units - 1);
                
                n_holes = max(0, hole_end_index - hole_start_index + 1);
                
                // Center of the hole group relative to Panel Center:
                // Unit 0 center: -(n-1)/2 * BU.
                // Group center index: (start + end) / 2.
                // Center position = (group_center_index - (n-1)/2) * BU.
                
                avg_index = (hole_start_index + hole_end_index) / 2.0;
                hole_center_shift = (avg_index - (n_units - 1) / 2.0) * BASE_UNIT;

                // --- Render ---
                holes_enabled = edge_holes[i];
                lacing_mode = (style == "laced_odd") ? 1 : ((style == "laced_even") ? 2 : 0);
                
                // Fallback for Laced: Use standard logic for now (user interest is in Strip)
                // However, we must implement the custom strip correctly.
                
                if (style == "tab" && final_width > 0) {
                     if (i == 0) { // Top
                        translate([final_center, panel_height/2 + shift_y, 0])
                            panel_tab_strip_custom(final_width, real_tab_length, panel_thickness, dist_to_hole, overlap, holes_enabled, n_holes, hole_center_shift - final_center);
                     } else if (i == 1) { // Bottom
                         // Rotated 180. Center X is inverted. hole_shift is inverted.
                         // But we map local coordinates.
                         // We translate by center, rotate, render.
                         // Wait, if centered at X=5, rotate 180 -> X=-5. Correct.
                        translate([final_center, -(panel_height/2 + shift_y), 0])
                            rotate([0,0,180])
                            panel_tab_strip_custom(final_width, real_tab_length, panel_thickness, dist_to_hole, overlap, holes_enabled, n_holes, hole_center_shift - final_center);
                     } else if (i == 2) { // Left
                        translate([-(panel_width/2 + shift_y), final_center, 0])
                            rotate([0,0,90])
                            panel_tab_strip_custom(final_width, real_tab_length, panel_thickness, dist_to_hole, overlap, holes_enabled, n_holes, hole_center_shift - final_center);
                     } else if (i == 3) { // Right
                         translate([panel_width/2 + shift_y, final_center, 0])
                            rotate([0,0,-90])
                            panel_tab_strip_custom(final_width, real_tab_length, panel_thickness, dist_to_hole, overlap, holes_enabled, n_holes, hole_center_shift - final_center);
                     }
                } else if ((style == "laced_odd" || style == "laced_even") && n_tabs > 0) {
                     // Keep existing laced logic for now
                    if (i == 0) translate([center_shift_mm, panel_height/2 + shift_y, 0]) panel_tab_laced(n_tabs, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing_mode, holes_enabled, start_index_offset);
                    else if (i == 1) translate([center_shift_mm, -(panel_height/2 + shift_y), 0]) rotate([0,0,180]) panel_tab_laced(n_tabs, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing_mode, holes_enabled, start_index_offset);
                    else if (i == 2) translate([-(panel_width/2 + shift_y), center_shift_mm, 0]) rotate([0,0,90]) panel_tab_laced(n_tabs, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing_mode, holes_enabled, start_index_offset);
                    else if (i == 3) translate([panel_width/2 + shift_y, center_shift_mm, 0]) rotate([0,0,-90]) panel_tab_laced(n_tabs, real_tab_length, panel_thickness, dist_to_hole, overlap, lacing_mode, holes_enabled, start_index_offset);
                }
            }
        }
    }
}

module panel_tab_strip_custom(width, length, thickness, dist_to_hole, overlap, holes, n_holes, hole_relative_offset) {
  // width: Exact physical width of the tab strip.
  // hole_relative_offset: The offset of the hole group Center relative to the Tab Center (local 0).
  
  hole_pos_y = -length / 2 + overlap + dist_to_hole;

  difference() {
    cuboid([width, length, thickness], chamfer=BASE_CHAMFER / 2, edges=TOP, except=FRONT);

    if (holes && n_holes > 0) {
        translate([hole_relative_offset, 0, 0])
            xcopies(spacing=BASE_UNIT, n=n_holes)
              translate([0, hole_pos_y, 0])
                cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, thickness + 1], chamfer=-LOCKPIN_HOLE_CHAMFER * 1.5);
    }

    panel_miter_cutter(width, length, thickness);
  }
}

// Keep legacy for compatibility if needed, or remove? 
// panel_render_tab_side is replaced by direct calls except for laced.
module panel_render_tab_side(n_tabs, length, thickness, dist_to_hole, overlap, mode, holes, start_index_offset) {
    if (mode > 0) panel_tab_laced(n_tabs, length, thickness, dist_to_hole, overlap, mode, holes, start_index_offset);
    else panel_tab_strip(n_tabs, length, thickness, dist_to_hole, overlap, holes);
}

module panel_tab_strip(n_tabs, length, thickness, dist_to_hole, overlap, holes) {
    // Wrapper for legacy grid-based strip
    total_width = n_tabs * BASE_UNIT - TOLERANCE;
    panel_tab_strip_custom(total_width, length, thickness, dist_to_hole, overlap, holes, n_tabs, 0);
}

module panel_tab_laced(n_tabs, length, thickness, dist_to_hole, overlap, mode, holes, start_index_offset) {
  spacing = BASE_UNIT;
  tab_width = BASE_UNIT - TOLERANCE;

  for (i = [0:n_tabs - 1]) {
    global_index = i + start_index_offset;
    keep = (mode == 1 && (global_index % 2 != 0)) || (mode == 2 && (global_index % 2 == 0));

    if (keep) {
      pos_x = (i - (n_tabs - 1) / 2) * spacing;
      translate([pos_x, 0, 0])
        panel_single_tab(tab_width, length, thickness, dist_to_hole, overlap, holes);
    }
  }
}

module panel_tab_side_cutter(n_tabs, length, thickness, dist_to_hole, overlap, mode, start_index_offset) {
    spacing = BASE_UNIT;
    tab_width = BASE_UNIT - TOLERANCE; 

    for (i = [0:n_tabs - 1]) {
        global_index = i + start_index_offset;
        keep_tab = (mode == 1 && (global_index % 2 != 0)) || (mode == 2 && (global_index % 2 == 0));
        
        if (!keep_tab) {
            pos_x = (i - (n_tabs - 1) / 2) * spacing;
            translate([pos_x, 0, 0]) 
              rotate([0, 180, 0])
                panel_miter_cutter(tab_width, length, thickness);
        }
    }
}

module panel_single_tab(width, length, thickness, dist_to_hole, overlap, has_hole) {
  hole_pos_y = -length / 2 + overlap + dist_to_hole;

  additional_amount = 3;

  difference() {
    cuboid([width, length + additional_amount, thickness], chamfer=BASE_CHAMFER / 2, edges=TOP, except=FRONT);

    if (has_hole) {
        translate([0, hole_pos_y, 0])
          cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, thickness + 1], chamfer=-LOCKPIN_HOLE_CHAMFER * 1.5);
    }

    panel_miter_cutter(width, length + additional_amount, thickness);
  }
}

module panel_miter_cutter(width, length, thickness) {
  // Shared Miter Cut Logic
  translate([-(width + 1) / 2, length / 2, -thickness / 2])
    rotate([90, 0, 90])
      linear_extrude(width + 1)
        polygon([[0, 0], [0, thickness], [-thickness, 0]]);
}
