docker build -t my-web .

sudo docker run -d --name my-web -p 127.0.0.1:3000:3000 --restart unless-stopped my-web


-----------------------------------------------------------------------------------------------


docker build -t my-web-api .

docker run -d --name my-web-api -p 127.0.0.1:8080:8080 --restart unless-stopped my-web-api


-----------------------------------------------------------------------------------------------


docker update --memory 128m --memory-swap 512m <container_id_or_name>


-----------------------------------------------------------------------------------------------


using local registry:

sudo docker run -d \
  -p 5000:5000 \
  --name registry \
  --restart unless-stopped \
  -e REGISTRY_HTTP_SECRET=secret-key \
  -v /mnt/data/registry/data:/var/lib/registry \
  registry:2.7
