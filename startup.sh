#!/usr/bin/env bash

# This script is running as root by default.
# Switching to the docker user can be done via "gosu docker <command>".

HOME_DIR='/home/circleci'

DEBUG=${DEBUG:-0}
# Turn debugging ON when cli is started in the service mode
[[ "$1" == "supervisord" ]] && DEBUG=1
echo-debug ()
{
	[[ "$DEBUG" != 0 ]] && echo "$(date +"%F %H:%M:%S") | $@"
}

uid_gid_reset ()
{
	if [[ "$HOST_UID" != "$(id -u circleci)" ]] || [[ "$HOST_GID" != "$(id -g circleci)" ]]; then
		echo-debug "Updating circleci user uid/gid to $HOST_UID/$HOST_GID to match the host user uid/gid..."
		usermod -u "$HOST_UID" -o circleci
		groupmod -g "$HOST_GID" -o "$(id -gn circleci)"
	fi
}

xdebug_enable ()
{
	echo-debug "Enabling xdebug..."
	ln -s /opt/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/
}

add_ssh_key ()
{
	echo-debug "Adding a private SSH key from SECRET_SSH_PRIVATE_KEY..."
	render_tmpl "$HOME_DIR/.ssh/id_rsa"
	chmod 0600 "$HOME_DIR/.ssh/id_rsa"
}

# Helper function to render configs from go templates using gomplate
render_tmpl ()
{
	local file="${1}"
	local tmpl="${1}.tmpl"

	if [[ -f "${tmpl}" ]]; then
		echo-debug "Rendering template: ${tmpl}..."
		gomplate --file "${tmpl}" --out "${file}"
	else
		echo-debug "Error: Template file not found: ${tmpl}"
		return 1
	fi
}

# Helper function to loop through all environment variables prefixed with SECRET_ and
# convert to the equivalent variable without SECRET.
# Example: SECRET_TERMINUS_TOKEN => TERMINUS_TOKEN.
convert_secrets ()
{
	eval 'secrets=(${!SECRET_@})'
	for secret_key in "${secrets[@]}"; do
		key=${secret_key#SECRET_}
		secret_value=${!secret_key}

		# Write new variables to /etc/profile.d/secrets.sh to make them available for all users/sessions
		echo "export ${key}=\"${secret_value}\"" | tee -a "/etc/profile.d/secrets.sh" >/dev/null

		# Also export new variables here
		# This makes them available in the server/php-fpm environment
		eval "export ${key}=${secret_value}"
	done
}

# Acquia Cloud API login
acquia_login ()
{
	echo-debug "Authenticating with Acquia..."
	# This has to be done using the circleci user via su to load the user environment
	# Note: Using 'su -l' to initiate a login session and have .profile sourced for the circleci user
	local command="drush ac-api-login --email='${ACAPI_EMAIL}' --key='${ACAPI_KEY}' --endpoint='https://cloudapi.acquia.com/v1' && drush ac-site-list"
	local output=$(su -l circleci -c "${command}" 2>&1)
	if [[ $? != 0 ]]; then
		echo-debug "ERROR: Acquia authentication failed."
		echo
		echo "$output"
		echo
	fi
}

# Pantheon (terminus) login
terminus_login ()
{
	echo-debug "Authenticating with Pantheon..."
	# This has to be done using the docker user via su to load the user environment
	# Note: Using 'su -l' to initiate a login session and have .profile sourced for the docker user
	local command="terminus auth:login --machine-token='${TERMINUS_TOKEN}'"
	local output=$(su -l circleci -c "${command}" 2>&1)
	if [[ $? != 0 ]]; then
		echo-debug "ERROR: Pantheon authentication failed."
		echo
		echo "$output"
		echo
	fi
}

# Git settings
git_settings ()
{
	# These must be run as the circleci user
	echo-debug "Configuring git..."
	sudo -u circleci git config --global user.email "${GIT_USER_EMAIL}"
	sudo -u circleci git config --global user.name "${GIT_USER_NAME}"
}

# Inject a private SSH key if provided
[[ "$SECRET_SSH_PRIVATE_KEY" != "" ]] && add_ssh_key

# Convert all Environment Variables Prefixed with SECRET_
convert_secrets

# Docker user uid/gid mapping to the host user uid/gid
[[ "$HOST_UID" != "" ]] && [[ "$HOST_GID" != "" ]] && uid_gid_reset

# Enable xdebug
[[ "$XDEBUG_ENABLED" != "" ]] && [[ "$XDEBUG_ENABLED" != "0" ]] && xdebug_enable

# Make sure permissions are correct (after uid/gid change and COPY operations in Dockerfile)
# To not bloat the image size, permissions on the home folder are reset at runtime.
echo-debug "Resetting permissions on $HOME_DIR and /var/www..."
chown "${HOST_UID:-3434}:${HOST_GID:-3434}" -R "$HOME_DIR"
# Docker resets the project root folder permissions to 0:0 when cli is recreated (e.g. an env variable updated).
# We apply a fix/workaround for this at startup (non-recursive).
chown "${HOST_UID:-3434}:${HOST_GID:-3434}" /var/www

# These have to happen after the home directory permissions are reset,
# otherwise the circleci user may not have write access to /home/circleci, where the auth session data is stored.
# Acquia Cloud API config
[[ "$ACAPI_EMAIL" != "" ]] && [[ "$ACAPI_KEY" != "" ]] && acquia_login
# Automatically authenticate with Pantheon if Terminus token is present
[[ "$TERMINUS_TOKEN" != "" ]] && terminus_login

# Apply git settings
[[ "$GIT_USER_EMAIL" != "" ]] && [[ "$GIT_USER_NAME" != "" ]] && git_settings

echo "export APACHE_DOCUMENTROOT=${APACHE_DOCUMENTROOT}" | exec gosu root tee -a /etc/environment

# If running on circleci make sure to add the profile to the ${BASH_ENV} file.
if [[ "${CIRCLECI}" == "true" ]] && [[ "${BASH_ENV}" != "" ]]; then 
	echo ". ${HOME}/.profile" >> ${BASH_ENV}
fi

# Execute passed CMD arguments
echo-debug "Passing execution to: $*"
# Service mode (run as root)
if [[ "$1" == "supervisord" ]]; then
	exec gosu root supervisord -c /etc/supervisor/supervisord.conf
# Command mode (run as circleci user)
else
	exec gosu circleci "$@"
fi
