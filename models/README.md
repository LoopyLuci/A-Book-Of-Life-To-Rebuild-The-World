# 3D Models

Parametric 3D models for tools, machines, and structures described in the
knowledge base. Every model is:

- Written in OpenSCAD (plain text, versionable).
- Parametric (dimensions adjust to local materials).
- Exportable to STL/STEP for printing or CNC.
- Linked to a sidecar via `media:` entries.

## Build all models

```bash
python scripts/build_models.py
```

Output goes to `build/models/`.

## Model index

| Model | Entry | Parameters |
|-------|-------|------------|
| `bow_drill.scad` | survival/making-fire | spindle_len, board_width |
| `water_filter.scad` | survival/water-purification | bottle_dia, layer_heights |
| `rocket_stove.scad` | energy/fire-combustion | feed_w, riser_h |
| `hand_pump.scad` | construction/water-pumps | cylinder_dia, stroke |
| `pelton_wheel.scad` | energy/micro-hydro | wheel_dia, buckets |
| `wind_turbine_blade.scad` | energy/wind-power | length, twist, chord |
| `solar_cooker.scad` | energy/solar-thermal | box_w, box_h, flap_angle |
| `bee_hive.scad` | agriculture/beekeeping | frame_count, box_w |
| `printing_press.scad` | knowledge/printing-press | platen_w, platen_h |
| `loom.scad` | materials/textiles | warp_width, heddle_count |
