FROM circleci/node:10-stretch-browsers


USER root

RUN set -ex; \
	npm install -g lighthouse circle-github-bot; \
  mkdir -p /opt/reports; \
  mkdir -p /opt/ci-scripts; \
  sudo chmod 777 /opt/reports;

COPY ci-scripts /opt/ci-scripts

RUN set -xe; \
  cd /opt/ci-scripts; \
  git init; \
  npm install
