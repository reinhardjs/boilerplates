## Using local registry:

```
sudo docker run -d \
  -p 5000:5000 \
  --name registry \
  --restart unless-stopped \
  -e REGISTRY_HTTP_SECRET=secret-key \
  -v /mnt/data/registry/data:/var/lib/registry \
  registry:2.7
```

## Authenticating to local registry:

```
# Basic login
docker login localhost:5000 -u username -p password

# Or using token (if using token authentication)
docker login localhost:5000 -u _ --password-stdin <<< "your_token"
```

## how to push to local registry

```
# Tag image
docker tag my-web localhost:5000/my-web

# Then push to local registry
docker push localhost:5000/my-web
```

## how to pull from local registry

```
sudo docker pull localhost:5000/my-web:latest

sudo docker tag localhost:5000/my-web:latest my-web:latest

sudo docker rmi localhost:5000/my-web:latest
```

## How to see registry resources

```
# List all repositories
curl -X GET http://localhost:5000/v2/_catalog

# List tags for specific image
curl -X GET http://localhost:5000/v2/my-web-api/tags/list

# Pretty print JSON output
curl -s http://localhost:5000/v2/_catalog | jq '.'
```
