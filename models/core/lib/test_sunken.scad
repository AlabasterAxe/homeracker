include <connector.scad>

// Test Case:
// - Configuration: 3 Dimensions, 4 Directions (+X, +Y, +Z, -Z).
// - Foot at -Z.
// - Sink +Z.

connector(dimensions=3, directions=4, is_foot=true, sunken_direction="-z");
