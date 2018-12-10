#!/bin/bash
set -o errexit

main() {
    case $1 in
        "prepare")
            docker_prepare
            ;;
        "build")
            docker_build
            ;;
        "test")
            docker_test
            ;;
        "tag")
            docker_tag
            ;;
        "push")
            docker_push
            ;;
        "manifest-list")
            docker_manifest_list
            ;;
        *)
            echo "none of above!"
    esac
}

docker_prepare() {
    # Prepare the machine before any code installation scripts
    setup_dependencies

    # Update docker configuration to enable docker manifest command
    update_docker_configuration

    # Start qemu
    docker run --rm --privileged multiarch/qemu-user-static:register --reset
}

docker_build() {
    echo "DOCKER BUILD: Build all docker images."

	docker build --tag ${DOCKER_REPO}:${BUILD_VERSION}-arm32v7 --build-arg BUILD_REF=${TRAVIS_COMMIT} --build-arg BUILD_ARCH=arm32v7 --build-arg BUILD_DATE=$(date +"%Y-%m-%dT%H:%M:%SZ") --build-arg BUILD_VERSION=${BUILD_VERSION} --build-arg QEMU_ARCH=hypriot/qemu-register .
	
	docker build --tag ${DOCKER_REPO}:${BUILD_VERSION}-amd64 --build-arg BUILD_REF=${TRAVIS_COMMIT} --build-arg BUILD_ARCH=amd64 --build-arg BUILD_DATE=$(date +"%Y-%m-%dT%H:%M:%SZ") --build-arg BUILD_VERSION=${BUILD_VERSION} --build-arg QEMU_ARCH=hypriot/qemu-register .
	
	
}

docker_test() {
    echo "DOCKER TEST: Test all docker images."
    docker run -d --rm --name=test-amd64 ${DOCKER_REPO}:${BUILD_VERSION}-amd64
    if [ $? -ne 0 ]; then
       echo "DOCKER TEST: FAILED - Docker container failed to start amd64."
       exit 1
    else
       echo "DOCKER TEST: PASSED - Docker container succeeded to start amd64."
    fi

    docker run -d --rm --name=test-arm32v7 ${DOCKER_REPO}:${BUILD_VERSION}-arm32v7
    if [ $? -ne 0 ]; then
       echo "DOCKER TEST: FAILED - Docker container failed to start arm32v7."
       exit 1
    else
       echo "DOCKER TEST: PASSED - Docker container succeeded to start arm32v7."
    fi
}

docker_tag() {
    echo "DOCKER TAG: Tag all docker images."
    docker tag ${DOCKER_REPO}:${BUILD_VERSION}-amd64 ${DOCKER_REPO}:${BUILD_VERSION}-amd64
    docker tag ${DOCKER_REPO}:${BUILD_VERSION}-arm32v7 ${DOCKER_REPO}:${BUILD_VERSION}-arm32v7
}

docker_push() {
    echo "DOCKER PUSH: Push all docker images."
    docker push ${DOCKER_REPO}:${BUILD_VERSION}-amd64
    docker push ${DOCKER_REPO}:${BUILD_VERSION}-arm32v7
}

docker_manifest_list() {
    # Create and push manifest lists, displayed as FIFO
    echo "DOCKER MANIFEST: Create and Push docker manifest lists."
    docker_manifest_list_version
    # if build is not a beta then create and push manifest lastest
    if [[ ${BUILD_VERSION} != *"RC"* ]]; then
        echo "DOCKER MANIFEST: Create and Push docker manifest lists LATEST."
        docker_manifest_list_latest
	else
        echo "DOCKER MANIFEST: Create and Push docker manifest lists BETA."
        docker_manifest_list_beta
    fi
    docker_manifest_list_version_os_arch
}

docker_manifest_list_version() {
  # Manifest Create BUILD_VERSION
  echo "DOCKER MANIFEST: Create and Push docker manifest list - $DOCKER_REPO:$BUILD_VERSION."
  docker manifest create ${DOCKER_REPO}:${BUILD_VERSION} \
      ${DOCKER_REPO}:${BUILD_VERSION}-amd64 \
      ${DOCKER_REPO}:${BUILD_VERSION}-arm32v7
	  
  # Manifest Annotate BUILD_VERSION
  docker manifest annotate "$DOCKER_REPO:$BUILD_VERSION" "$DOCKER_REPO:$BUILD_VERSION-arm32v7" --os linux --arch arm --variant v6

  # Manifest Push BUILD_VERSION
  docker manifest push $DOCKER_REPO:$BUILD_VERSION
}

docker_manifest_list_latest() {
  # Manifest Create latest
  echo "DOCKER MANIFEST: Create and Push docker manifest list - $DOCKER_REPO:latest."
  docker manifest create $DOCKER_REPO:latest \
      $DOCKER_REPO:$BUILD_VERSION-amd64 \
      $DOCKER_REPO:$BUILD_VERSION-arm32v7

  # Manifest Annotate BUILD_VERSION
  docker manifest annotate $DOCKER_REPO:latest $DOCKER_REPO:$BUILD_VERSION-arm32v7 --os linux --arch arm --variant v6

  # Manifest Push BUILD_VERSION
  docker manifest push $DOCKER_REPO:latest
}


docker_manifest_list_beta() {
  # Manifest Create latest
  echo "DOCKER MANIFEST: Create and Push docker manifest list - $DOCKER_REPO:beta."
  docker manifest create $DOCKER_REPO:beta \
      $DOCKER_REPO:$BUILD_VERSION-amd64 \
      $DOCKER_REPO:$BUILD_VERSION-arm32v7

  # Manifest Annotate BUILD_VERSION
  docker manifest annotate $DOCKER_REPO:beta $DOCKER_REPO:$BUILD_VERSION-arm32v7 --os linux --arch arm --variant v6

  # Manifest Push BUILD_VERSION
  docker manifest push $DOCKER_REPO:beta
}

docker_manifest_list_version_os_arch() {
  # Manifest Create amd64
  echo "DOCKER MANIFEST: Create and Push docker manifest list - $DOCKER_REPO:$BUILD_VERSION-amd64."
  docker manifest create $DOCKER_REPO:$BUILD_VERSION-amd64 \
      $DOCKER_REPO:$BUILD_VERSION-amd64

  # Manifest Push amd64
  docker manifest push $DOCKER_REPO:$BUILD_VERSION-amd64

  # Manifest Create arm32v7
  echo "DOCKER MANIFEST: Create and Push docker manifest list - $DOCKER_REPO:$BUILD_VERSION-arm32v7."
  docker manifest create $DOCKER_REPO:$BUILD_VERSION-arm32v7 \
      $DOCKER_REPO:$BUILD_VERSION-arm32v7

  # Manifest Annotate arm32v7
  docker manifest annotate $DOCKER_REPO:$BUILD_VERSION-arm32v7 $DOCKER_REPO:$BUILD_VERSION-arm32v7 --os=linux --arch=arm --variant=v6

  # Manifest Push arm32v7
  docker manifest push $DOCKER_REPO:$BUILD_VERSION-arm32v7

}

setup_dependencies() {
  echo "PREPARE: Setting up dependencies."

  sudo apt update -y
  # sudo apt install realpath python python-pip -y
  #sudo apt install --only-upgrade docker-ce -y
  sudo apt-get install docker-ce=18.02.0~ce-0~ubuntu
  # sudo pip install docker-compose || true

  docker info
  # docker-compose --version
}

update_docker_configuration() {
  echo "PREPARE: Updating docker configuration"

  mkdir $HOME/.docker

  # enable experimental to use docker manifest command
  echo '{
    "experimental": "enabled"
  }' | tee $HOME/.docker/config.json

  # enable experimental
  echo '{
    "experimental": true,
    "max-concurrent-downloads": 100,
    "max-concurrent-uploads": 100
  }' | sudo tee /etc/docker/daemon.json

  sudo service docker restart
}

main $1
