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

(rnaseq_tracks) [igentile@bamdev2 CLE_mmseq]$ ls *jl
adj2list.jl  FR.jl  index_list.jl
(rnaseq_tracks) [igentile@bamdev2 CLE_mmseq]$ cat adj2list.jl
# Dependency check
import Pkg
for pkg in ["DelimitedFiles", "ProgressMeter"]
    try
        @eval import $(Symbol(pkg))
    catch
        println("Installing missing package: $pkg")
        Pkg.add(pkg)
        @eval import $(Symbol(pkg))
    end
end

using DelimitedFiles
using ProgressMeter

# Load IDs and adjacency matrix
ids = readdlm("CLE_nodes.txt", String)[:]     # Vector of node IDs
A = readdlm("CLE_adj_matrix.tsv", '\t', Float64)
n = length(ids)

total_entries = n * n
io = open("CLE_edgelist.tsv", "w")

# Write edges with a progress bar showing time-based updates
@showprogress for idx in 1:total_entries
    i = Int(div(idx-1, n) + 1)
    j = Int(mod(idx-1, n) + 1)
    val = A[i, j]
    if val != 0.0
        println(io, "$(ids[i])\t$(ids[j])\t$val")
    end
end

close(io)
println("Done! Edge list saved to CLE_edgelist.tsv")
