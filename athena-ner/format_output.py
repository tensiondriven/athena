#!/usr/bin/env python3

import json
import sys

for line in sys.stdin:
    data = json.loads(line)
    print(f"TEXT: {data['text']}")
    for entity in data["entities"]:
        print(f"  • {entity['label']}: {entity['text']}")
    print("")