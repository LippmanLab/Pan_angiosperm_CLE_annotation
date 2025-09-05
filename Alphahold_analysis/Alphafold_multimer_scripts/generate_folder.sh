#!/bin/bash

# Run the Python script and store the output in a variable
substitutions=$(python generate_substitutions.py)

# Loop over each substitution and create a directory
for sub in $substitutions; do
    mkdir "$sub"
done
