#!/bin/bash

echo "Starting the processing of directories..."

# Loop over directories that have 12-character names
for dir in ????????????; do
    if [ -d "$dir" ]; then
        echo "Entering directory: $dir"

        # Change into the directory
        cd "$dir"

        # Count the number of files in the directory
        file_count=$(ls -1 | wc -l)

        # Check if there's exactly one file and it's the expected FASTA file
        if [ "$file_count" -eq 1 ] && [ -f "SlCLV1_${dir}.fasta" ]; then
            echo "Found one file, which is the expected FASTA file. Running colabfold_batch..."
            # Execute the colabfold_batch command
            colabfold_batch --templates --amber --model-type alphafold2_multimer_v3 "SlCLV1_${dir}.fasta" ./
            echo "colabfold_batch processing completed for $dir"
        else
            echo "Skipping directory $dir: Criteria not met (either file count is not 1 or the FASTA file is missing)"
        fi

        # Go back to the parent directory
        cd ..

        echo "Exiting directory: $dir"
    fi
done

echo "Processing complete."
