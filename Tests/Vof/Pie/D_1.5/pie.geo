//------------------------------------------
//
// Base all dimensions on the bubble radius
//
//------------------------------------------
r_bub = 0.00075;

//-------------------
// Define dimensions
//-------------------
x_min = r_bub *  1.0e-4;      // this is just something very small
x_max = r_bub *  8.0;         // recommended by Lubos, if I am not mistaken
y_max = r_bub * 30.0;
delta_min = r_bub / 20.0;     // say 40 cells across the bubble
delta_max = delta_min * 8.0;  // this is a bit arbitrary, but bigger is better

wake_x_min = -r_bub * 2.5;    // quite a safety margin: 2.5
wake_x_max = -wake_x_min;
wake_y_min = -1.0;
wake_y_max =  y_max - wake_y_min;
wake_limit_width = r_bub * 0.25;

//---------------
// Define points
//---------------
Point(1) = {x_min,   0.0,     0.0,   delta_min};
Point(2) = {x_max,   0.0,     0.0,   delta_max};
Point(3) = {x_max,   y_max,   0.0,   delta_max};
Point(4) = {x_min,   y_max,   0.0,   delta_min};

//--------------
// Define lines
//--------------
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

//----------------
// Define surface
//----------------
Curve Loop(1) = {1, 2, 3, 4};
Plane Surface(1) = {1};

//-------------
// Define mesh
//-------------

// Define spacing function with MathEval
Field[1] = MathEval;
Field[1].F = Sprintf("  (%5.2g)
                      + (%5.2g) * (1.0-(0.5*(  tanh((x-(%5.2g))/(%5.2g))
                                             - tanh((x-(%5.2g))/(%5.2g))))
                                      *(0.5*(  tanh((y-(%5.2g))/(%5.2g))
                                             - tanh((y-(%5.2g))/(%5.2g)))) )",
  delta_min,
  delta_max - delta_min,
  wake_x_min, wake_limit_width,
  wake_x_max, wake_limit_width,
  wake_y_min, wake_limit_width,
  wake_y_max, wake_limit_width);
Background Field = 1;

Recombine Surface{1};
Mesh.Algorithm = 8;

Extrude {{0, 1, 0}, {0, 0, 0}, Pi/4} {
  Surface{1}; Layers{5}; Recombine;
}

//---------------------------------------
// Define volume and boundary conditions
//---------------------------------------

Physical Volume("Fluid") = {1};

Physical Surface("Top")      = {21};
Physical Surface("Bottom")   = {13};
Physical Surface("Axe")      = {25};
Physical Surface("Cylinder") = {17};
Physical Surface("Cuts")     = {1, 26};
