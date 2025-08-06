#!/bin/bash
#$ -cwd                    # Use current working directory.
#$ -j y                    # Merge standard output and standard error to one file.
#$ -l m_mem_free=6G        # Request 6GB of memory per node.
#$ -l tmp_free=10G        # Request 100GB of temporary storage.
#$ -o Extract.txt         # Output file for standard output/error.
#$ -pe threads 1           # Request 8 threads.

# Load necessary modules. Note: The exact command might need to be adjusted based on your HPC environment.
module load EBModules
module load Python
module load Julia

FASTA=$(sed -n "${SGE_TASK_ID}p" /grid/lippman/data/temp_IG/CLES/My_genomes.txt)

# Extract the basename without path or .gz extension.
BASENAME=$(basename "$FASTA" .fasta.gz)  # Assuming filenames end with '.fasta.gz'

# Copy the FASTA file to the temporary directory.
cp -v "$FASTA" "$TMPDIR/$BASENAME.fasta.gz"

# Decompress the file.
gunzip "$TMPDIR/$BASENAME.fasta.gz"

# Check if decompression succeeded.
if [ $? -ne 0 ]; then
    echo "gunzip failed."
    exit 1
fi

# The path to the decompressed FASTA file.
DECOMPRESSED_FASTA="$TMPDIR/$BASENAME.fasta"

Input1=${BASENAME}_blast_results.txt
Expected_output=${BASENAME}_blast_results.txt_processed

# Check if the expected output file already exists.
if [ -f "$Expected_output" ]; then
    echo "Expected output file $Expected_output already exists. Skipping processing."
else
    # Run the Python script.
    python Process_blast_output.py "$Input1"

    # Check if the Python script succeeded.
    if [ $? -ne 0 ]; then
        echo "Python script failed."
        exit 1
    fi
fi

# Check if possible outputs already exist.
if [ ! -z "$(find /grid/lippman/data/temp_IG/CLES/Sequences/ -name "$BASENAME*")" ]; then
    echo "Possible outputs for $BASENAME already exist. Skipping processing."
else
    # Run the Julia script.
    julia Extract_seq.jl "$DECOMPRESSED_FASTA" "$Expected_output" /grid/lippman/data/temp_IG/CLES/Sequences

    # Check if the Julia script succeeded.
    if [ $? -ne 0 ]; then
        echo "Julia script failed."
        exit 1
    fi
fi
