FROM circleci/php:7.2-apache-stretch-browsers

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

USER root

# Install basic packages
RUN set -xe; \
	apt-get update >/dev/null; \
	apt-get -y --no-install-recommends install >/dev/null \
		apt-transport-https \
		# ca-certificates and curl come from upstream
		#ca-certificates \
		#curl \
		gnupg \
		locales \
		wget \
	;\
	# Cleanup
	apt-get clean; rm -rf /var/lib/apt/lists/*

# Set en_US.UTF-8 as the default locale
RUN set -xe; \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LC_ALL en_US.utf8

# Enable additional repos
RUN set -xe; \
	sed -i 's/main/main contrib non-free/' /etc/apt/sources.list; \
	# git-lfs repo
	curl -fsSL https://packagecloud.io/github/git-lfs/gpgkey | apt-key add -; \
	echo 'deb https://packagecloud.io/github/git-lfs/debian stretch main' | tee /etc/apt/sources.list.d/github_git-lfs.list; \
	echo 'deb-src https://packagecloud.io/github/git-lfs/debian stretch main' | tee -a /etc/apt/sources.list.d/github_git-lfs.list; \
	# MSQSQL repo - msodbcsql17, pecl/sqlsrv and pecl/pdo_sqlsrv (PHP 7.0+ only)
	curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -; \
	echo 'deb https://packages.microsoft.com/debian/9/prod stretch main' | tee /etc/apt/sources.list.d/mssql.list; \
	# MariaDB 10.3 for Debain 9
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8; \
	echo 'deb [arch=amd64,i386,ppc64el] http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.3/debian stretch main' | tee /etc/apt/sources.list.d/mariadb.list; \
	echo 'deb-src http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.3/debian stretch main' | tee -a /etc/apt/sources.list.d/mariadb.list;

# Additional packages
RUN set -xe; \
	# Create man direcotries, otherwise some packages may not install (e.g. postgresql-client)
	# This should be a temporary workaround until fixed upstream: https://github.com/debuerreotype/debuerreotype/issues/10
	mkdir -p /usr/share/man/man1 /usr/share/man/man7; \
	apt-get update >/dev/null; \
	apt-get -y --no-install-recommends install >/dev/null \
		software-properties-common \
		dirmngr \
		cron \
		dnsutils \
		git \
		git-lfs \
		ghostscript \
		# html2text binary - used for self-testing (php-fpm)
		html2text \
		imagemagick \
		iputils-ping \
		less \
		# cgi-fcgi binary - used for self-testing (php-fpm)
		libfcgi-bin \
		mc \
		msmtp \
		mysql-client \
		nano \
		openssh-client \
		openssh-server \
		postgresql-client \
		procps \
		pv \
		rsync \
		sudo \
		supervisor \
		unzip \
		webp \
		zip \
	;\
	# Cleanup
	apt-get clean; rm -rf /var/lib/apt/lists/*

# PHP
RUN set -xe; \
	# Note: essential build tools (g++, gcc, make, etc) are included upstream as persistent packages.
	# See https://github.com/docker-library/php/blob/4af0a8734a48ab84ee96de513aabc45418b63dc5/7.2/stretch/fpm/Dockerfile#L18-L37
	buildDeps=" \
		libc-client2007e-dev \
		libfreetype6-dev \
		libgpgme11-dev \
		libicu-dev \
		libjpeg62-turbo-dev \
		libkrb5-dev \
		libldap2-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		libmemcached-dev \
		libmhash-dev \
		libpng-dev \
		libpq-dev \
		libwebp-dev \
		libssh2-1-dev \
		libxpm-dev \
		libxslt1-dev \
		libzip-dev \
		unixodbc-dev \
	"; \
	apt-get update >/dev/null; \
	# Necessary for msodbcsql17 (MSSQL)
	ACCEPT_EULA=Y \
	apt-get -y --no-install-recommends install >/dev/null \
		$buildDeps \
		libc-client2007e \
		libfreetype6 \
		libgpgme11 \
		libicu57 \
		libjpeg62-turbo \
		libldap-2.4-2 \
		libmagickcore-6.q16-3 \
		libmagickwand-6.q16-3 \
		libmemcached11 \
		libmemcachedutil2 \
		libmhash2 \
		libpng16-16 \
		libpq5 \
		libssh2-1 \
		libxpm4 \
		libxslt1.1 \
		libzip4 \
		msodbcsql17 \
		mariadb-server \
		mariadb-server-10.3 \
		mariadb-client-10.3 \
		mariadb-server-core-10.3 \
	;\
	# SSH2 must be installed from source for PHP 7.x
	git clone https://github.com/php/pecl-networking-ssh2.git /usr/src/php/ext/ssh2 && rm -rf /usr/src/php/ext/ssh2/.git; \
	\
	docker-php-ext-configure >/dev/null gd \
		--with-freetype-dir=/usr/include/ \
		--with-jpeg-dir=/usr/include/ \
		--with-webp-dir=/usr/include/ \
		--with-png-dir=/usr/include/ \
		--with-xpm-dir=/usr/include/; \
	docker-php-ext-configure >/dev/null imap --with-kerberos --with-imap-ssl; \
	docker-php-ext-configure >/dev/null ldap --with-libdir=lib/x86_64-linux-gnu/; \
	docker-php-ext-configure >/dev/null pgsql --with-pgsql=/usr/local/pgsql/; \
	docker-php-ext-configure >/dev/null zip --with-libzip; \
	\
	docker-php-ext-install >/dev/null -j$(nproc) \
		bcmath \
		bz2 \
		calendar\
		exif \
		gd \
		gettext \
		imap \
		intl \
		ldap \
		# mcrypt is deprecated in 7.1 and removed in 7.2. See Deprecated features.
		# mcrypt \
		mysqli \
		opcache \
		pcntl \
		pdo_mysql \
		pdo_pgsql \
		pgsql \
		soap \
		sockets \
		ssh2 \
		xsl \
		zip \
	;\
	pecl update-channels; \
	pecl install >/dev/null </dev/null \
		apcu \
		gnupg \
		imagick \
		# Use memcached (not memcache) for PHP 7.x
		memcached \
		pdo_sqlsrv \
		redis \
		sqlsrv \
		xdebug \
	;\
	docker-php-ext-enable \
		apcu \
		gnupg \
		imagick \
		memcached \
		pdo_sqlsrv \
		redis \
		sqlsrv \
	;\
	# Cleanup
	docker-php-source delete; \
	rm -rf /tmp/pear ~/.pearrc; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps >/dev/null; \
	apt-get clean; rm -rf /var/lib/apt/lists/*

# PHP tools (installed globally)
ENV COMPOSER_VERSION=1.8.0 \
	DRUSH_VERSION=8.1.18 \
	DRUSH_LAUNCHER_VERSION=0.6.0 \
	DRUPAL_CONSOLE_LAUNCHER_VERSION=1.8.0 \
	WPCLI_VERSION=2.0.1 \
	PLATFORMSH_CLI_VERSION=3.38.1
RUN set -xe; \
	# Composer
	curl -fsSL "https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar" -o /usr/local/bin/composer; \
	# Drush 8 (global fallback)
	curl -fsSL "https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar" -o /usr/local/bin/drush8; \
	# Drush Launcher
	curl -fsSL "https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VERSION}/drush.phar" -o /usr/local/bin/drush; \
	# Drupal Console Launcher
	curl -fsSL "https://github.com/hechoendrupal/drupal-console-launcher/releases/download/${DRUPAL_CONSOLE_LAUNCHER_VERSION}/drupal.phar" -o /usr/local/bin/drupal; \
	# Wordpress CLI
	curl -fsSL "https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar" -o /usr/local/bin/wp; \
	# Platform.sh CLI
	curl -fsSL "https://github.com/platformsh/platformsh-cli/releases/download/v${PLATFORMSH_CLI_VERSION}/platform.phar" -o /usr/local/bin/platform; \
	# Make all downloaded binaries executable in one shot
	(cd /usr/local/bin && chmod +x composer drush8 drush drupal wp platform);

# All further RUN commands will run as the "docker" user
USER circleci
SHELL ["/bin/bash", "-c"]

# PHP tools (installed as user)
ENV TERMINUS_VERSION=2.0.0

# Don't use -x here, as the output may be excessive
RUN set -e; \
	\
	# Set drush8 as a global fallback for Drush Launcher
	echo -e "\n""export DRUSH_LAUNCHER_FALLBACK=/usr/local/bin/drush8" >> $HOME/.profile; \
	# Composer based dependencies
	# Add composer bin directory to PATH
	echo -e "\n"'export PATH="$PATH:$HOME/.composer/vendor/bin"' >> $HOME/.profile; \
	# Reload updated PATH from profile to make composer/drush/etc. visible below
	. $HOME/.profile; \
	# Install cgr to use it in-place of `composer global require`
	composer global require consolidation/cgr >/dev/null; \
	# Composer parallel install plugin
	composer global require hirak/prestissimo >/dev/null; \
	# Drupal Coder & WP Coding Standards w/ a matching version of PHP_CodeSniffer
	cgr drupal/coder wp-coding-standards/wpcs phpcompatibility/phpcompatibility-wp >/dev/null; \
	phpcs --config-set installed_paths "$HOME/.composer/global/drupal/coder/vendor/drupal/coder/coder_sniffer/,$HOME/.composer/global/wp-coding-standards/wpcs/vendor/wp-coding-standards/wpcs/"; \
	# Terminus
	cgr pantheon-systems/terminus:${TERMINUS_VERSION} >/dev/null; \
	# Cleanup
	composer clear-cache; \
	\
	# Drush modules
	drush dl registry_rebuild --default-major=7 --destination=$HOME/.drush >/dev/null; \
	drush cc drush

# Node.js (installed as user)
ENV \
	NVM_VERSION=0.34.0 \
	NODE_VERSION=10.15.0 \
	YARN_VERSION=1.13.0
# Don't use -x here, as the output may be excessive
RUN set -e; \
	# NVM and a defaut Node.js version
	export PROFILE="$HOME/.profile"; \
	curl -fsSL https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash >/dev/null; \
	# Reload profile to load nvm (needed by Yarn installation below)
	. $HOME/.profile; \
	# Yarn
	export YARN_PROFILE="$HOME/.profile"; \
	curl -fsSL https://yarnpkg.com/install.sh | bash -s -- --version ${YARN_VERSION} >/dev/null; \
	# Add lighthouse
  npm i lighthouse circle-github-bot fs path -g

# Ruby (installed as user)
ENV \
	RVM_VERSION_INSTALL=1.29.7 \
	RUBY_VERSION_INSTALL=2.6.0
# Don't use -x here, as the output may be excessive
RUN set -e; \
	# Public GPG servers are not realiable, so downloading keys from rvm.io instead.
	#gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
	# Import and trust rvm keys
	# mpapis@gmail.com
	curl -sSL https://rvm.io/mpapis.asc | gpg --batch --import -; \
	echo 409B6B1796C275462A1703113804BB82D39DC0E3:6: | gpg --batch --import-ownertrust; \
	# piotr.kuczynski@gmail.com
	curl -sSL https://rvm.io/pkuczynski.asc | gpg --batch --import -; \
	echo 7D2BAF1CF37B13E2069D6956105BD0E739499BDB:6: | gpg --batch --import-ownertrust; \
	\
	echo 'rvm_autoupdate_flag=0' >> $HOME/.rvmrc; \
	echo 'rvm_silence_path_mismatch_check_flag=1' >> $HOME/.rvmrc; \
	curl -fsSL https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION_INSTALL}/binscripts/rvm-installer | bash -s -- --ignore-dotfiles --version ${RVM_VERSION_INSTALL}; \
	{ \
		echo ''; \
		echo 'export PATH="$PATH:$HOME/.rvm/bin"'; \
		echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"'; \
	} >> $HOME/.profile; \
	# Reload $HOME/.profile to apply settings for the current shell
	. $HOME/.profile; \
	\
	# rvm.io does not currently have ruby binaries for Debian 9, so Ruby is compiled from source, which requires a bunch
	# of extra dependencies installed (rvm installs these automatically), which bloat this image:
	# rvm/ruby required packages: gawk, automake, bison, libffi-dev, libgdbm-dev, libncurses5-dev, libsqlite3-dev, libtool, libyaml-dev, sqlite3, zlib1g-dev, libgmp-dev, libreadline-dev, libssl-dev
	rvm install ruby-${RUBY_VERSION_INSTALL}; \
	rvm use ruby-${RUBY_VERSION_INSTALL} --default; \
	\
	gem install bundler; \
	# Have bundler install gems locally (./.bundle) by default
	echo -e "\n"'export BUNDLE_PATH=.bundle' >> $HOME/.profile; \
	\
	rvm cleanup all; \
	rvm gemset globalcache enable

USER root

ENV \
	APACHE_DOCUMENTROOT=/var/www/docroot

RUN set -xe; \
	mkdir /etc/apache2/ssl; \
	openssl req -batch -x509 -newkey rsa:4096 -days 3650 -nodes -sha256 -subj "/"  -keyout /etc/apache2/ssl/server.key -out /etc/apache2/ssl/server.crt

RUN set -x; \
	cd /etc/apache2/mods-enabled; \
	ln -s ../mods-available/proxy.load ./proxy.load; \
	ln -s ../mods-available/proxy_http.load ./proxy_http.load; \
	ln -s ../mods-available/proxy_connect.load ./proxy_connect.load; \
	ln -s ../mods-available/ssl.load ./ssl.load; \
	ln -s ../mods-available/rewrite.load ./rewrite.load; \
	rm /etc/apache2/sites-enabled/000-default.conf; \
	rm -rf /var/www/html; \
	echo ". /etc/environment" | tee -a /etc/apache2/envvars; \
	mkdir /opt/reports; \
  chmod 777 /opt/reports

COPY config/apache/httpd-vhost.conf /etc/apache2/sites-enabled/000-default.conf
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY startup.sh /opt/startup.sh

USER circleci
WORKDIR /var/www

# Copy CI scripts
RUN mkdir /home/circleci/ci-scripts
COPY ci-scripts /home/circleci/ci-scripts
ENV BASH_ENV '~/.bashrc'
# Starter script
ENTRYPOINT ["/opt/startup.sh"]

# By default, launch supervisord to keep the container running.
CMD ["supervisord"]