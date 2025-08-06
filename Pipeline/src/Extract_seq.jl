for pkg in ["DataFrames", "CSV", "ArgParse", "FASTX"]
    try
        @eval using $(Symbol(pkg))
    catch e
        println("Installing $pkg...")
        import Pkg
        Pkg.add(pkg)
        @eval using $(Symbol(pkg))
    end
end


function read_fasta(file_path::String)
    println("Reading FASTA file: $file_path")
    fasta_dict = Dict{String, String}()
    
    reader = open(FASTA.Reader, file_path)
    for record in reader
        seq_name = identifier(record)
        seq = String(sequence(record))
        fasta_dict[seq_name] = seq
    end
    close(reader)
    
    println("FASTA file read complete.")
    return fasta_dict
end

function merge_overlapping_segments(df::DataFrame)
    grouped = groupby(df, Symbol("1"))
    merged_df = DataFrame(Symbol("1") => String[], :start => Int[], :endd => Int[])
    
    for subdf in grouped
        sort!(subdf, :start)
        start = subdf[1, :start]
        endd = subdf[1, :end]
        
        for i in 2:nrow(subdf)
            if subdf[i, :start] <= endd
                endd = max(endd, subdf[i, :end])
            else
                push!(merged_df, (subdf[1, Symbol("1")], start, endd))
                start = subdf[i, :start]
                endd = subdf[i, :end]
            end
        end
        
        push!(merged_df, (subdf[1, Symbol("1")], start, endd))
    end
    
    return merged_df
end

function save_sequences_to_fasta(merged_df::DataFrame, fasta_dict::Dict{String, String}, output_dir::String, name::String)
    for row in eachrow(merged_df)
        identifier = row[Symbol("1")]
        start = row[:start]
        endd = row[:endd]
        
        seq_name = "$(name)_$(identifier)_$(start)_$(endd).fna"
        header = ">$seq_name"
        
        if haskey(fasta_dict, identifier)
            sequence = fasta_dict[identifier]
            seq_length = length(sequence)
            
            if endd > seq_length
                endd = seq_length
            end
            
            if start + 1 <= seq_length
                substring = sequence[start+1:endd]
                
                output_path = joinpath(output_dir, seq_name)
                open(output_path, "w") do file
                    write(file, "$header\n$substring\n")
                end
            else
                println("Skipping $identifier due to out-of-bounds start position.")
            end
        else
            println("Skipping $identifier as it does not exist in the fasta_dict.")
        end
    end
end

# Main script
function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "fasta_file"
            help = "Path to the FASTA file"
            required = true
        "processed_file"
            help = "Path to the processed file"
            required = true
        "output_dir"
            help = "Output directory for the FASTA files"
            required = true
    end
    return parse_args(s)
end

function main()
    # Parse command-line arguments
    println("Parsing command-line arguments...")
    args = parse_commandline()
    fasta_file = args["fasta_file"]
    processed_file = args["processed_file"]
    output_dir = args["output_dir"]
    println("Command-line arguments parsed.")

    # Extract the NAME variable from the fasta_file path
    name = splitdir(fasta_file)[2]
    println("Extracted NAME variable: $name")

    # Read the FASTA file into a dictionary
    fasta_dict = read_fasta(fasta_file)

    # Read the processed file into a DataFrame
    println("Reading processed file: $processed_file")
    processed_df = CSV.read(processed_file, DataFrame)
    println("Processed file read complete.")

    # Subtract 1000 from start and add 1000 to end
    println("Adjusting start and end positions...")
    processed_df[!, :start] = max.(processed_df[!, :start] .- 1000, 0)
    processed_df[!, :end] = processed_df[!, :end] .+ 1000
    println("Start and end positions adjusted.")

    # Merge overlapping segments
    merged_df = merge_overlapping_segments(processed_df)

    # Save sequences to FASTA files
    save_sequences_to_fasta(merged_df, fasta_dict, output_dir, name)

    println("Pipeline completed successfully!")
end

main()
