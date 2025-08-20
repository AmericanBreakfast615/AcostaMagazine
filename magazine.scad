//-----------------------------------
// PARAMETERS (all in mm)
//-----------------------------------
wall_width_side_front  = 2.4;
wall_width_side        = 2.2;
wall_width_front       = 1.0;
wall_width_rear       = 1.65;
beam_width        = 22.25;
center_y          = beam_width / 2;
ridge_length      = 3.5;
ridge_width       = 11.25;
ridge_width_inner = 7.05;
feed_lips_width       = 11.25;
front_taper_start = 48;
front_width_bot   = 18;
body_length       = 60.3;
corner_r          = 1.5;

straight_len      = 70;
bend_deg          = 17;
segments_curve    = 70;
arc_len = 103;

bolt_cutout_bottom_width = 5.56;
bolt_cut_depth = 11;

// front follower guide
follower_front_w   = 1.5;   // guide width  (mm)
follower_front_d   = 1.4;   // guide depth  (mm)
front_follower_stop_h = 15;
front_follower_stop_x = 2.4;

catch_depth_y = 1.35;
catch_height_z  = 6.75;
catch_length_x = 13.2;

//-----------------------------------
// helper to centre the guide on the front
//-----------------------------------
follower_y_lo = (beam_width - follower_front_w) / 2;
follower_y_hi = follower_y_lo + follower_front_w;
x_front       = body_length - wall_width_front;          // current inner front X
x_front_inset = x_front       - follower_front_d;         // inward face of ridge

//-----------------------------------
//  FOLLOWER GUIDE PARAMS
//-----------------------------------
side_guide_d     = 1.7;   // protrusion depth  (mm)
side_guide_len   = 4.9;   // length along X    (mm)
side_guide_front = 42.2;  // forward face offset from inner rear (mm)

// precalc X positions for polygon notches
x_rear_in   = wall_width_rear;                    // inner rear wall
side_guide_x_face_fwd  = x_rear_in + side_guide_front;       // forward face of ridge
side_guide_x_face_back = side_guide_x_face_fwd - side_guide_len;        // rear face of ridge

// Y positions for the notches on each side
y_right     = wall_width_side;
side_guide_y_right_in  = y_right + side_guide_d;

y_left      = beam_width - wall_width_side;
side_guide_y_left_in   = y_left  - side_guide_d;

// make sure the guide stays behind the taper start
assert(side_guide_x_face_fwd < front_taper_start,
       "side_guide_front pushes follower guide into tapered region");

extra_bottom_len = 10;

$fn = 32;

//-----------------------------------
// 2D PROFILES
//-----------------------------------
ridge_right = (beam_width - ridge_width) / 2;
ridge_left  = ridge_right + ridge_width;
ridge_center = (ridge_right + ridge_left) / 2;

function profile_pts() = [
    [0, 0],
    [0, ridge_right],
    [-ridge_length, ridge_right],
    [-ridge_length, ridge_left],
    [0, ridge_left],
    [0, beam_width],
    [front_taper_start, beam_width],
    [body_length, front_width_bot + ((beam_width - front_width_bot) / 2)],
    [body_length, ((beam_width - front_width_bot) / 2)],
    [front_taper_start, 0]
];

function inner_pts() = [
    // back + sides (unchanged) ─────────────────────────────
    [wall_width_rear, wall_width_side],
    [wall_width_rear, ridge_center - (ridge_width_inner / 2)],
    [wall_width_rear - ridge_length, ridge_center - (ridge_width_inner / 2)],
    [wall_width_rear - ridge_length, ridge_center + (ridge_width_inner / 2)],
    [wall_width_rear, ridge_center + (ridge_width_inner / 2)],
    [wall_width_rear, beam_width - wall_width_side],

    // left follower guide
    [side_guide_x_face_back, y_left],
    // [side_guide_x_face_back, side_guide_y_left_in],
    [side_guide_x_face_fwd, side_guide_y_left_in],
    [side_guide_x_face_fwd, y_left],


    [front_taper_start, beam_width - wall_width_side_front],
    [body_length - wall_width_front,
     front_width_bot + ((beam_width - front_width_bot) / 2) - wall_width_side_front],

    // front wall with follower ridge ───────────────────────
    // upper right corner of cavity
    [x_front, follower_y_hi],
    // step inward (ridge material)
    [x_front_inset, follower_y_hi],
    // down to bottom of ridge
    [x_front_inset, follower_y_lo],
    // back out to original front wall
    [x_front, follower_y_lo],

    // lower right corner of cavity
    [x_front, ((beam_width - front_width_bot) / 2) + wall_width_side_front],

    [front_taper_start, wall_width_side_front],

    // right follower guide
    [side_guide_x_face_fwd, y_right],
    [side_guide_x_face_fwd, side_guide_y_right_in],
    [side_guide_x_face_back, y_right]

];

module mag_profile() {
    difference() {
        offset(r = corner_r)
            offset(delta = -corner_r)
            polygon(profile_pts());
        polygon(inner_pts());
    }
}

//-----------------------------------
// 3‑D SECTIONS
//-----------------------------------
module straight_section(section_len) {
    linear_extrude(section_len) mag_profile();
}

module curved_section() {
    radius_c     = straight_len / tan(bend_deg * PI / 180) / 2
                   + straight_len / (2 * sin(bend_deg * PI / 180));      // any large R works, but this keeps arc length ≈ straight_len
    delta_deg    = bend_deg / segments_curve;
    slice_len    = (radius_c * (bend_deg * PI / 180)) / segments_curve;  // arc‑length per slice

    for (i = [0 : segments_curve - 1]) {
        theta_deg = delta_deg * (i + 0.5);                // centre of slice
        theta_rad = theta_deg * PI / 180;

        translate([
            radius_c * (1 - cos(theta_rad)),
            0,
            straight_len + radius_c * sin(theta_rad)
        ])
        rotate([0, theta_deg, 0])
            linear_extrude(slice_len + 0.05)               // tiny overlap
                mag_profile();
    }
}

radius = arc_len / (bend_deg * PI / 180);   // r = s / θ
module curved_section_rotate() {



    // 1) build the arc in the XY plane with rotate_extrude
    // 2) tip the whole arc into the X‑Z plane
    // 3) slide it forward so it begins where the straight section ends
        rotate([-90, 0, 0])                  // XY → XZ
            rotate_extrude(angle = -bend_deg, $fn=500)
                translate([-radius, 0, 0])    // keep profile off the axis
                    mag_profile();

    // rotate_extrude(angle=4 * bend_deg, $fn = 100)
    //     translate([radius, 0, 0])    // keep profile off the axis
    //         mag_profile();
}

//-----------------------------------
//  FRONT RIDGE GEOMETRY
//-----------------------------------

// 2D cross section of “missing” wedge
module front_ridge_xsec() {
    difference() {
        // rectangle that would exist if no taper

        offset(r = corner_r)
        offset(delta = -corner_r)
            square([body_length, beam_width], center = false);
        // cut away the actual outer profile so only the wedge remains
        // mag_profile();
        polygon(inner_pts());

    }
}

// 3D rib between z0 … z1  (z0 < z1)
module front_ridge(z0, z1) {
    translate([0, 0, z0])
        linear_extrude(height = z1 - z0)
            front_ridge_xsec();
}

//-----------------------------------
//  RIB POSITIONS  (measured down from top)
//-----------------------------------
upper_rib_z0 = straight_len - 12;
upper_rib_z1 = straight_len -  7;

lower_rib_z0 = straight_len - 49;
lower_rib_z1 = straight_len - 44;

assert(upper_rib_z0 > 0 && lower_rib_z0 > 0, "rib Z range below zero");

feed_lips_r = 11.7 / 2;

module feed_lips_round() {

    big_r   = feed_lips_r;
    small_r = big_r - wall_width_side;
    lip_len = 32;            // cylinder length  (mm)


    cx      = lip_len / 2;
    cz      = straight_len;              // z plane = top of mag body

    module rear_spine_extension() {

        ext_h = 11.7/2;                   // = big_r  (feed‑lip radius)

        translate([0, 0, straight_len])   // start at mag‑top plane
            linear_extrude(height = ext_h)
            difference() {

            // ── outer rear slice (x ≤ 0)─────────────────────────────
            intersection() {
                // original outer profile (with fillet)
                offset(r = corner_r)
                    offset(delta = -corner_r)
                    polygon(profile_pts());

                // clip to rear‑only band  (from x = –ridge_length → 0)
                polygon([
                         [-ridge_length, -100],
                         [wall_width_rear,            -100],
                         [wall_width_rear,             200],
                         [-ridge_length, 200]
                         ]);
            }

            // ── subtract inner cavity to keep walls hollow ──────────
            polygon(inner_pts());
        }
    }

    // helper: build 2 cylinders at Y=± sides
    module cyl_pair(r) {
        for (cy = [big_r, beam_width - big_r])          // tangent to outer walls
            translate([cx, cy, cz])
                rotate([0, 90, 0])                      // axis → X
                    cylinder(h = lip_len, r = r, center = true);
    }

    module mag_profile_inverse() {
        linear_extrude(3 * big_r)
            difference() {
                polygon([
                         [-100, -100], [-100, 100], [100, 100], [100, -100]
                ]);
                offset(r = corner_r)
                    offset(delta = -corner_r)
                    polygon(profile_pts());
            }

    }

    union() {
        difference() { // curved parts
            // ── A. outer solids
            cyl_pair(big_r);

            // ── B. carve interior cradle from the hull of inner cylinders
            translate([0, 0, 1]) hull() cyl_pair(small_r);

            // ── C. trim anything poking into the mag cavity
            translate([0, 0, cz-9])
                linear_extrude(height = 10)
                polygon(inner_pts());

            // ── D. square‑off very top edges
            translate([cx - lip_len/2,
                       (beam_width - feed_lips_width)/2,
                       cz])
                cube([lip_len, feed_lips_width, 10], center = false);

            translate([0, 0, cz-10]) mag_profile_inverse();

            // round cut into front of feed lips
            for (cy = [big_r + wall_width_side, beam_width - big_r - wall_width_side])
                translate([cx + lip_len/2 - 0.01, cy , cz])         // flush with front face
                    cylinder(h = 2*big_r, r = big_r, center = true);

            translate([lip_len, 15, straight_len + 21.2])
                rotate([0, 45, 0])
                    cube([30,
                          30,
                          30], true);
        }

        difference() { // extension of rear ridge
            intersection() {
                rear_spine_extension();
                translate([-10, 0, 0]) cyl_pair(big_r);
            }
        }
    }
}

module feed_lips() {
    // union() {
    //     feed_lips_round();
    //     rear_spine_extension();
    // }
    feed_lips_round();
}

//-----------------------------------
//  BOTTOM BRIM   (floor-plate rail)
//-----------------------------------
brim_h      = 2.7;   // Z height
ext_max     = 1.5;   // side‑wall extension
ext_taper   = 1.0;   // extension at x = front_taper_start
nose_top_y = front_width_bot + ((beam_width - front_width_bot) / 2);
nose_bot_y = ((beam_width - front_width_bot) / 2);
// polygon that wraps the outer shell, minus the back ridge
brim_poly = [
             // rear face (no ridge)
             [0, -ext_max],
             [0,  beam_width + ext_max],

             // start of taper
             [front_taper_start,  beam_width + ext_taper],

             // nose (point)
             [body_length,  nose_top_y],
             [body_length,  nose_bot_y],

             // bottom of taper
             [front_taper_start, -ext_taper]
];
module bottom_brim() {
    // nose Y‑coordinates from outer profile



    difference() {
        // ── outer rail
            linear_extrude(height = brim_h)
                polygon(brim_poly);

        // ── hollow it out with the inner cavity outline
            linear_extrude(height = brim_h + 0.2)
                polygon(inner_pts());
    }
}

//-----------------------------------
// Base-plate
//-----------------------------------
plate_clear     = 0.15;  // slide clearance all round
plate_wall      = 2.0;   // wall thickness of base plate
plate_height    = 6.0;   // Z height of the plate “shoe”

module spring_seat_cutter() {
    cut_r   = 2.6;                  // semicircle radius (=> 5 mm width)
    flat_L  = 14.75;                // length of straight section
    cx1     = 20.75 + cut_r;        // rear circle center X
    cx2     = cx1 + flat_L;         // front circle center X (36.0)
    cy      = beam_width/2;         // centered in Y

    // overshoot downward & upward so it punches through every layer
        linear_extrude(height = plate_wall + plate_height + 2)
            hull() {
                translate([cx1, cy]) circle(r = cut_r, $fn = 32);
                translate([cx2, cy]) circle(r = cut_r, $fn = 32);
            }
}


module base_plate() {
    difference() {
        union() {
            linear_extrude(plate_wall) polygon(profile_pts());

            difference() {
                linear_extrude(plate_height)
                    offset(r = corner_r)
                    offset(delta = -corner_r)
                    offset(delta = plate_wall + plate_clear)
                    polygon(brim_poly);

                // cavity for brim + clearance
                translate([0,0, plate_wall])
                    linear_extrude(brim_h + 2 * plate_clear)
                    offset(delta = 2 * plate_clear)
                    polygon(brim_poly);


                translate([0, 0, plate_wall + brim_h])
                    linear_extrude(10)
                    offset(delta = 2 * plate_clear )
                    polygon(profile_pts());

                translate([-plate_wall-plate_clear, -ext_max-2*plate_clear-plate_wall, ])
                    cube([plate_wall, beam_width + 2 * ext_max + 4 * plate_clear + 2 * plate_wall, plate_height]);
            }
        }
        spring_seat_cutter();
    }
}

lips_top = straight_len + feed_lips_r;
catch_top = lips_top - 28;
catch_z_translate = catch_top - catch_height_z;
catch_x_translate = 10.3;
module magazine_catch_cutout() {


    // translate([10.3, 0, catch_top - catch_height_z])
    translate([catch_x_translate, beam_width - catch_depth_y, catch_z_translate])
        cube([catch_length_x, catch_depth_y, catch_height_z]);
}

module front_feed_cutout() {
    h = 3;

    // extend the cutout vertically to make sure and cut out the whole follower stop
    fudge = 4;

    translate([x_front, beam_width / 2, straight_len - (h / 2)])
        rotate([0, -45, 0])
            translate([0, 0, fudge / 2])
                cube([16, front_width_bot - (2 * wall_width_side_front), h + fudge], true);
}

module insert_stop() {
    translate([catch_x_translate, beam_width , catch_z_translate])
        rotate([-90, 0, 0])
        hull() {
        cube([catch_length_x, catch_height_z, 0.01]);
        translate([catch_length_x * 0.1, 0, 0.8]) cube([catch_length_x * 0.8, catch_height_z * 0.6, 0.01]);
    }
}

module bolt_cutout() {
    // cutouts for bolt and LRBHO catch
    union() {
        hull() {
            translate([0, center_y, straight_len + feed_lips_r - 2.5])
                linear_extrude(2.5) square(feed_lips_width, true);
            translate([-2 * wall_width_rear, center_y, straight_len + feed_lips_r - bolt_cut_depth])
                linear_extrude(0.01)  square([2 * bolt_cutout_bottom_width, bolt_cutout_bottom_width], true);
        }

        translate([-ridge_length, (beam_width / 2) + (feed_lips_width / 2), straight_len + feed_lips_r - bolt_cut_depth])
            rotate([0, -18, 180])
            cube([2 * ridge_length, feed_lips_width, bolt_cut_depth], false);


        translate([(-beam_width / 2) - 2, 0, straight_len + feed_lips_r - bolt_cut_depth]) cube(beam_width / 2);


    }
}

//-----------------------------------
// COMPLETE BODY
//-----------------------------------
module magazine_body() {
    difference() {
        union() {
            // straight walls
            straight_section(straight_len);

            // curved section
            translate([radius, 0, 0]) curved_section_rotate();

            // outer spacer ribs inside mag well
            front_ridge(upper_rib_z0, upper_rib_z1);
            front_ridge(lower_rib_z0, lower_rib_z1);

            // ...
            feed_lips();

            // lower straight section below curve
            translate([radius, 0, 0]) rotate([0, -bend_deg, 0]) translate([-radius, 0, -extra_bottom_len]) straight_section(extra_bottom_len);

            // bottom brim attached to bottom of magazine
            translate([radius, 0, 0]) rotate([0, -bend_deg, 0]) translate([-radius, 0, -extra_bottom_len]) bottom_brim();

            // front follower stop
            translate([x_front_inset - front_follower_stop_x, follower_y_lo, straight_len - front_follower_stop_h])
                cube([front_follower_stop_x, follower_front_w, front_follower_stop_h]);

            // over-insertion stop
            insert_stop();

        }

        bolt_cutout();


        // connection point for the magazine catch
        magazine_catch_cutout();

        // feed ramp cutout
        front_feed_cutout();
    }
}
// curved_section_rotate();
