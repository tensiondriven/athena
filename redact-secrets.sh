#!/bin/bash

# Redact secrets from files - preserves files while removing sensitive data
# Usage: ./redact-secrets.sh [file or directory]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to redact secrets in a file
redact_file() {
    local file="$1"
    local modified=false
    
    echo -e "${YELLOW}Checking${NC} $file"
    
    # Create backup
    cp "$file" "$file.backup"
    
    # Redact various API key patterns
    # OpenRouter keys
    if grep -q "sk-or-" "$file"; then
        sed -i '' 's/sk-or-[a-zA-Z0-9_-]\{20,\}/REDACTED_OPENROUTER_KEY/g' "$file"
        modified=true
        echo -e "  ${GREEN}✓${NC} Redacted OpenRouter keys"
    fi
    
    # Anthropic keys  
    if grep -q "sk-ant-" "$file"; then
        sed -i '' 's/sk-ant-[a-zA-Z0-9_-]\{20,\}/REDACTED_ANTHROPIC_KEY/g' "$file"
        modified=true
        echo -e "  ${GREEN}✓${NC} Redacted Anthropic keys"
    fi
    
    # OpenAI keys
    if grep -q "sk-[a-zA-Z0-9]\{48\}" "$file"; then
        sed -i '' 's/sk-[a-zA-Z0-9]\{48\}/REDACTED_OPENAI_KEY/g' "$file"
        modified=true
        echo -e "  ${GREEN}✓${NC} Redacted OpenAI keys"
    fi
    
    # Generic API key patterns
    if grep -q "api[_-]key['\"]]*[:=]['\"]]*[a-zA-Z0-9_-]\{32,\}" "$file"; then
        sed -i '' 's/\(api[_-]key['\''\"]*[:=]['\''\"]]*\)[a-zA-Z0-9_-]\{32,\}/\1REDACTED_API_KEY/g' "$file"
        modified=true
        echo -e "  ${GREEN}✓${NC} Redacted generic API keys"
    fi
    
    # AWS keys
    if grep -q "AKIA[0-9A-Z]\{16\}" "$file"; then
        sed -i '' 's/AKIA[0-9A-Z]\{16\}/REDACTED_AWS_ACCESS_KEY/g' "$file"
        modified=true
        echo -e "  ${GREEN}✓${NC} Redacted AWS access keys"
    fi
    
    # Check if file was modified
    if [ "$modified" = true ]; then
        # Remove backup if redaction successful
        rm "$file.backup"
        echo -e "${GREEN}✅ Redacted secrets from${NC} $file"
    else
        # Remove backup if no changes
        rm "$file.backup"
        echo -e "  No secrets found"
    fi
}

# Function to find and redact in directory
redact_directory() {
    local dir="$1"
    local count=0
    
    echo -e "${YELLOW}Scanning directory:${NC} $dir"
    echo ""
    
    # Find all text files (excluding binaries and .git)
    while IFS= read -r -d '' file; do
        if file "$file" | grep -q "text"; then
            redact_file "$file"
            ((count++))
        fi
    done < <(find "$dir" -type f -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/.env" -print0)
    
    echo ""
    echo -e "${GREEN}Processed $count files${NC}"
}

# Main script
main() {
    local target="${1:-.}"
    
    echo -e "${YELLOW}🔒 Secret Redaction Tool${NC}"
    echo -e "========================"
    echo ""
    
    if [ -f "$target" ]; then
        # Single file
        redact_file "$target"
    elif [ -d "$target" ]; then
        # Directory
        redact_directory "$target"
    else
        echo -e "${RED}Error:${NC} '$target' is not a valid file or directory"
        exit 1
    fi
    
    echo ""
    echo -e "${YELLOW}⚠️  Important:${NC}"
    echo "  - Review changes with: git diff"
    echo "  - Commit redacted files immediately"
    echo "  - Never commit files with .backup extension"
}

# Run main function
main "$@"