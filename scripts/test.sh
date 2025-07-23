#!/bin/bash

# Build policies.txt
find tests/policies -type f -name '*.yaml' -exec basename {} \; > policies.txt

export existing_policy="policies.txt"
export repo="dummy"
export token="dummy"

for file in tests/requests/*.yaml tests/policies/*.yaml; do
    export filename="$file"
    echo "🔍 Running test on: $file"
    python3 validate_duplicates.py
    echo "--------------------------------------------------"
done
