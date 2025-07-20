% parametric.mp
tau := 2 * pi ;
presetparameters "curve" [
    ustart          = 0,
    ustop           = tau,
    usamples        = 36,
    fx              = "cos(u)",
    fy              = "sin(u)",
    fz              = "u",
    drawcommands    = "withcolor black",
    transformation  = "identity()"
] ;

def lmt_curve = applyparameters "curve" "lmt_do_curve" enddef ;

vardef lmt_do_curve =
    pushparameters "curve" ;
    lua.mp.lmt_curve_generate() ;
    popparameters ;
enddef ;



presetparameters "surface" [
    ustart          = 0,
    ustop           = tau,
    usamples        = 36,
    vstart          = 0,
    vstop           = pi,
    vsamples        = 18,
    fx              = "sin(v)*cos(u)",
    fy              = "sin(v)*sin(u)",
    fz              = "cos(v)",
    drawcommands    = "withcolor black",
    fillcommands    = "withcolor darkred",
    transformation  = "identity()"
] ;

def lmt_surface = applyparameters "surface" "lmt_do_surface" enddef ;

vardef lmt_do_surface =
    pushparameters "surface" ;
    lua.mp.lmt_surface_generate() ;
    popparameters ;
enddef ;


def lmt_render_segments = lmt_do_render_segments enddef ;

vardef lmt_do_render_segments =
    image(
        lua.mp.lmt_render_segments_generate() ;
    )
enddef ;