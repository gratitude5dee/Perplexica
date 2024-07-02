#!/bin/bash

# Read the JSON array from the file
json_array=$(cat /tmp/file_digests.json)

# Remove leading commas
json_array=$(echo "$json_array" | sed 's/^\[,\[/\[/')

# Remove extraneous commas and rebuild the JSON array
corrected_json_array=$(echo "$json_array" | jq -c 'map(select(.digest != null and .name != null))')

# Ensure the JSON array starts with an opening bracket and ends with a closing bracket
corrected_json_array=$(echo "$corrected_json_array" | sed 's/^\[,\[/\[/; s/,\]$/\]/')

# Overwrite the existing file with the corrected JSON data
echo "$corrected_json_array" > /tmp/file_digests.json
