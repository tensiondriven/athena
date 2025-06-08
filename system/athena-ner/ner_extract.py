#!/usr/bin/env python3

import sys
import json
from transformers import AutoTokenizer, AutoModelForTokenClassification, pipeline

def extract_entities(text):
    """Extract named entities from text using BERT."""
    # Load model and tokenizer
    tokenizer = AutoTokenizer.from_pretrained("dslim/bert-base-NER")
    model = AutoModelForTokenClassification.from_pretrained("dslim/bert-base-NER")
    
    # Create NER pipeline
    ner_pipeline = pipeline("ner", model=model, tokenizer=tokenizer, aggregation_strategy="simple")
    
    # Get entities
    entities_raw = ner_pipeline(text)
    
    # Convert to desired format
    entities = []
    for ent in entities_raw:
        entities.append({
            "text": ent["word"],
            "start": ent["start"],
            "end": ent["end"],
            "label": ent["entity_group"]
        })
    
    return entities

def main():
    """Process text input line by line and output entities in JSONL format."""
    # Initialize the model once to avoid reloading for each line
    tokenizer = AutoTokenizer.from_pretrained("dslim/bert-base-NER")
    model = AutoModelForTokenClassification.from_pretrained("dslim/bert-base-NER")
    ner_pipeline = pipeline("ner", model=model, tokenizer=tokenizer, aggregation_strategy="simple")
    
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        
        # Get entities using the pipeline
        entities_raw = ner_pipeline(line)
        
        # Convert to desired format
        entities = []
        for ent in entities_raw:
            entities.append({
                "text": ent["word"],
                "start": ent["start"],
                "end": ent["end"],
                "label": ent["entity_group"]
            })
        
        result = {
            "text": line,
            "entities": entities
        }
        
        print(json.dumps(result))

if __name__ == "__main__":
    main()