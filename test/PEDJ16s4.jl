# Section 4 of
# M. Philippe, R. Essick, G. E. Dullerud and R. M. Jungers.
# "Stability of discrete-time switching systems with constrained switching sequences."
# Automatica, 72:242-250, 2016
# The JSR is 0.9748171979372074

const expected_lb = [0.7096115688862492,
                     0.749432937404542,
                     0.803983520107364,
                     0.8425634051754579,
                     0.8674767989157529,
                     0.8844616629378517]
const expected_ub = [1.0035568400762171,
                     0.9863261446338583,
                     0.9769402921375085,
                     0.9749706065652288,
                     0.9749659545861287,
                     0.9749138871770363]

@testset "[PEDJ] Section 4" begin
    A = [0.94 0.56; 0.14 0.46]
    B = [0; 1]
    k1 = -0.49
    k2 = 0.27
    As = [A + B * [k1 k2], A + B * [0 k2], A + B * [k1 0], A]
    G = DiGraph(4)
    σ = Dict{Edge, Int}()
    function add_edge_labeled!(G, u, v, σuv)
        e = u => v
        σ[e] = σuv
        add_edge!(G, e)
    end
    add_edge_labeled!(G, 1, 2, 3)
    add_edge_labeled!(G, 2, 1, 2)
    add_edge_labeled!(G, 1, 3, 1)
    add_edge_labeled!(G, 3, 1, 2)
    add_edge_labeled!(G, 2, 3, 1)
    add_edge_labeled!(G, 3, 2, 3)
    add_edge_labeled!(G, 3, 3, 1)
    add_edge_labeled!(G, 3, 4, 4)
    add_edge_labeled!(G, 4, 3, 1)
    s = ConstrainedDiscreteSwitchedSystem(As, G, σ)
    snp = ConstrainedDiscretePeriodicSwitching(s, [3=>1, 1=>3, 3=>1, 1=>3, 3=>3, 3=>3, 3=>3, 3=>3])
    @test snp.growthrate == 0.9728940109399586
    smp = ConstrainedDiscretePeriodicSwitching(s, [3=>1, 1=>3, 3=>1, 1=>2, 2=>3, 3=>3, 3=>3, 3=>3])
    @test smp.growthrate == 0.9748171979372074
    for solver in sdp_solvers
        println("  > With solver $(typeof(solver))")
        for d in 1:6
            tol = ismosek(solver) ? 3e-4 : 1e-3
            lb, ub = soslyapb(s, d, solver=solver, tol=tol)
            @test abs(log(lb) - log(expected_lb[d])) <= tol
            @test abs(log(ub) - log(expected_ub[d])) <= tol
            psw = sosbuildsequence(s, d, p_0=:Primal)
            @test isnull(psw) == false
            @test get(psw) == (d <= 3 ? snp : smp)
        end
    end
end