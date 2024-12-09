#!/bin/bash

# 1. Create a directory 'data_folder' - all files will be stored here.
# Passed as the first argument. Default value is 'data' if not provided
data_folder=${1:-data}
prefix=${2:-HG00707}
mkdir -p "$data_folder"

echo "Directories in the current directory: $(ls -d */)"

# 2. Download the .bam file into the specified directory
echo "Downloading the .bam file to the $data_folder directory..."
wget -O "$data_folder/$prefix.bam" "https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/HG00707/alignment/HG00707.mapped.ILLUMINA.bwa.CHS.low_coverage.20120522.bam"

echo "Contents of $data_folder after downloading: $(ls $data_folder)"

#  3. Index and sort the downloaded .bam file.
echo "Indexing the .bam file..."
samtools index "$data_folder/$prefix.bam"

echo "Sorting the .bam file..."
samtools sort "$data_folder/$prefix.bam" -o "$data_folder/$prefix.sorted.bam"

echo "Remove initial .bam file..."
rm "$data_folder/$prefix.bam"

echo "Contents of $data_folder after indexing and sorting: $(ls $data_folder)"

# 4. Extract metadata from the .bam file header.
header_file="$data_folder/HEADER_$prefix"
echo "Extracting metadata from the .bam header into $header_file..."

# Save the header to a variable
header=$(samtools view -H "$data_folder/$prefix.sorted.bam")

# Lists of sections and tags to extract
sections=("@HD" "@SQ" "@SQ" "@RG" "@PG")
tags=("SO" "AS" "SP" "PL" "CL")
tags_with_one_value=("AS" "SP" "PL")
descriptions=(
    "@HD SO tag (sort order)"
    "@SQ AS tag (assembly)"
    "@SQ SP tag (species)"
    "@RG PL tag (sequence platform)"
    "@PG CL tag (command line)"
)

# Search for tags - as not all tags might be present, we use conditional structures
{
    echo "Metadata for the file $prefix.sorted.bam"
    echo "=================================="

    for i in "${!tags[@]}"; do
        tag="${tags[i]}"
        section="${sections[i]}"
        description="${descriptions[i]}"

        # For some tags, only the first value is needed; for CL, splitting by tabs is required
        if [[ "$tag" == "CL" ]]; then
            value=$(echo "$header" | grep "^$section" | awk -F'\t' -v tag="$tag" '{for(i=1; i<=NF; i++) if ($i ~ tag":") print $i}')
        elif [[ " ${tags_with_one_value[*]} " =~ " ${tag} " ]]; then
            value=$(echo "$header" | grep "^$section" | awk -v tag="$tag" '{for(i=1; i<=NF; i++) if ($i ~ tag":") print $i}' | head -1)
        else
            value=$(echo "$header" | grep "^$section" | awk -v tag="$tag" '{for(i=1; i<=NF; i++) if ($i ~ tag":") print $i}')
        fi

        # If the tag exists, write it to the file.
        if [[ -n $value ]]; then
            echo "$description"
            echo "$value"
            echo "-----------------------------------------------------------------------------"
        fi
    done
} > "$header_file"

echo "Metadata for the file $prefix.sorted.bam has been saved to $header_file"

rm "$data_folder/$prefix.sorted.bam"
rm "$data_folder/$prefix.bam.bai"
echo "Sorted .bam file and index for it have been removed"
