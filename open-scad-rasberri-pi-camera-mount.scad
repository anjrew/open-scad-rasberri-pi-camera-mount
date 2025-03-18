// Parameters for screw thread
r = 2.4;   // minor radius
d = 0.6;   // thread depth
p = 1;     // pitch
h = 6;     // height
n = 100;   // number of segments
w = 0.1;   // width of thread segment

// Parameters for triangular plate
a = 50;     // length of radial leg
t = 12;     // thickness
triangle_height = 65;
mount_length = 16;  // Base length before tilt adjustment
theta = 0;  // angle around cylinder (horizontal rotation)
tilt_angle = 30;  // Angle to tilt the screw thread downward (adjustable)

// Parameters for base
base_width = a + r + 10;  // Width (x-direction)
base_depth = t + 20;      // Depth (y-direction)
base_height = 2;          // Height of the base (z-direction)
screw_diameter = 3.2;     // Diameter for M3 screws
screw_offset = 5;         // Distance from edges for screw holes

// Module for thread segment
module thread_segment(theta) {
    z = (p / 360) * theta;
    translate([0, 0, z])
    rotate([0, 0, theta])
    translate([r + d/2, 0, 0])
    rotate([0, 90, 0])
    cylinder(h=d, r=w/2, center=true);
}

// Total rotation for thread
total_theta = 360 * (h / p);

// Module for triangular plate
module triangular_plate(a, t, theta, tilt_angle) {
    rotate([0, 0, theta]) {
        rotate([90, 0, 0])
        linear_extrude(height=t)
        polygon(points=[
            [r, 0],                           // Bottom left
            [r, triangle_height],             // Top left
            [r + a + h * sin(tilt_angle), 0]  // Bottom right, adjusted for tilt
        ]);
    }
}

// Module for screw thread
module screw_thread() {
    union() {
        cylinder(r=r, h=h);
        for (i = [0 : n-2]) {
            hull() {
                thread_segment(i * total_theta / (n-1));
                thread_segment((i+1) * total_theta / (n-1));
            }
        }
    }
}

// Module for base with mounting holes
module base_with_holes() {
    difference() {
        translate([-base_width/2, -base_depth/2, 0])
        cube([base_width, base_depth, base_height]);
        
        for (x = [-base_width/2 + screw_offset, base_width/2 - screw_offset])
        for (y = [-base_depth/2 + screw_offset, base_depth/2 - screw_offset]) {
            translate([x, y, -1])
            cylinder(h=base_height + 2, d=screw_diameter, $fn=20);
        }
    }
}

// Module for mounting exclusion (adjusted for tilt compensation)
mount_height = 55;
module mount_exclude(tilt_angle) {
    // Adjust dimensions for tilt
    adjusted_width = (r * 2 + 2) / cos(tilt_angle);  // Ensure x-width covers thread diameter + clearance
    adjusted_height = h / cos(tilt_angle) + 2;       // Ensure z-height covers thread height + buffer
    translate([-3, 0, mount_height -3])                  // Position at mount_height
    rotate([0, -tilt_angle, 0])                      // Tilt to match screw thread
    cube([adjusted_width + 10, t + 10, adjusted_height + 10]);      // Adjusted size
}

// Main assembly
union() {
    // Tilted screw thread centered in mount_exclude
    translate([-t/2 + mount_length/2 -2, 0, mount_height])  // Center in exclusion
    rotate([0, -tilt_angle, 0])                          // Tilt downward
    screw_thread();
    
    // Triangular plate with adjusted mount exclusion
    difference() {
        translate([-t/2, t/2, 0])
        triangular_plate(a, t, theta, tilt_angle);
        translate([-t/2 + mount_length/2 - (r + 1), -t/2, 0])  // Center exclusion under thread
        mount_exclude(tilt_angle);
    }
    
    // Base with mounting holes
    translate([a/2, 0, 0])
    base_with_holes();
}