#!/bin/bash

for file in init/*.yaml; do
  kubectl apply -f "$file"
done

# Apply all YAML files in the current directory
for file in *.yaml; do
  kubectl apply -f "$file"
done
