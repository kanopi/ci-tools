#!/usr/bin/env bats

# Following Tests are used to confirm software is installed.

# Runs at the beginning of every test.
setup () {
  docker run -d --rm -p 80:80 -p 443:443 --volumes-from=project-root -e APACHE_DOCUMENTROOT=/var/www/project --name=${CONTAINER_NAME} ${DOCKER_IMAGE_NAME}
}

# Runs at the end of every test.
teardown() {
  docker rm -f ${CONTAINER_NAME}
  echo "Status: $status"
  echo "Output:"
  echo "================================================================"
  for line in "${lines[@]}"; do
    echo $line
  done
  echo "================================================================"
}
