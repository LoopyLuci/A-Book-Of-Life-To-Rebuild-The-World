// Bow Drill — Parametric Model
// Entry: pnk:01HZX0K8J9Q7R3VY6T2M4B8N1P/survival/making-fire
// License: MIT
//
// Adjust dimensions to local materials.

spindle_len = 200;   // mm
spindle_dia = 20;    // mm
board_width = 120;   // mm
board_thick = 20;    // mm
bow_len     = 500;   // mm
bow_curve   = 40;    // mm

module spindle() {
    cylinder(h=spindle_len, d=spindle_dia, $fn=64);
    translate([0, 0, spindle_len])
        sphere(d=spindle_dia * 0.8, $fn=32);
    translate([0, 0, -spindle_dia * 0.4])
        sphere(d=spindle_dia * 0.8, $fn=32);
}

module fireboard() {
    difference() {
        cube([board_width, board_width * 0.6, board_thick], center=true);
        // Depression for spindle
        translate([0, 0, board_thick / 2])
            cylinder(h=board_thick * 0.3, d=spindle_dia * 1.1, $fn=48);
        // Notch for ember
        translate([board_width * 0.3, 0, 0])
            rotate([0, 90, 0])
                cylinder(h=board_width, d=spindle_dia * 0.5, $fn=32);
    }
}

module bow() {
    // Bow as a curved rod
    translate([-bow_len / 2, 0, 0])
        for (i = [0 : bow_len / 10 : bow_len])
            hull() {
                translate([i, sin(i / bow_len * 180) * bow_curve, 0])
                    sphere(d=12, $fn=16);
                translate([i + bow_len / 10, sin((i + bow_len / 10) / bow_len * 180) * bow_curve, 0])
                    sphere(d=12, $fn=16);
            }
}

module socket() {
    difference() {
        cylinder(h=40, d=spindle_dia * 1.5, $fn=48);
        translate([0, 0, 10])
            cylinder(h=30, d=spindle_dia * 0.9, $fn=48);
    }
}

// Layout
translate([-spindle_len * 0.6, 0, 0]) spindle();
translate([spindle_len * 0.3, 0, 0]) fireboard();
translate([0, board_width, 0]) bow();
translate([spindle_len * 0.3, -board_width, 0]) socket();
