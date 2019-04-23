#!/usr/bin/env bats

# Following Tests are used to confirm software is installed.

@test "Drush Installed" {
  [[ $SKIP == 1 ]] && skip

  run docker exec -it qabuild drush --version
  [[ "$output" =~ "Drush Launcher Version" ]] &&
    [[ "$output" =~ "Drush Version" ]]
  unset output

  return 0
}
