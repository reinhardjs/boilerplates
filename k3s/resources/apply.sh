#!/bin/bash

# Apply all YAML files in the current directory
for file in *.yaml; do
  kubectl apply -f "$file"
done
