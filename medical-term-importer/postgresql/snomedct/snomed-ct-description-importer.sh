#!/bin/bash

# Set up variables for PostgreSQL connection
DB_HOST="localhost"
DB_PORT="5438"
DB_NAME="db4"
DB_USER="postgres"
DB_PASSWORD="password"

# Set up variables for SNOMED CT import
FOLDER="release"
TYPE="Full"
RELEASE="GermanyEdition_20240515"
SUFFIX="_f"

# Construct the file path
FILE_PATH="$FOLDER/$TYPE/Terminology/sct2_Description_${TYPE}_${RELEASE}.txt"

# Ensure the SNOMED CT file exists
if [ ! -f "$FILE_PATH" ]; then
  echo "SNOMED CT file '$FILE_PATH' not found!"
  exit 1
fi

# Export password for PostgreSQL session
export PGPASSWORD=$DB_PASSWORD

# Execute the SQL commands with adjusted memory parameters
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" <<EOF
BEGIN;
TRUNCATE TABLE description${SUFFIX};
\copy description${SUFFIX}(id, effectivetime, active, moduleid, conceptid, languagecode, typeid, term, casesignificanceid) FROM '$FILE_PATH' WITH (FORMAT csv, HEADER true, DELIMITER E'\t', QUOTE E'\b', ENCODING 'utf-8');
COMMIT;
EOF

# Check if the SQL execution was successful
if [ $? -eq 0 ]; then
  echo "SNOMED CT data imported successfully!"
else
  echo "There was an error importing the SNOMED CT data."
  exit 1
fi

# Unset the password variable for security
unset PGPASSWORD
