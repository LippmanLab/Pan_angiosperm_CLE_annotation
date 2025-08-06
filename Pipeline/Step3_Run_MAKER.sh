#!/bin/bash

line="$1"
dna_path="$line"
dna_dir="${line##*/}"

# Determine species based on taxonomy ID
species="arabidopsis"


# Directory checks and creation
if [ -d "$dna_dir" ] || [ -d "temp_${dna_dir}" ]; then
  echo "Directories for $dna_dir already exist, skipping..."
  exit
fi

if [ ! -f "$dna_path" ]; then
  echo "The DNA path $dna_path does not exist, skipping..."
  exit
fi

mkdir -p "$dna_dir"
temp_dir="temp_${dna_dir}"
mkdir "$temp_dir"
cd "$temp_dir"

cp /grid/lippman/analysis/raw_data/IG_genomes/ZFF/maker_bopts.ctl /grid/lippman/analysis/raw_data/IG_genomes/ZFF/maker_evm.ctl /grid/lippman/analysis/raw_data/IG_genomes/ZFF/maker_exe.ctl /grid/lippman/analysis/raw_data/IG_genomes/ZFF/maker_opts.ctl .
sed -i "s|genome=#|genome=$dna_path|" maker_opts.ctl
sed -i "s|augustus_species=$species|" maker_opts.ctl
maker

output_dir=$(ls -td -- */ | head -n 1)
mv "$output_dir" "$species"
mv "$species" "../$dna_dir"

cd ..

# Locate all .gff files within the species directory and rename them
find "$dna_dir/$species" -name '*.gff' -exec sh -c 'mv "$1" "'"$dna_dir/${species}_"'$(basename "$1")"' _ {} \;

# Remove the species directory
rm -rf "$dna_dir/$species"

rm -r "$temp_dir"
