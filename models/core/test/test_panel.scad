// Test assembly for Panel Lacing and Styles
//
// Visualizes two 5x5 panels side-by-side using Lacing.
// Shared support in the middle.

include <BOSL2/std.scad>
include <../main.scad>
include <../lib/constants.scad>

// Configuration
S_LEN = 6; 

// Spacing
MODULE_SPACING = (S_LEN + 1) * BASE_UNIT;

module assembly() {
    
    // --- CONNECTORS & SUPPORTS (Simplified Visualization) ---
    // Center Vertical Support (Shared)
   // translate([MODULE_SPACING, MODULE_SPACING/2, 0]) 
   //     support(units=S_LEN, x_holes=true);

    // --- PANELS ---
    
    // Left Panel (Purple)
    // Right Edge: Laced Odd
    translate([MODULE_SPACING/2, MODULE_SPACING/2, BASE_UNIT/2 + BASE_STRENGTH/2])
        color("purple")
        panel(rows=S_LEN, cols=S_LEN, 
              edge_styles=["tab", "laced_odd", "tab", "tab"],
              edge_holes=[false, false, true, true],
              edge_cutouts=[[false, false], [false, false], [false, true], [false, true]]
              );

    // Right Panel (Orange)
    // Left Edge: Laced Even
   // translate([MODULE_SPACING*1.5, MODULE_SPACING/2, BASE_UNIT/2 + BASE_STRENGTH/2])
    //    color("orange")
    //    panel(rows=S_LEN, cols=S_LEN, 
    //          edge_styles=["tab", "tab", "laced_even", "tab"],
    //          edge_holes=[true, true, true, true]);
              
    // Bottom Panel (Cyan) - Connectorless / Full Width Test
    // Top Edge: Full Width Tab (No Connectors).
    // Sits below the Left Panel?
    // Let's place it separately to avoid overlap.
    translate([MODULE_SPACING/2, -MODULE_SPACING/2, BASE_UNIT/2 + BASE_STRENGTH/2])
        color("cyan")
        panel(rows=S_LEN, cols=S_LEN,
            edge_holes=[false, false, true, true],
            edge_styles=["laced_odd", "tab", "tab", "tab"], // Top tab only
            edge_cutouts=[[false, false], [false,false], [true,false], [true,false]] // Top full width
        );
}

assembly();