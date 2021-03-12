#!/bin/bash

if [[ $(which docker) && $(docker --version) ]]; then
    echo "Docker is already installed"
  else
    echo "Installing docker"
    curl -fsSL https://get.docker.com | bash
fi

if [  "$#" -ne 0 ]  &&  [ "$#" -eq 1 ]  &&  [ "$1" -gt 1 ] && [ "$1" -lt  65353  ]
then
    echo "Using port $1"
    port=$1
else 
    cat <<EOF
    USAGE: 
    ./pupchallenge.sh <port_number>

    EXAMPLE: 
    ./pupchallenge.sh 80 

    OR

    USAGE: 
    curl https://raw.github.com/brokorus/lilship/main/pupchallenge.sh | bash -s <port_number>

    EXAMPLE: 
    curl https://raw.github.com/brokorus/lilship/main/pupchallenge.sh | bash -s 80

    Port must be between 2 and 65353
    Only 1 argument provided as an integer is accepted
    #########

    Defaulting to port 80
EOF
port=80
fi

if [ ! -f dockerfile.pupchallenge ]; then
    echo "No local dockerfile found"
    cat <<-EOF > dockerfile.pupchallenge
      FROM httpd:2.4
      RUN rm -rf /usr/local/apache2/htdocs/* && \
        echo "Hello World" > /usr/local/apache2/htdocs/index.html
      EXPOSE 80
EOF
fi

image_and_tag="pupchallenge/simpleapache:latest"
image_and_tag_array=(${image_and_tag//:/ })
if [[ "$(docker images ${image_and_tag_array[0]} | grep ${image_and_tag_array[1]} 2> /dev/null)" != "" ]]; then
  echo 'image already exists'
else
  docker build -t pupchallenge/simpleapache:latest -f dockerfile.pupchallenge  .
fi


if docker container port pupchallenge &> /dev/null ;
then 
old_port="$(docker container port pupchallenge | sed 's|^.*:||' )" &> /dev/null
else
       echo 'Creating container'
       docker run -d --name pupchallenge -p $port:80 pupchallenge/simpleapache:latest
       echo "Running curl localhost:$port"
       echo 'GOT'
       sleep 2
       curl "localhost:$port"
       exit 0
fi


echo "old port is $old_port"
echo "new port is $port"
if [[ $port -eq $old_port ]] 
  then
    echo 'No change to port detected' 
    echo 'Running curl localhost:$port'
    echo 'GOT'
       sleep 2
    curl localhost:$port
    exit 0
  else
    echo 'Port change detected' 
    if $(docker inspect --format '{{json .State.Running}}' pupchallenge); then 
       docker kill pupchallenge > /dev/null 2>&1
       docker container rm pupchallenge > /dev/null 2>&1
       docker run -d --name pupchallenge -p $port:80 pupchallenge/simpleapache:latest
       echo 'Running curl localhost:$port'
       echo 'GOT'
       sleep 2
       curl localhost:$port
    else
       docker run -d --name pupchallenge -p $port:80 pupchallenge/simpleapache:latest
       echo 'Running curl localhost:$port'
       echo 'GOT'
       sleep 2
       curl localhost:$port
    fi 
fi



