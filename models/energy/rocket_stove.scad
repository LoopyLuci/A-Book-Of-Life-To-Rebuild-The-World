// Rocket Stove — Parametric Model
// Entry: pnk:01HZX0K8J9Q7R3VY6T2M4B8N40/energy/fire-combustion
// License: MIT

feed_w       = 100;   // mm
feed_h       = 100;   // mm
feed_len     = 300;   // mm
riser_h      = 400;   // mm
riser_w      = 100;   // mm
wall         = 8;     // mm
insulation   = 30;    // mm

module shell() {
    difference() {
        // Outer barrel
        cylinder(h=riser_h + feed_h, d=riser_w + 2*(wall + insulation), $fn=64);
        // Inner riser
        translate([0, 0, feed_h])
            cylinder(h=riser_h, d=riser_w, $fn=64);
        // Feed tube opening
        translate([-feed_w / 2 - wall, -feed_w / 2, -1])
            cube([feed_w + wall * 2, feed_w + wall * 2, feed_h + 1]);
        translate([-feed_w / 2, -feed_w / 2 - wall, 0])
            cube([feed_w, feed_w + wall, feed_h]);
    }
}

module feed_tube() {
    difference() {
        cube([feed_w + 2*wall, feed_w + 2*wall, feed_h + 2*wall]);
        translate([wall, wall, wall])
            cube([feed_w, feed_w, feed_h + wall]);
    }
}

translate([0, 0, 0]) feed_tube();
translate([feed_w / 2 + wall, feed_w / 2 + wall, feed_h / 2]) shell();
