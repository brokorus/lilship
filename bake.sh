function main () {
  dockerCheck
  init
  cd /tmp/lilship
  lilAdmin k3d registry create lilshiplocalregistry.localhost --port 8083 
  k3d cluster create --api-port 8082 lilship --kubeconfig-update-default=true --registry-use k3d-lilshiplocalregistry.localhost:8083 
  installPuppetServer

  
  # to push to local
  #docker pull nginx:latest
  #docker tag nginx:latest  k3d-lilshiplocalregistry.localhost:8083/nginx:latest
  #docker push  k3d-lilshiplocalregistry.localhost:8083/nginx:latest
}


function init () {
  docker kill k3d-lilship-server-0
  docker kill k3d-lilship-serverlb
  docker kill k3d-lilshiplocalregistry.localhost
  docker rm k3d-lilship-server-0
  docker rm k3d-lilship-serverlb
  docker rm k3d-lilshiplocalregistry.localhost
  rm -rf /tmp/lilship
  mkdir -p /tmp/lilship
  if docker run -w /tmp/lilship -e KUBECONFIG=/tmp/lilship/kubeconfig -d -p 8081:8080 --name lilship-k3d-webmux -it -v /tmp/lilship:/tmp/lilship -v /var/run/docker.sock:/var/run/docker.sock --privileged  brokorus/lilship:1.1-k3dind-webmux
    docker exec -it lilship-k3d-webmux tmux new -s lilshipbuilder -d
    docker exec -i lilship-k3d-webmux  tmux send-keys -t lilshipbuilder "tmux split-window -h" ENTER
    docker exec -i lilship-k3d-webmux  tmux send-keys -t lilshipbuilder.1 "curl https://raw.githubusercontent.com/brokorus/lilship/main/bake.sh | bash" ENTER
    echo 'Please open your browser to http://localhost:8081/\?arg\=a\&arg\=-t\&arg\=lilshipbuilder'
    echo 'New ttys can be made by visiting http://localhost:8081 in a new tab or window'
    exit
  else
    echo 'already running'
  fi
}

function lilAdmin () {
  docker exec -w /tmp/lilship lilship-k3d-webmux $@
}

function lilKube () {
  lilAdmin docker run --network host -e KUBECONFIG=/tmp/lilship/kubeconfig --rm --name kubectl -w /tmp/lilship:/tmp/lilship -v /tmp/lilship:/tmp/lilship  dtzar/helm-kubectl:3.5.2 $@
}


function lilGit () {
  lilAdmin docker run -v /tmp/lilship:/tmp/lilship -w /tmp/lilship --rm alpine/git $@
}

function installPuppetServer () {
  lilKube helm install puppetserver ./charts/puppetserver-helm-chart
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
