// HomeRacker - Core Connector
//
// This model is part of the HomeRacker - Core system.
//
// MIT License
// Copyright (c) 2025 Patrick Pötz
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// TODO: 1D1W is completely useless if not a pull-through connector. we should account for that.

include <BOSL2/std.scad>
include <constants.scad>

connector_outer_side_length = BASE_UNIT + BASE_STRENGTH * 2 + TOLERANCE;
arm_side_length_inner = connector_outer_side_length - BASE_STRENGTH * 2;

core_to_arm_translation = BASE_UNIT;

// Connector arm configuration lookup table
// Format: [dimensions][ways-1] = [+z, -z, +x, -x, +y, -y]
// Axis priority: Z → X → Y
// Direction priority: + before -
CONNECTOR_CONFIGS = [
  // 1D configurations (1-2 ways, Z-axis only)
  [
    [true, false, false, false, false, false], // 1D1W: +Z
    [true, true, false, false, false, false], // 1D2W: +Z, -Z
  ],
  // 2D configurations (2-4 ways, Z and X axes)
  [
    [true, false, true, false, false, false], // 2D2W: +Z, +X
    [true, true, true, false, false, false], // 2D3W: +Z, -Z, +X
    [true, true, true, true, false, false], // 2D4W: +Z, -Z, +X, -X
  ],
  // 3D configurations (3-6 ways, all three axes)
  [
    [true, false, true, false, true, false], // 3D3W: +Z, +X, +Y
    [true, true, true, false, true, false], // 3D4W: +Z, -Z, +X, +Y
    [true, true, true, true, true, false], // 3D5W: +Z, -Z, +X, -X, +Y
    [true, true, true, true, true, true], // 3D6W: +Z, -Z, +X, -X, +Y, -Y
  ],
];

/**
  * HomeRacker Connector Module
  *
  * Parameters:
  *   dimensions (int, default=3): Number of dimensions the connector spans.
  *       - Valid range: 1 to 3.
  *   directions (int, default=3): Number of directions the connector has.
  *       - Valid ranges:
  *         - 1 to 2 when dimensions = 1.
  *         - 2 to 4 when dimensions = 2.
  *         - 3 to 6 when dimensions = 3.
  *       - No worries, invalid dimension/direction combinations will be corrected to the min/max valid values.
  *   pull_through_axis (string, default="none"): Axis along which items can be pulled through.
  *       - Options: "none", "x", "y", "z".
  *   is_foot (bool, default=false): If true, configures the connector as a foot piece.
  *       - Note: If set to true, it overrides pull_through_axis when set to "z".
  *   optimal_orientation (bool, default=false): If true, rotates the connector for optimal print orientation.
  *
  *   sunken_direction (string, default="none"): 
  *       Direction to sink (recess).
  *       Valid values: "none", "+z", "-z", "+x", "-x", "+y", "-y".
  *
  * Produces:
  *   A connector piece for the HomeRacker modular rack system.
  *   The connector can span multiple dimensions and directions, with optional pull-through functionality.
  *
  * Usage:
  *   connector_piece = homeRackerConnector(dimensions=2, directions=4, pull_through_axis="y", is_foot=false);
  */

module connector(dimensions = 3, directions = 6, pull_through_axis = "none", is_foot = false, optimal_orientation = false, sunken_direction = "none") {

  // Validate and correct dimensions (1-3)
  valid_dimensions = max(1, min(3, dimensions));

  // Determine valid direction range based on dimensions
  min_directions = valid_dimensions == 1 ? 1 : valid_dimensions;
  max_directions = valid_dimensions * 2;

  // Validate and correct directions
  valid_directions = max(min_directions, min(max_directions, directions));

  // Get arm configuration from lookup table
  // Array index: [dimensions-1][directions-min_directions]
  config = CONNECTOR_CONFIGS[valid_dimensions - 1][valid_directions - min_directions];

  // for nicer optics, mirror the whole connector along the xy plane when it's a foot

  // Subtract Pull-Through Hole if applicable
  difference() {
    // Combine connector with Printing interfaces
    union() {
      if (valid_directions > 4) {
        // 5-6 way connectors: tetrahedron at chamfered corner
        rotation_1 = optimal_orientation ? [-(180 - acos(1 / sqrt(3))), 0, 0] : [0, 0, 0];
        rotation_2 = optimal_orientation ? [0, 0, 45] : [0, 0, 0];
        rotate(rotation_1) rotate(rotation_2)
            difference() {
              union() {
                connector_raw(config, is_foot, sunken_direction);
                print_interface_3d();
              }
              pull_through_hole(pull_through_axis, is_foot);
            }
      } else if (valid_directions == 4 && valid_dimensions == 2) {
        rotation = optimal_orientation ? [0, -135, 0] : [0, 0, 0];
        rotate(rotation)
          difference() {
            connector_raw(config, is_foot, sunken_direction);
            pull_through_hole(pull_through_axis, is_foot);
          }
      } else {
        // All other cases: simple flat base with chamfered edge
        rotation = optimal_orientation ? [90, -45, 0] : [0, 0, 0];
        rotate(rotation)
          difference() {
            intersection() {
              connector_raw(config, is_foot, sunken_direction);
              print_interface_base();
            }
            pull_through_hole(pull_through_axis, is_foot);
          }
      }
    }
  }
}

module connector_raw(config, is_foot = false, sunken_direction = "none") {

  // Map sunken_direction string to index
  sunken_index =
    sunken_direction == "+z" ? 0
    : sunken_direction == "-z" ? 1
    : sunken_direction == "+x" ? 2
    : sunken_direction == "-x" ? 3
    : sunken_direction == "+y" ? 4
    : sunken_direction == "-y" ? 5
    : -1;

  // Create boolean array for easy lookup
  sunken = [
    sunken_index == 0,
    sunken_index == 1,
    sunken_index == 2,
    sunken_index == 3,
    sunken_index == 4,
    sunken_index == 5,
  ];

  // Calculate sunken translation (centering the arm opening on the core face)
  // The arm inner length is connector_outer_side_length - BASE_STRENGTH*2
  // We want the inner opening to start at the face of the core.
  // The core face is at connector_outer_side_length/2 from center.
  // The arm is normally centered at core_to_arm_translation = connector_outer_side_length (approx, it's BASE_UNIT actually).
  // Let's look at the standard positioning:
  // translate([0, 0, core_to_arm_translation]) connectorArmInner()
  // core_to_arm_translation = BASE_UNIT

  // Actually, checking constants and logic:
  // connector_outer_side_length = BASE_UNIT + BASE_STRENGTH*2 + TOLERANCE
  // core_to_arm_translation = BASE_UNIT

  // When sunken, we want the arm to be inside. 
  // The arm module creates a block of size arm_dimensions_outer or inner.
  // We effectively want to move it "inwards" by BASE_UNIT.
  // So translation should be 0 instead of core_to_arm_translation?
  // Let's verify. core_to_arm_translation is BASE_UNIT.
  // If we translate by 0, the arm is centered at origin. That's too far in.

  // We want the "top" of the arm to be flush with the core face?
  // No, we want the "opening" of the arm to be flush with the core face.
  // The core face is at +/- connector_outer_side_length/2.

  // Let's assume for now, sunken means "don't translate out".
  // The standard translation is `core_to_arm_translation` which is `BASE_UNIT`.
  // If we want it sunk, we calculate the position so it is fully inside? 
  // Or is it that the "Connector" hole is recessed?

  // "recesses into the middle of the cube"
  // "sink one of the axes into the body"

  // If we look at `connectorArmInner`:
  // cuboid(arm_dimensions_inner, ... edges=BOTTOM)
  // arm_dimensions_inner Z is BASE_UNIT.
  // It is a cuboid of height BASE_UNIT.
  // When translated by `core_to_arm_translation` (BASE_UNIT), its bottom is at BASE_UNIT/2? 
  // No, `cuboid` centers unless anchor is set.
  // default anchor is center.
  // So it spans z from -BASE_UNIT/2 to +BASE_UNIT/2 relative to its center.
  // Centered at BASE_UNIT -> spans [BASE_UNIT/2, 3*BASE_UNIT/2].

  // `connectorCore` is `connector_outer_side_length` cube. centered at 0.
  // Extent is +/- `connector_outer_side_length`/2.
  // `connector_outer_side_length` ≈ BASE_UNIT + small stuff. (25mm + 4mm + tol) ≈ 29mm.
  // BASE_UNIT = 25mm.
  // Core extend is +/- 14.5mm.
  // Arm Inner (green) at BASE_UNIT (25mm) -> spans [12.5, 37.5].
  // This seems to be sticking OUT of the core.

  // To SINK it, we want it INSIDE the core.
  // So we want the void to be inside the blue box.
  // We need to move it in by `BASE_UNIT`?
  // If we position it at 0, it spans [-12.5, 12.5]. This is inside the +/- 14.5mm core.
  // ONE problem: The "arm" usually adds an EXTRA block (yellow) on the outside.
  // If sunken, we probably DON'T want the yellow block (connectorArmOuter), we just want the HOLE (connectorArmInner) inside the core.

  difference() {
    // Core + Outer Arms
    union() {
      // Create connector core
      connectorCore();

      // Place arms based on configuration
      // Order: +Z, -Z, +X, -X, +Y, -Y
      // Only place Outer Arm if NOT sunken
      if (config[0] && !sunken[0]) translate([0, 0, core_to_arm_translation]) connectorArmOuter(is_foot); // +Z
      if (config[1] && !sunken[1]) translate([0, 0, -core_to_arm_translation]) rotate([180, 0, 0]) connectorArmOuter(); // -Z
      if (config[2] && !sunken[2]) translate([core_to_arm_translation, 0, 0]) rotate([0, 90, 0]) connectorArmOuter(); // +X
      if (config[3] && !sunken[3]) translate([-core_to_arm_translation, 0, 0]) rotate([0, -90, 0]) connectorArmOuter(); // -X
      if (config[4] && !sunken[4]) translate([0, core_to_arm_translation, 0]) rotate([-90, 0, 0]) connectorArmOuter(); // +Y
      if (config[5] && !sunken[5]) translate([0, -core_to_arm_translation, 0]) rotate([90, 0, 0]) connectorArmOuter(); // -Y
    }
    // Subract Inner Arms
    // Order: +Z, -Z, +X, -X, +Y, -Y
    // If sunken, translate to 0 (center of core). If not sunken, translate to core_to_arm_translation.

    // NOTE: We need to check if 0 is the correct "sunken" position.
    // As analyzed, 0 puts the 25mm cutout centered at origin.
    // The core is ~29mm.
    // So the cutout is fully contained within the core.
    // The "foot" usually needs the hole to be accessible.
    // If it is at 0, is it accessible?
    // The core face is at ~14.5.
    // The cutout ends at 12.5.
    // There is a 2mm wall closing it off!
    // We need to move it so the "top" of the cutout breaks the surface.
    // Cutout Z range: [-12.5, 12.5] (length 25).
    // We want the TOP (positive Z in local coords) to be at 'connector_outer_side_length/2'.
    // Target Top = connector_outer_side_length/2.
    // Current Top (at pos 0) = BASE_UNIT/2.
    // Shift needed = (connector_outer_side_length/2) - (BASE_UNIT/2).
    // shift = (connector_outer_side_length - BASE_UNIT) / 2.

    // For Sunken Arms:
    // 1. Center alignment: The pin holes must be at origin (0,0,0).
    // 2. Depth calculation (based on user specs & geometry):
    //    - Rim (Face) is at: connector_outer_side_length / 2
    //    - Bottom needs to be at: -(BASE_UNIT/2 + TOLERANCE/2)
    //      (This ensures the inserted support tip, which extends ~7.5mm past hole center, fits).

    sunken_bottom = -(BASE_UNIT / 2 + TOLERANCE / 2);
    sunken_rim = connector_outer_side_length / 2 + 0.01; // +0.01 for clean surface cut
    sunken_len = sunken_rim - sunken_bottom;
    sunken_offset = (sunken_rim + sunken_bottom) / 2;
    sunken_scale = sunken_len / BASE_UNIT;

    if (config[0] && !is_foot) { if (sunken[0]) translate([0, 0, sunken_offset]) scale([1, 1, sunken_scale]) connectorArmInner(); else translate([0, 0, core_to_arm_translation]) connectorArmInner(); } // +Z
    if (config[1]) { if (sunken[1]) translate([0, 0, -sunken_offset]) rotate([180, 0, 0]) scale([1, 1, sunken_scale]) connectorArmInner(); else translate([0, 0, -core_to_arm_translation]) rotate([180, 0, 0]) connectorArmInner(); } // -Z
    if (config[2]) { if (sunken[2]) translate([sunken_offset, 0, 0]) rotate([0, 90, 0]) scale([1, 1, sunken_scale]) connectorArmInner(); else translate([core_to_arm_translation, 0, 0]) rotate([0, 90, 0]) connectorArmInner(); } // +X
    if (config[3]) { if (sunken[3]) translate([-sunken_offset, 0, 0]) rotate([0, -90, 0]) scale([1, 1, sunken_scale]) connectorArmInner(); else translate([-core_to_arm_translation, 0, 0]) rotate([0, -90, 0]) connectorArmInner(); } // -X
    if (config[4]) { if (sunken[4]) translate([0, sunken_offset, 0]) rotate([-90, 0, 0]) scale([1, 1, sunken_scale]) connectorArmInner(); else translate([0, core_to_arm_translation, 0]) rotate([-90, 0, 0]) connectorArmInner(); } // +Y
    if (config[5]) { if (sunken[5]) translate([0, -sunken_offset, 0]) rotate([90, 0, 0]) scale([1, 1, sunken_scale]) connectorArmInner(); else translate([0, -core_to_arm_translation, 0]) rotate([90, 0, 0]) connectorArmInner(); } // -Y

    // Add pin holes for sunken arm
    if (sunken_index != -1) {
      pin_hole_cross(sunken_direction);
    }
  }
}

module pin_hole_cross(direction) {
  // Direction is the axis of the sunken arm.
  // Holes go in the perpendicular axes.
  // e.g. if sunken along Z, holes along X and Y.

  len = connector_outer_side_length; // Exact length to ensure flare matches surface

  color(HR_RED) {
    if (direction == "+z" || direction == "-z") {
      rotate([0, 90, 0]) cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, len], chamfer=-LOCKPIN_HOLE_CHAMFER); // X
      rotate([90, 0, 0]) cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, len], chamfer=-LOCKPIN_HOLE_CHAMFER); // Y
    } else if (direction == "+x" || direction == "-x") {
      rotate([90, 0, 0]) cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, len], chamfer=-LOCKPIN_HOLE_CHAMFER); // Y
      cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, len], chamfer=-LOCKPIN_HOLE_CHAMFER); // Z
    } else if (direction == "+y" || direction == "-y") {
      rotate([0, 90, 0]) cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, len], chamfer=-LOCKPIN_HOLE_CHAMFER); // X
      cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, len], chamfer=-LOCKPIN_HOLE_CHAMFER); // Z
    }
  }
}

/** * Connector Arm Modules
  *
  * Produces a single arm of the connector to define the outer geometry.
  * It also creates the lock pin holes.
  */
module connectorArmOuter(is_foot = false) {

  arm_dimensions_outer = [connector_outer_side_length, connector_outer_side_length, BASE_UNIT];
  arm_side_length_inner = connector_outer_side_length - BASE_STRENGTH * 2;
  arm_dimensions_inner = [arm_side_length_inner, arm_side_length_inner, BASE_UNIT];

  // outer cuboid
  difference() {
    color(HR_YELLOW) cuboid(arm_dimensions_outer, chamfer=BASE_CHAMFER, except=BOTTOM);
    if (!is_foot) {
      color(HR_RED) rotate([90, 0, 0]) cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, connector_outer_side_length], chamfer=-LOCKPIN_HOLE_CHAMFER);
      color(HR_RED) rotate([90, 0, 90]) cuboid([LOCKPIN_HOLE_SIDE_LENGTH, LOCKPIN_HOLE_SIDE_LENGTH, connector_outer_side_length], chamfer=-LOCKPIN_HOLE_CHAMFER);
    }
  }
}

/** * Connector Arm Inner Module
  *
  * Produces a single arm of the connector to define the inner cutout.
  * When you difference() this with the outer arm, you get the hollow arm structure.
  */
module connectorArmInner() {

  arm_dimensions_inner = [arm_side_length_inner, arm_side_length_inner, BASE_UNIT];
  color(HR_GREEN)
    cuboid(arm_dimensions_inner, chamfer=BASE_CHAMFER, edges=BOTTOM);
}

/** * Connector Core Module
  *
  * Produces the core block of the connector.
  * Around it, the arms are attached.
  */
module connectorCore() {
  core_dimensions = [connector_outer_side_length, connector_outer_side_length, connector_outer_side_length];
  color(HR_BLUE)
    cuboid(core_dimensions, chamfer=BASE_CHAMFER);
}

/** * 3D Print Interface Module
  * Produces a tetrahedral shape that fits into the chamfered corner of the connector.
  * Used to provide enough surface area for 3D printing when the connector has multiple arms (5 or 6)
  */
module print_interface_3d() {
  // Create a tetrahedron by defining 4 vertices
  // Right angle at origin, edges along +X, +Y, +Z axes
  side_length = BASE_UNIT - TOLERANCE / 2 - BASE_STRENGTH / 2;
  // Position tetrahedron at chamfered corner: from center to outer edge, minus chamfer offset
  translation = connector_outer_side_length / 2 - BASE_CHAMFER;
  points = [
    [0, 0, 0], // Origin (right angle corner)
    [side_length, 0, 0], // Along X axis
    [0, side_length, 0], // Along Y axis
    [0, 0, side_length], // Top point (apex)
  ];

  // Define the 4 triangular faces
  faces = [
    [0, 2, 1], // Bottom face (XY plane triangle)
    [0, 1, 3], // XZ plane face
    [0, 3, 2], // YZ plane face
    [1, 2, 3], // Hypotenuse face (slanted)
  ];

  color(HR_CHARCOAL)
    translate([translation, translation, translation])
      polyhedron(points=points, faces=faces, convexity=2);
}

/** * Base Print Interface Module
  * Produces a simple flat base with double-chamfered edge for print bed adhesion.
  * Used for most connector configurations (1-3 way connectors and 2D3W).
  */
module print_interface_base() {
  base_height = BASE_UNIT * 3;
  side_length = connector_outer_side_length * 2;
  chamfer = BASE_CHAMFER * 3;

  // Position the base below the connector core
  //translate([0, 0, -base_height/2 - connector_outer_side_length/2])
  color(HR_CHARCOAL)
    // Main base cuboid with standard chamfer
    translate([connector_outer_side_length / 2, connector_outer_side_length / 2, 0])
      cuboid([side_length, side_length, base_height], chamfer=chamfer, edges=LEFT + FRONT);
}

/* Pull-Through Hole Module
  *
  * Produces a pull-through hole along the specified axis.
  */
module pull_through_hole(axis = "none", is_foot = false) {
  // Determine hole orientation and dimensions based on axis
  hole_length = BASE_UNIT * 3;
  hole_dimensions = [hole_length, arm_side_length_inner, arm_side_length_inner];

  color(HR_WHITE) if (axis == "y") {
    rotate([0, 0, 90])
      cuboid(hole_dimensions);
  } else if (axis == "z" && !is_foot) {
    rotate([0, -90, 0])
      cuboid(hole_dimensions);
  } else if (axis == "x") {
    cuboid(hole_dimensions);
  }
}
