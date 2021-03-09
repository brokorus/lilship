function main () {
  dockerCheck
  init
  createCluster
  getLilShip
  localizeGit
  installPuppetServer
  giveInfo

  
  # to push to local
  #docker pull nginx:latest
  #docker tag nginx:latest  k3d-lilshiplocalregistry.localhost:8083/nginx:latest
  #docker push  k3d-lilshiplocalregistry.localhost:8083/nginx:latest
}


function init () {
  rm -rf /tmp/lilship
  mkdir -p /tmp/lilship
  docker run --network host -w /tmp/lilship -e KUBECONFIG=/tmp/lilship/kubeconfig -d -p 8081:8080 --name lilship-k3d-webmux -it -v /tmp/lilship:/tmp/lilship -v /var/run/docker.sock:/var/run/docker.sock --privileged  brokorus/lilship:1.1-k3dind-webmux
}

function lilAdmin () {
  docker exec -w /tmp/lilship lilship-k3d-webmux $@
}

function getPodName () {
	lilKube kubectl get pods --namespace default -l "app.kubernetes.io/name=$1,app.kubernetes.io/instance=$1" -o jsonpath="{.items[0].metadata.name}"
}

function getLilShip () {
  #docker run --network host -w /tmp/lilship --rm -v /tmp/lilship:/tmp/lilship --name lilgitserver -d -p 2222:22 arvindr226/alpine-ssh
  lilGit clone https://github.com/brokorus/lilship.git
  lilGit clone https://github.com/brokorus/demo-control-repo.git
  docker exec -w /tmp/lilship lilship-k3d-webmux ssh-keygen -f /tmp/lilship/id_rsa -t rsa -N ''
  lilKube kubectl apply -f /tmp/lilship/lilship/k8s/lilgit.yaml -w
  PODNAME="$(getPodName lilgitserver)"
  ID_RSA="$(lilKube kubectl exec $PODNAME cat /tmp/lilship/id_rsa  | base64)"
  KNOWN_HOSTS="$(lilKube kubectl exec $PODNAME ssh-keyscan -p 22 -H lilgitserver | base64)"
  AUTHORISED_KEYS="$(lilAdmin cat /tmp/lilship/id_rsa.pub)"

  lilKube kubectl create secret generic gitssh --from-literal=id_rsa=$ID_RSA --from-literal=known_hosts=$KNOWN_HOSTS --from-literal=authorized_keys=$AUTHORISED_KEYS
  lilKube exec $PODNAME cp /tmp/lilship/id_rsa.pub /home/git/.ssh/authorized_keys
  lilKube exec $PODNAME chown -R git:git /tmp/lilship/id_rsa.pub 
}

function lilGit  () {
  lilAdmin docker run -v /tmp/lilship:/tmp/lilship -w /tmp/lilship --rm alpine/git $@
}

function localizeGit () {
  lilAdmin rm -rf /tmp/lilship/demo-control-repo/.git*
  lilGit init
  lilGit config --global user.email "lilship@lilship.com"
  lilGit config --global user.name "Little Ship"
  lilGit add -A
  lilGit commit -m 'Initial'
  lilGit remote add origin ssh://root@lilgitserver:22/tmp/lilship/demo-control-repo.git
}

function createCluster () {
  lilAdmin k3d registry create lilshiplocalregistry.localhost --port 8083 
  lilAdmin k3d cluster create -p "8089:80@loadbalancer" --agents 2 --volume /tmp/lilship:/tmp/lilship --api-port 8082 lilship --kubeconfig-update-default=true --registry-use k3d-lilshiplocalregistry.localhost:8083 
}

function lilKube () {
  lilAdmin docker run --network host -w /tmp/lilship -e KUBECONFIG=/tmp/lilship/kubeconfig --rm --name kubectl -v /tmp/lilship:/tmp/lilship  dtzar/helm-kubectl:3.5.2 $@
}

function installPuppetServer () {
  lilKube kubectl create secret generic lilconfig --from-file=/tmp/lilship/kubeconfig
  lilKube kubectl apply -f /tmp/lilship/lilship/k8s/puppetserver.yaml

}

function giveInfo () {
    echo '################################################################'
    echo 'Please open your browser to http://localhost:8081/'
    echo '################################################################'
    echo 'New ttys can be made by visiting http://localhost:8081 in a new tab or window'
    echo '################################################################'
    echo 'Be sure to export your localkubeconfig by running export KUBECONFIG=/tmp/lilship/kubeconfig'
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