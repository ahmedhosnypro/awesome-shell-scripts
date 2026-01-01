#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}PDF Page Extractor with Bookmark Filtering${NC}"
echo -e "${CYAN}==========================================${NC}"

# Check if fzf is installed
if ! command -v fzf &> /dev/null; then
    echo -e "${YELLOW}Installing fzf for interactive file selection...${NC}"
    sudo apt update && sudo apt install -y fzf
fi

# Interactive PDF file selection with fzf
echo -e "${BLUE}Select PDF file:${NC}"
pdf_file=$(find . -name "*.pdf" -type f 2>/dev/null | fzf --prompt="PDF> " --height=40% --border --preview="echo 'File: {}'" --preview-window=up:1)

if [[ -z "$pdf_file" ]]; then
    echo -e "${RED}No file selected. Exiting.${NC}"
    exit 1
fi

echo -e "${GREEN}Selected: $pdf_file${NC}"

# Check if file exists
if [[ ! -f "$pdf_file" ]]; then
    echo "Error: File '$pdf_file' not found!"
    exit 1
fi

# Get page range
while true; do
    echo -e "${BLUE}Enter page range (format: start-end, e.g., ${YELLOW}10-20${BLUE}):${NC}"
    read -p "> " range
    if [[ $range =~ ^[0-9]+-[0-9]+$ ]]; then
        start_page=$(echo $range | cut -d'-' -f1)
        end_page=$(echo $range | cut -d'-' -f2)
        if [[ $start_page -le $end_page ]]; then
            break
        else
            echo -e "${RED}Error: Start page must be <= end page${NC}"
        fi
    else
        echo -e "${RED}Error: Invalid format. Use: start-end (e.g., 10-20)${NC}"
    fi
done

# Generate default output name
basename=$(basename "$pdf_file" .pdf)
default_output="${basename}_pages_${range}_filtered.pdf"

# Get output filename
echo -e "${BLUE}Output filename [${YELLOW}$default_output${BLUE}]:${NC}"
read -p "> " output_file
output_file=${output_file:-$default_output}

echo -e "${CYAN}Extracting pages $start_page-$end_page from '$pdf_file'...${NC}"

# Extract pages
pdftk "$pdf_file" cat $start_page-$end_page output temp_extract.pdf

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to extract pages${NC}"
    exit 1
fi

# Get original metadata and filter bookmarks
pdftk "$pdf_file" dump_data > original_metadata.txt

# Filter bookmarks for the page range
awk -v start=$start_page -v end=$end_page '
BEGIN { in_bookmark=0; bookmark_page=0 }
/^BookmarkBegin$/ { 
    in_bookmark=1; 
    bookmark_block="BookmarkBegin\n"; 
    next 
}
in_bookmark && /^BookmarkPageNumber:/ { 
    bookmark_page = $2;
    if (bookmark_page >= start && bookmark_page <= end) {
        new_page = bookmark_page - start + 1;
        bookmark_block = bookmark_block "BookmarkPageNumber: " new_page "\n";
        print bookmark_block;
    }
    in_bookmark=0;
    bookmark_block="";
    next;
}
in_bookmark { 
    bookmark_block = bookmark_block $0 "\n"; 
    next 
}
!in_bookmark && !/^Bookmark/ { print }
' original_metadata.txt > filtered_bookmarks.txt

# Get extracted PDF metadata
pdftk temp_extract.pdf dump_data > extract_metadata.txt

# Insert filtered bookmarks after NumberOfPages line
num_pages=$((end_page - start_page + 1))
awk -v bookmarks="filtered_bookmarks.txt" -v pages=$num_pages '
/^NumberOfPages:/ { 
    print; 
    while ((getline line < bookmarks) > 0) {
        if (line ~ /^Bookmark/) print line;
    }
    close(bookmarks);
    next;
}
!/^Bookmark/ { print }
' extract_metadata.txt > new_metadata.txt

# Update PDF with filtered bookmarks
pdftk temp_extract.pdf update_info new_metadata.txt output "$output_file"

# Cleanup
rm -f temp_extract.pdf original_metadata.txt filtered_bookmarks.txt extract_metadata.txt new_metadata.txt

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Success! Created: $output_file${NC}"
    ls -lh "$output_file"
else
    echo -e "${RED}Error: Failed to create output file${NC}"
    exit 1
fi
