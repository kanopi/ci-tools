#!/usr/bin/env bats

# Name of the Docker Container to Reference
CINAME=app

# Docker Image to Build Container
IMG=app

# Following Tests are used to confirm software is installed.

setup () {
  docker run -d --rm -p 80:80 -p 443:443 -v /app/project:/var/www/ --name=$CINAME $IMG
}

# Debugging
teardown() {
  docker rm -f $CINAME
  echo "Status: $status"
  echo "Output:"
  echo "================================================================"
  for line in "${lines[@]}"; do
    echo $line
  done
  echo "================================================================"
}

@test "PHPCS Installed" {
  [[ $SKIP == 1 ]] && skip

  run docker exec -it app phpcs -i
  [[ "$status" -eq 0 ]]
  # TODO: Add in check to make sure coding standards are loaded.

  unset output
}

@test "Drush Installed" {
  [[ $SKIP == 1 ]] && skip

  run docker exec -it app drush --version
  [[ "$status" -eq 0 ]] &&
  [[ "$output" =~ "Drush Launcher Version" ]] &&
  [[ "$output" =~ "Drush Version" ]]
  unset output
}
