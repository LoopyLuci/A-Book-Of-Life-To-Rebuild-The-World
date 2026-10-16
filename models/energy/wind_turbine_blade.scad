// Wind Turbine Blade — Parametric
// Entry: pnk:01HZX0K8J9Q7R3VY6T2M4B8N43/energy/wind-power
// License: MIT

blade_len    = 1000;  // mm
root_chord   = 120;   // mm
tip_chord    = 40;    // mm
thickness    = 12;    // mm
twist_deg    = 20;    // deg from root to tip

module blade() {
    steps = 20;
    for (i = [0 : steps - 1]) {
        t0 = i / steps;
        t1 = (i + 1) / steps;
        hull() {
            translate([0, 0, t0 * blade_len])
                rotate([0, 0, -t0 * twist_deg])
                    scale([1, 1, 1])
                        cube([root_chord * (1 - t0) + tip_chord * t0,
                              thickness,
                              1], center=true);
            translate([0, 0, t1 * blade_len])
                rotate([0, 0, -t1 * twist_deg])
                    cube([root_chord * (1 - t1) + tip_chord * t1,
                          thickness,
                          1], center=true);
        }
    }
}

blade();
