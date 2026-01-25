// Test assembly for Panel Lacing
//
// Visualizes two 5x5 panels side-by-side using Lacing.
// Shared support in the middle.
// Corrected Orientations (Flat on XY Plane).

include <BOSL2/std.scad>
include <../main.scad>
include <../lib/constants.scad>

// Configuration
S_LEN = 5; 

// Spacing
MODULE_SPACING = (S_LEN + 1) * BASE_UNIT;

module assembly() {
    
    // --- CONNECTORS ---
    
    // 1. Bottom Row (Y=0)
    // BL Corner (0,0): Needs +X, +Y.
    // Base 2D2W: +Z, +X.
    // Rotate [-90, 0, 0] -> +Y, +X.
    translate([0, 0, 0]) 
        rotate([-90, 0, 0])
        connector(dimensions=2, directions=2); 

    // BM (Middle) (Spacing, 0): Needs +X, -X, +Y. (T-Junction)
    // Base 2D3W: +Z, -Z, +X.
    // Rotate [-90, -90, 0] helps?
    // Let's try: Rot Y -90 -> (+X, -X, +Z). Rot X -90 -> (+X, -X, +Y).
    translate([MODULE_SPACING, 0, 0]) 
        rotate([90, 0, 90])
        connector(dimensions=2, directions=3); 

    // BR Corner (2*Spacing, 0): Needs -X, +Y.
    // Base 2D2W: +Z, +X.
    // Rotate [-90, 0, 180]? 
    // Base->Rot X -90: (+Y, +X). Rot Z 180: (+Y, -X). Correct.
    translate([MODULE_SPACING*2, 0, 0]) 
        rotate([90, 0, 180])
        connector(dimensions=2, directions=2); 


    // 2. Top Row (Y=Spacing)
    // TL Corner (0, Spacing): Needs +X, -Y.
    // Base 2D2W: +Z, +X.
    // Rot X -90 -> (+Y, +X). Rot Z -90 -> (-X, +Y)? No.
    // Needs +X, -Y.
    // Rot X 90 -> (-Y, +X). Correct.
    translate([0, MODULE_SPACING, 0]) 
        rotate([90, 0, 0])
        connector(dimensions=2, directions=2); 

    // TM (Middle) (Spacing, Spacing): Needs +X, -X, -Y.
    // Base 2D3W: +Z, -Z, +X.
    // Rot Y -90 -> (+X, -X, +Z). Rot X 90 -> (+X, -X, -Y).
    translate([MODULE_SPACING, MODULE_SPACING, 0]) 
        rotate([90, 0, -90])
        connector(dimensions=2, directions=3); 

    // TR Corner (2*Spacing, Spacing): Needs -X, -Y.
    // Base 2D2W: +Z, +X.
    // Rot X 90 -> (-Y, +X). Rot Z 180 -> (-Y, -X).
    translate([MODULE_SPACING*2, MODULE_SPACING, 0]) 
        rotate([90, 0, -90])
        connector(dimensions=2, directions=2); 


    // --- SUPPORTS ---
    
    // Left Frame Vertical (Left)
    translate([0, MODULE_SPACING/2, 0]) 
        support(units=S_LEN, x_holes=true);
        
    // Left Frame Horizontal (Bottom)
    translate([MODULE_SPACING/2, 0, 0]) 
        rotate([0, 0, 90]) 
        support(units=S_LEN, x_holes=true);

    // Left Frame Horizontal (Top)
    translate([MODULE_SPACING/2, MODULE_SPACING, 0]) 
        rotate([0, 0, 90]) 
        support(units=S_LEN, x_holes=true);

    // Center Vertical (Shared)
    translate([MODULE_SPACING, MODULE_SPACING/2, 0]) 
        support(units=S_LEN, x_holes=true);

    // Right Frame Horizontal (Bottom)
    translate([MODULE_SPACING*1.5, 0, 0]) 
        rotate([0, 0, 90]) 
        support(units=S_LEN, x_holes=true);

    // Right Frame Horizontal (Top)
    translate([MODULE_SPACING*1.5, MODULE_SPACING, 0]) 
        rotate([0, 0, 90]) 
        support(units=S_LEN, x_holes=true);

    // Right Frame Vertical (Right)
    translate([MODULE_SPACING*2, MODULE_SPACING/2, 0]) 
        support(units=S_LEN, x_holes=true);


    // --- PANELS ---
    
    // Left Panel
    // Sits in [0,0] to [Spacing, Spacing].
    // Center is [Spacing/2, Spacing/2].
    // Z-Height: Panel sits flush with "Top" of support.
    // Support Top is Z = +7.5mm. Panel Thickness = 2mm.
    // Panel Center Z = 8.5mm.
    
    translate([MODULE_SPACING/2, MODULE_SPACING/2, BASE_UNIT/2 + BASE_STRENGTH/2])
        color("purple")
        panel(rows=S_LEN, cols=S_LEN, 
              tabs=[true, true, true, true],
              lacing=[0, 0, 0, 1]); // Right side (Side 3) laced Odd (1)


    // Right Panel
    // Sits in [Spacing, 0] to [2*Spacing, Spacing].
    // Center is [Spacing*1.5, Spacing/2].
    
    translate([MODULE_SPACING*1.5, MODULE_SPACING/2, BASE_UNIT/2 + BASE_STRENGTH/2])
        color("orange")
        panel(rows=S_LEN, cols=S_LEN, 
              tabs=[true, true, true, true],
              lacing=[0, 0, 2, 0]); // Left side (Side 2) laced Even (2)
              
}

assembly();
