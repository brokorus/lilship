function main () {
  dockerCheck
  init
  lilGit clone https://github.com/brokorus/lilship.git
  createCluster
  installPuppetServer
  giveInfo

  
  # to push to local
  #docker pull nginx:latest
  #docker tag nginx:latest  k3d-lilshiplocalregistry.localhost:8083/nginx:latest
  #docker push  k3d-lilshiplocalregistry.localhost:8083/nginx:latest
}


function init () {
  docker kill k3d-lilship-server-0
  docker kill k3d-lilship-serverlb
  docker kill k3d-lilshiplocalregistry.localhost
  docker kill lilship-k3d-webmux
  docker rm lilship-k3d-webmux
  docker rm k3d-lilship-server-0
  docker rm k3d-lilship-serverlb
  docker rm k3d-lilshiplocalregistry.localhost
  rm -rf /tmp/lilship
  mkdir -p /tmp/lilship
  docker run -w /tmp/lilship -e KUBECONFIG=/tmp/lilship/kubeconfig -d -p 8081:8080 --name lilship-k3d-webmux -it -v /tmp/lilship:/tmp/lilship -v /var/run/docker.sock:/var/run/docker.sock --privileged  brokorus/lilship:1.1-k3dind-webmux
}

function lilAdmin () {
  docker exec -w /tmp/lilship lilship-k3d-webmux $@
}

function createCluster () {
  lilAdmin k3d registry create lilshiplocalregistry.localhost --port 8083 
  lilAdmin k3d cluster create --api-port 8082 lilship --kubeconfig-update-default=true --registry-use k3d-lilshiplocalregistry.localhost:8083 
}

function lilKube () {
  lilAdmin docker run --network host -w /tmp/lilship -e KUBECONFIG=/tmp/lilship/kubeconfig --rm --name kubectl -v /tmp/lilship:/tmp/lilship  dtzar/helm-kubectl:3.5.2 $@
}

function lilGit () {
  lilAdmin docker run -v /tmp/lilship:/tmp/lilship -w /tmp/lilship --rm alpine/git $@
}

function installPuppetServer () {
  lilKube kubectl create secret generic lilconfig --from-file=/tmp/lilship/kubeconfig
#  lilKube helm repo add puppet https://puppetlabs.github.io/puppetserver-helm-chart
  lilKube helm install puppetserver /tmp/lilcharts/lilcharts/charts/puppetserver-helm-chart --set puppetserver.puppeturl='https://github.com/brokorus/demo-control-repo.git'

}

function giveInfo () {
    echo 'Please open your browser to http://localhost:8081/\?arg\=a\&arg\=-t\&arg\=lilshipbuilder'
    echo 'New ttys can be made by visiting http://localhost:8081 in a new tab or window'
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

