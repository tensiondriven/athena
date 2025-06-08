#!/bin/bash

# Activate virtual environment
source .venv/bin/activate

# Create sample text file
cat > sample_text.txt << 'EOF'
Apple CEO Tim Cook announced a new iPhone today in Cupertino, California.
Google's Sundar Pichai spoke at the I/O conference in Mountain View last May.
Tesla and SpaceX founder Elon Musk announced plans to visit Mars by 2030.
Microsoft released Windows 11 in October, according to CEO Satya Nadella.
EOF

echo "Running NER extraction on sample text..."
echo ""

# Process the text and save to output file
cat sample_text.txt | python ner_extract.py > output.jsonl

# Display the results
echo "Extracted entities (JSONL output):"
echo "--------------------------------"
cat output.jsonl
echo ""

# Display in a more readable format
echo "Formatted view of extracted entities:"
echo "--------------------------------"
cat output.jsonl | python format_output.py