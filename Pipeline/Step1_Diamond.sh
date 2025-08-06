#!/bin/bash
#$ -cwd
#$ -pe threads 40
#$ -l m_mem_free=35G
#$ -N Diamond_Allign
#$ -o Diamond_out.txt
#$ -e Diamond_log.txt

# Load the required modules
module load EBModules
module load Anaconda3

# Activate the necessary environment

# Set the parent directory containing the subdirectories with .fna.gz files
PARENT_DIR=""

# Function to perform the blastx alignment
perform_blastx() {
  fy_gz_file=$1

  # Extract the base file name without the .fna.gz extension
  base_name=$(basename "$fy_gz_file" .fna)
  output_file="${base_name}_matches.m8"

  # If the output file already exists, print a message and skip this iteration
  if [ -e "$output_file" ]; then
    echo "$output_file already exists, moving to the next file"
    return
  fi

  # Run the diamond blastx command
  ./diamond blastx -d YOUR_SOURCE_PROTEIN_FILE  -q "$fy_gz_file" -o "${base_name}_matches.m8" --ultra-sensitive --masking 0 --iterate
}

# Export the function for GNU Parallel to use it
export -f perform_blastx

# Run the blastx command in parallel for each file
find "$PARENT_DIR" -type f -name '*.fna' | parallel -j 60 perform_blastx {}
