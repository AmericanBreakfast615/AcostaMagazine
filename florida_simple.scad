// florida_simple_positive_coords.scad
// Simple outline with every coordinate ≥ 0.
// Northwest corner fixed at (0, 500).

module mainland(thickness = 5) {
    linear_extrude(height = thickness)
        polygon(points = [
            [  0, 500],  // northwest corner of the panhandle
            [  0, 450],  // southwest corner of the panhandle (FL‑AL border meets Gulf)
            [75, 455],   // Destin
            [ 130, 430], // Apalachicola National Forest
            [ 180, 450], // northern tip of Apalachee Bay
            [240, 400],  // Cedar Key
            [235, 310],  // Clearwater / St. Pete
            [295, 210],  // Naples
            [315, 190],  // Nothing
            [335, 155],  // Everglades southern tip (Flamingo)
            [355, 155],  // US‑1 leaves mainland (bridge start)
            [385, 190],  // Miami
            [390, 240],  // Palm Beach
            [380, 315],  // Melbourne
            [385, 345],  // Cape Canaveral
            [335, 420],  // Daytona
            [310, 498],  // Jacksonville/top right corner
            [280, 498],  // nothing
            [280, 475],  // woods
            [272, 475],  // bigfoot
            [272, 488],  // Indian ghosts
            [135, 490],  // Chatahootche
            [130, 500]   // tri-state area

        ]);
}


// ——— island helper ———
module island(cx, cy, len, w = 4, ang = 0, thickness = 5) {
    translate([cx, cy, 0])
        rotate(ang)
            linear_extrude(height = thickness)
                square([len, w], center = true);
}


// Preview or render
thickness = 5;

union() {
    mainland(thickness = thickness);
    // Key Biscayne
    island(380, 180, 20, 4, 75);

    // Florida Keys (largest → west)
    island(362, 152, 15, 4, 45, thickness);   // Key Largo
    island(345, 138, 9, 4, 25, thickness);   // Islamorada
    island(330, 132, 6, 4, 20, thickness);   // Marathon
    island(314, 128, 6, 6, 20, thickness);   // Big Pine Key
    island(304,  124, 2, 4, 20, thickness);  // Key West
}
