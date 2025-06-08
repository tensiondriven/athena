#!/usr/bin/env python3

"""
Example of fine-tuning BERT for custom entity types.
This script shows how to prepare data for fine-tuning.
"""

import json
from transformers import AutoTokenizer

# Example of what labeled data would look like
sample_data = [
    {
        "text": "Apple CEO Tim Cook announced a new iPhone today in Cupertino, California.",
        "entities": [
            {"text": "Apple", "start": 0, "end": 5, "label": "COMPANY"},
            {"text": "Tim Cook", "start": 10, "end": 18, "label": "CEO"},
            {"text": "iPhone", "start": 35, "end": 41, "label": "PRODUCT"},
            {"text": "Cupertino", "start": 51, "end": 60, "label": "CITY"},
            {"text": "California", "start": 62, "end": 72, "label": "STATE"}
        ]
    }
]

# Define custom entity types
ENTITY_TYPES = ["O", "B-COMPANY", "I-COMPANY", "B-CEO", "I-CEO", "B-PRODUCT", "I-PRODUCT", 
                "B-CITY", "I-CITY", "B-STATE", "I-STATE"]

def convert_to_training_format(data):
    """
    Convert labeled data to the BIO format required for BERT fine-tuning.
    Returns examples in the format needed for the transformers library.
    """
    tokenizer = AutoTokenizer.from_pretrained("bert-base-cased")
    training_examples = []
    
    for item in data:
        text = item["text"]
        entities = item["entities"]
        
        # Sort entities by start position
        entities = sorted(entities, key=lambda x: x["start"])
        
        # Tokenize text
        tokens = []
        word_ids = []
        current_word_idx = 0
        
        # Convert to word-level tokens first
        words = text.split()
        position = 0
        word_positions = []
        
        for word in words:
            word_positions.append((position, position + len(word)))
            position += len(word) + 1  # +1 for the space
        
        # Tokenize each word
        tokenized_inputs = tokenizer(text, return_offsets_mapping=True, return_tensors="pt")
        input_ids = tokenized_inputs["input_ids"][0]
        offset_mapping = tokenized_inputs["offset_mapping"][0]
        
        # Initialize labels with "O" for Outside
        labels = ["O"] * len(input_ids)
        
        # Assign entity labels
        for entity in entities:
            entity_start = entity["start"]
            entity_end = entity["end"]
            entity_type = entity["label"]
            
            # Find tokens that correspond to this entity
            for i, (token_start, token_end) in enumerate(offset_mapping):
                token_start = token_start.item()
                token_end = token_end.item()
                
                # Skip special tokens
                if token_start == 0 and token_end == 0:
                    continue
                
                # Check if token is part of the entity
                if token_start >= entity_start and token_end <= entity_end:
                    # First token of entity gets B- prefix
                    if token_start == entity_start:
                        labels[i] = f"B-{entity_type}"
                    else:
                        labels[i] = f"I-{entity_type}"
        
        # Remove label for special tokens [CLS] and [SEP]
        labels[0] = -100
        labels[-1] = -100
        
        training_examples.append({
            "input_ids": input_ids.tolist(),
            "labels": labels,
            "tokens": tokenizer.convert_ids_to_tokens(input_ids)
        })
    
    return training_examples

# Show example of converted data
print("Example of training data format for custom entities:")
examples = convert_to_training_format(sample_data)
print(json.dumps(examples[0], indent=2))

print("\nTo fine-tune a model with these custom entity types:")
print("1. Create a dataset with many labeled examples")
print("2. Use the Hugging Face Trainer with the TokenClassificationPipeline")
print("3. Train with a command like:")
print("   python run_ner.py --model_name_or_path bert-base-cased --train_file train.json --validation_file valid.json --output_dir ./custom-ner-model --do_train --do_eval")