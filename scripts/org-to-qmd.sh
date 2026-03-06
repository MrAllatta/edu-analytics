#!/bin/bash
# ============================================================
# org-to-qmd.sh - Convert Org files to Quarto Markdown
# 
# Uses Emacs in batch mode to export org files to markdown,
# then renames to .qmd for Quarto processing.
# ============================================================

set -e

ORG_DIR="org"
QMD_DIR="output"

echo "Converting Org files to Quarto Markdown..."
echo "==========================================="

# Check if emacs is available
if ! command -v emacs &> /dev/null; then
    echo "Error: Emacs not found. Please install Emacs."
    echo "Alternative: Use pandoc for conversion (see below)"
    exit 1
fi

# Process each org file
for org_file in "$ORG_DIR"/*.org; do
    if [ -f "$org_file" ]; then
        basename=$(basename "$org_file" .org)
        qmd_file="$QMD_DIR/$basename.qmd"
        
        echo "Converting: $org_file -> $qmd_file"
        
        # Export using Emacs batch mode
        emacs --batch \
              --eval "(require 'org)" \
              --eval "(require 'ox-md)" \
              --visit="$org_file" \
              --eval "(org-md-export-to-markdown)" \
              2>/dev/null
        
        # Rename .md to .qmd
        md_file="$ORG_DIR/$basename.md"
        if [ -f "$md_file" ]; then
            mv "$md_file" "$qmd_file"
            echo "  ✓ Created: $qmd_file"
        fi
    fi
done

echo ""
echo "Conversion complete!"
echo "Run 'quarto render' to build the website."
