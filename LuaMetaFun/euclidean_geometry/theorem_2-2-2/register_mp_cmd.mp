
% parametric.mp
tau := 2 * pi ;



presetparameters "label" [
    px               = "0",
    py               = "0",
    pz               = "0",
    text            = "Label",
    transformation  = "identity_matrix()",
    texttransformation = "identity_matrix()"
] ;

def jasper_append_label = applyparameters "label" "jasper_do_label" enddef ;

vardef jasper_do_label =
    pushparameters "label" ;
    lua.mp.jasper_label_generate() ;
    popparameters ;
enddef ;

presetparameters "point" [
    fx              = "0",
    fy              = "0",
    fz              = "0",
    drawcommands    = "withcolor black",
    transformation  = "identity_matrix()"
] ;

def jasper_point = applyparameters "point" "jasper_do_point" enddef ;

vardef jasper_do_point =
    pushparameters "point" ;
    lua.mp.jasper_point_generate() ;
    popparameters ;
enddef ;


presetparameters "curve" [
    ustart          = 0,
    ustop           = tau,
    usamples        = 36,
    fx              = "cos(u)",
    fy              = "sin(u)",
    fz              = "u",
    drawcommands    = "withcolor black",
    transformation  = "identity_matrix()"
] ;

def jasper_curve = applyparameters "curve" "jasper_do_curve" enddef ;

vardef jasper_do_curve =
    pushparameters "curve" ;
    lua.mp.jasper_curve_generate() ;
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
    transformation  = "identity_matrix()"
] ;

def jasper_surface = applyparameters "surface" "jasper_do_surface" enddef ;

vardef jasper_do_surface =
    pushparameters "surface" ;
    lua.mp.jasper_surface_generate() ;
    popparameters ;
enddef ;


def jasper_render_segments = jasper_do_render_segments enddef ;

vardef jasper_do_render_segments =
    lua.mp.jasper_render_segments_generate() ;
enddef ;