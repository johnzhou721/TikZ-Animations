

function get_observer_plane_basis(observer)
    origin = {0,0,0}
    basis_i = pv_orthogonal_vector(observer)
    basis_j = pv_cross_product(observer,basis_i)
    return {origin,basis_i,basis_j}

end

function project_point_onto_basis(point,basis)
    normal = pv_cross_product(basis[2],basis[3])
    signed_distance_from_plane = pv_orthogonal_vector_projection(point,normal)
    result = {
        point[1]-signed_distance_from_plane[1]
        ,point[2]-signed_distance_from_plane[2]
        ,point[3]-signed_distance_from_plane[3]
    }
    return result
end



function compare_triangles(triangle_1,triangle_2)
    P_1,Q_1,R_1,color_1,options_1 = table.unpack(triangle_1)
    P_2,Q_2,R_2,color_2,options_2 = table.unpack(triangle_2)
    observer_basis = get_observer_plane_basis(observer)
    P_1_projection = project_point_onto_basis(P_1)
    Q_1_projection = project_point_onto_basis(Q_1)
    R_1_projection = project_point_onto_basis(R_1)
    P_2_projection = project_point_onto_basis(P_2)
    Q_2_projection = project_point_onto_basis(Q_2)
    R_2_projection = project_point_onto_basis(R_2)
    -- compare to triangle 1
    PQ_cross_P_2 = pv_cross_product(
        pv_addition(Q_1,pv_scalar_multiplication({P_1,-1}))
        ,P_2
    )
    PQ_cross_Q_2 = pv_cross_product(
        pv_addition(Q_1,pv_scalar_multiplication({P_1,-1}))
        ,Q_2
    )
    PQ_cross_R_2 = pv_cross_product(
        pv_addition(Q_1,pv_scalar_multiplication({P_1,-1}))
        ,R_2
    )
    if (
        pv_sign(PQ_cross_P_2[1]) == pv_sign(PQ_cross_Q_2[1]) and 
        pv_sign(PQ_cross_P_2[1]) == pv_sign(PQ_cross_R_2[1])
    ) then
        
    end
end







segments = {}
function pv_append_surface(
    u_start
    ,u_end
    ,u_samples
    ,v_start
    ,v_end
    ,v_samples
    ,fx,fy,fz
    ,options
)
    local u_step = (u_end - u_start) / (u_samples - 1)
    local v_step = (v_end - v_start) / (v_samples - 1)
    local function parametric_surface(u,v)
        return {fx(u,v), fy(u,v), fz(u,v)}
    end
    for i = 0, u_samples - 2 do
        local u = u_start + i * u_step
        local color = (u - u_start) / (u_end - u_start)
        for j = 0, v_samples - 2 do
            local v = v_start + j * v_step
            local A = surface(u, v)
            local B = surface(u + u_step, v)
            local C = surface(u, v + v_step)
            local D = surface(u + u_step, v + v_step)
            -- the tables for surfaces have 5 values
            table.insert(segments, {A, B, D, color, options})
            table.insert(segments, {A, C, D, color, options})
        end
    end

end -- ends pv_append_surface

function pv_render_segments()
    table.sort(segments, segment_comparator)
end

