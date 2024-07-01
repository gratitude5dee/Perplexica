#!/bin/bash

# Script to upload files to Vercel API

# Vercel API endpoint for file uploads
VERCEL_API="https://api.vercel.com/v2/files"
VERCEL_TOKEN="${vercel_vercel_access_token}"

# Function to upload a file
upload_file() {
  local file_path=$1
  local file_name=$(basename "$file_path")
  local file_digest=$(sha1sum "$file_path" | awk '{print $1}')
  local file_size=$(stat -c%s "$file_path")

  # Upload file content
  file_upload_response=$(curl -X POST "$VERCEL_API" \
    -H "Authorization: Bearer $VERCEL_TOKEN" \
    -H "Content-Length: $file_size" \
    -H "x-now-digest: $file_digest" \
    -H "x-vercel-digest: $file_digest" \
    --data-binary @"$file_path")

  # Check if file upload was successful
  if echo "$file_upload_response" | grep -q '"error"'; then
    echo "Error uploading file: $file_name"
    echo "$file_upload_response"
    return 1
  fi

  # Collect file digest and name for deployment
  if [ -s /tmp/file_digests.json ]; then
    echo "," >> /tmp/file_digests.json
  fi
  echo "{\"digest\": \"$file_digest\", \"name\": \"$file_name\"}" >> /tmp/file_digests.json
}

# Initialize the file digests JSON array
echo "[" > /tmp/file_digests.json

# Find and upload all relevant files
first_file=true
find . -type f ! -path "./.git/*" ! -path "./node_modules/*" ! -path "./.vercel/*" | while read -r file; do
  if [ "$first_file" = true ]; then
    first_file=false
  else
    echo "," >> /tmp/file_digests.json
  fi
  upload_file "$file"
done

# Close the JSON array
echo "]" >> /tmp/file_digests.json

# Create deployment with file digests
curl -X POST "https://api.vercel.com/v13/deployments" \
  -H "Authorization: Bearer $VERCEL_TOKEN" \
  -H "Content-Type: application/json" \
  -d @/tmp/file_digests.json
