docker build -t my-web .

sudo docker run -d --name my-web -p 127.0.0.1:3000:3000 --restart unless-stopped my-web


-----------------------------------------------------------------------------------------------


docker build -t my-web-api .

docker run -d --name my-web-api -p 127.0.0.1:8080:8080 --restart unless-stopped my-web-api


-----------------------------------------------------------------------------------------------


docker update --memory 128m --memory-swap 512m <container_id_or_name>
