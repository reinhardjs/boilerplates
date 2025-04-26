# API Authentication Request

```
curl --location 'https://api-zimozi.reinhardjs.my.id/api/users/login' \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "name": "Admin User",
    "email": "admin@example.com",
    "password": "password123",
    "role": "admin"
  }' \
  --silent --output /dev/null \
  --write-out $'\
time_namelookup:  %{time_namelookup}s\
\
time_connect:     %{time_connect}s\
\
time_appconnect:  %{time_appconnect}s\
\
time_starttransfer: %{time_starttransfer}s\
\
time_total:       %{time_total}s\
'
```