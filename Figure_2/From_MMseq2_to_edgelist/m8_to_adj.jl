import Pkg

function ensure_pkg(pkg::String)
    try
        @eval import $(Symbol(pkg))
    catch
        println("Package $pkg not found. Installing...")
        Pkg.add(pkg)
        @eval import $(Symbol(pkg))
(rnaseq_tracks) [igentile@bamdev2 CLE_mmseq]$ cat m8_to_adj.txt
# --- Dependency check ---
import Pkg

function ensure_pkg(pkg::String)
    try
        @eval import $(Symbol(pkg))
    catch
        println("Package $pkg not found. Installing...")
        Pkg.add(pkg)
        @eval import $(Symbol(pkg))
    end
end

for pkg in ["DelimitedFiles", "LinearAlgebra", "Statistics", "ProgressMeter"]
    ensure_pkg(pkg)
end

using DelimitedFiles
using LinearAlgebra
using Statistics
using ProgressMeter

# --- Parameters ---
input_file = "CLE_vs_CLE_aln.m8"
topk = 200

# --- Read BLAST/ MMseqs m8 ---
data = readdlm(input_file, '\t', String)

qids = data[:,1]
sids = data[:,2]
evals = parse.(Float64, data[:,11])

# Map sequence IDs to indices
all_ids = unique(vcat(qids, sids))
id_to_idx = Dict(id => i for (i,id) in enumerate(all_ids))
n = length(all_ids)

# Initialize adjacency matrix
A = zeros(Float64, n, n)

# --- Fill adjacency matrix ---
@showprogress 1 "Filling adjacency matrix..." for (q, s, e) in zip(qids, sids, evals)
    qi, si = id_to_idx[q], id_to_idx[s]
    val = -log10(e + eps())  # avoid log(0)
    A[qi, si] = max(A[qi, si], val)
end

# --- Keep only top-K values per row ---
@showprogress 1 "Pruning to top $topk per row..." for i in 1:n
    rowvals = A[i, :]
    idxs = partialsortperm(rowvals, rev=true, 1:min(topk, n))
    mask = trues(n)
    mask[idxs] .= false
    A[i, mask] .= 0.0
end

# --- Symmetrize ---
@showprogress 1 "Symmetrizing matrix..." for i in 1:n
    for j in i+1:n
        val = max(A[i,j], A[j,i])
        A[i,j] = val
        A[j,i] = val
    end
end

# --- Save outputs ---
writedlm("CLE_adj_matrix.tsv", A, '\t')
writedlm("CLE_nodes.txt", all_ids)

println("✅ Done! Matrix saved to CLE_adj_matrix.tsv and nodes to CLE_nodes.txt")
