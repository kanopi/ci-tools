#!/usr/bin/env bats

# Docker Image to Build Container
IMG=app

# Following Tests are used to confirm software is installed.

setup () {
  docker run -d --rm -p 80:80 -p 443:443 --volumes-from=project-root -e APACHE_DOCUMENTROOT=/var/www/project --name=$IMG $IMAGE_NAME
}

# Debugging
teardown() {
  docker rm -f $IMG
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

  run docker exec -it ${IMG} bash -l -c ''
  [[ "$status" -eq 0 ]]
  # TODO: Add in check to make sure coding standards are loaded.

  unset output
}

@test "PHPCS Installed" {
  [[ $SKIP == 1 ]] && skip

  run docker exec -it ${IMG} bash -l -c 'phpcs -i'
  [[ "$status" -eq 0 ]]
  # TODO: Add in check to make sure coding standards are loaded.

  unset output
}

@test "Drush Installed" {
  [[ $SKIP == 1 ]] && skip

  run docker exec -it ${IMAGE_NAME} bash -l -c 'drush --version'
  [[ "$status" -eq 0 ]] &&
  [[ "$output" =~ "Drush Launcher Version" ]] &&
  [[ "$output" =~ "Drush Version" ]]
  unset output
}
