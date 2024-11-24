
#!/bin/bash

# find ~/Downloads/db/ -name "*.sql" -exec /opt/homebrew/opt/libpq/bin/psql -d postgres://postgres:password@127.0.0.1:5432/ -f {} \;

## Reference https://tembo.io/docs/getting-started/postgres_guides/how-to-backup-and-restore-a-postgres-database

databases="
  db-name-1
  db-name-2
"

source_conn="postgresql://source-username:source-password@77.77.77.77:5432"
destination_conn="postgres://postgres:password@localhost:5432"

# Loop over each database
for db in $databases; do
  echo "Processing $db..."
  
  # Dump the database
  pg_dump "$source_conn/$db" > "$db.sql"
  
  # Drop and recreate the public schema in the destination database
  psql "$destination_conn/$db" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
  
  # Restore the database
  psql "$destination_conn/$db" -f "$db.sql"
  
  echo "$db processed successfully."
done

# Clean up
# rm backup_file.sql
