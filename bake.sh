function main () {
  dockerCheck
  init
  cd /tmp/lilship
  muxAdmin k3d registry create lilshiplocalregistry.localhost --port 8083 
  k3d cluster create --api-port 8082 lilship --kubeconfig-update-default=true --registry-use k3d-lilshiplocalregistry.localhost:8083 
  muxAdmin docker run --network host -e KUBECONFIG=/tmp/lilship/kubeconfig --rm --name kubectl -v /tmp/lilship:/tmp/lilship  dtzar/helm-kubectl:3.5.2 kubectl get pods 
  muxAdmin docker run -v /tmp/lilship:/tmp/lilship -w /tmp/lilship --rm alpine/git clone https://github.com/alpine-docker/git.git 

  
  # to push to local
  #docker pull nginx:latest
  #docker tag nginx:latest  k3d-lilshiplocalregistry.localhost:8083/nginx:latest
  #docker push  k3d-lilshiplocalregistry.localhost:8083/nginx:latest
}


function init () {
  rm -rf /tmp/lilship
  mkdir -p /tmp/lilship
  docker run -w /tmp/lilship -e KUBECONFIG=/tmp/lilship/kubeconfig -d -p 8081:8080 --name lilship-k3d-webmux -it -v /tmp/lilship:/tmp/lilship -v /var/run/docker.sock:/var/run/docker.sock --privileged  brokorus/lilship:1.1-k3dind-webmux
}


function muxAdmin () {
	docker exec -w /tmp/lilship lilship-k3d-webmux $@
}

function installPuppetServer () {
	echo 'hello'
}

function dockerCheck () {
  echo 'Making sure docker is installed'
  if docker images > /dev/null; then
    echo "Docker is installed"
    else
    echo "Please install and or start Docker to run this demo"
  fi

}

main 
