REGISTRY_URI="$1"

docker pull octopusdeploy/octopusdeploy:latest
docker pull nginx:1.27.3
docker image tag octopusdeploy/octopusdeploy:latest $REGISTRY_URI/octopusdeploy/octopusdeploy:latest
docker image tag nginx:1.27.3 $REGISTRY_URI/nginx/nginx:1.27.3
az acr login --name $REGISTRY_URI
docker push $REGISTRY_URI/octopusdeploy/octopusdeploy:latest
docker push $REGISTRY_URI/nginx/nginx:1.27.3