include <magazine.scad>;

// short section
// union() {
//     intersection() {
//         straight_section();
//         translate([-20, 0, 0])
//             cube([300, 300, 7]);
//     }
//     bottom_brim();
// }


// straight upper section
straight_len = 76;

module magazine_body() {
    difference() {
        union() {
            straight_section(straight_len);

            front_ridge(upper_rib_z0, upper_rib_z1);
            front_ridge(lower_rib_z0, lower_rib_z1);
            feed_lips();
            bottom_brim();

            translate([x_front_inset - front_follower_stop_x, follower_y_lo, straight_len - front_follower_stop_h])
                cube([front_follower_stop_x, follower_front_w, front_follower_stop_h]);

            // over-insertion stop
            insert_stop();

        }

        // cutouts for bolt and LRBHO catch
        bolt_cutout();

        // connection point for the magazine catch
        magazine_catch_cutout();

        // feed ramp cutout
        front_feed_cutout();



    }
}
magazine_body();
