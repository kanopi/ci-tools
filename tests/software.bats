#!/usr/bin/env bats

# Docker Image to Build Container
CONTAINER_NAME=app

# User to run commands as
CONTAINER_USER=circleci

# Following Tests are used to confirm software is installed.

# Runs at the beginning of every test.
setup () {
  docker run -d --rm -p 80:80 -p 443:443 --volumes-from=project-root -e APACHE_DOCUMENTROOT=/var/www/project --name=${CONTAINER_NAME} ${IMAGE_NAME}
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

@test "Composer Installed" {
  [[ $SKIP == 1 ]] && skip

  run docker exec -i -u ${CONTAINER_USER} ${CONTAINER_NAME} bash -lc 'composer --version'
  [[ "$status" -eq 0 ]]
  # TODO: Add in check to make sure coding standards are loaded.

  unset output
}

@test "PHPCS Installed" {
  [[ $SKIP == 1 ]] && skip

  run docker exec -i -u ${CONTAINER_USER} ${CONTAINER_NAME} bash -lc 'phpcs -i'
  [[ "$status" -eq 0 ]]
  # TODO: Add in check to make sure coding standards are loaded.

  unset output
}

@test "Drush Installed" {
  [[ $SKIP == 1 ]] && skip

  run docker exec -i -u ${CONTAINER_USER} ${CONTAINER_NAME} bash -lc 'drush --version'
  [[ "$status" -eq 0 ]] &&
  [[ "$output" =~ "Drush Launcher Version" ]] &&
  [[ "$output" =~ "Drush Version" ]]
  unset output
}
