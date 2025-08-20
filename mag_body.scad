
include <magazine.scad>;


bend_deg = 17;
text_extrude = 0.25;

difference() {

    // render the magazine body
    union() {
        magazine_body();
        scale = 0.1;
        translate([12, 0, -100]) rotate([90, 0, 0]) scale([scale, scale, scale]) import("florida.stl");
        translate([45, beam_width , -10]) rotate([90, 0, 180]) linear_extrude(text_extrude) text("Your Ad Here", size=3);
    }


    // cutaway for visualization in design
    // translate([-10, 17, -250]) cube([500, 500, 500]);
}
