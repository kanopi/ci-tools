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

# Test if Composer Installed.
@test "Composer Installed" {
  [[ $SKIP == 1 ]] && skip "Full Skip Set"
  [[ $SKIP_TESTS =~ " ${!BATS_TEST_NAME^^} " ]] && skip "${BATS_TEST_NAME^^} set in SKIP_TESTS"

  run docker exec -i -u ${CONTAINER_USER} ${CONTAINER_NAME} bash -lc 'composer --version'
  [[ "$status" -eq 0 ]]
}

# Test if PHPCS and All Appropriate Libraries Installed.
@test "PHPCS Installed" {
  [[ $SKIP == 1 ]] && skip "Full Skip Set"
  [[ $SKIP_TESTS =~ " ${!BATS_TEST_NAME^^} " ]] && skip "${BATS_TEST_NAME^^} set in SKIP_TESTS"

  run docker exec -i -u ${CONTAINER_USER} ${CONTAINER_NAME} bash -lc 'phpcs -i'
  [[ "$status" -eq 0 ]]
}

# Test if Drush Launcher and Drush 8 are installed.
@test "Drush Installed" {
  [[ $SKIP == 1 ]] && skip "Full Skip Set"
  [[ $SKIP_TESTS =~ " ${!BATS_TEST_NAME^^} " ]] && skip "${BATS_TEST_NAME^^} set in SKIP_TESTS"

  run docker exec -i -u ${CONTAINER_USER} ${CONTAINER_NAME} bash -lc 'drush --version'
  [[ "$status" -eq 0 ]]
  [[ "$output" =~ "Drush Launcher Version" ]]
  [[ "$output" =~ "Drush Version" ]]
}

# Test if Drush Launcher and Drush 8 are installed.
@test "Lighthouse" {
  [[ $SKIP == 1 ]] && skip "Full Skip Set"
  [[ $SKIP_TESTS =~ " ${!BATS_TEST_NAME^^} " ]] && skip "${BATS_TEST_NAME^^} set in SKIP_TESTS"

  run docker exec -i -u ${CONTAINER_USER} ${CONTAINER_NAME} bash -lc 'lighthouse https://google.com --port=9222 --chrome-flags="--headless" --output-path=/opt/reports/anonymous-"$(echo -n $CIRCLE_SHELL_ENV | md5sum | awk '{print $1}')" --output=json --output=html'
  [[ "$status" -eq 0 ]]
  [[ "$output" =~ "Generating results" ]]
}

