DOCKER ?= docker
VERSION ?= 1
REPO = kanopi/ci
TAG = build-$(VERSION)
NAME = kanopi-ci-$(VERSION)
CWD = $(shell pwd)

# Improve write performance for /home/docker by turning it into a volume
VOLUMES += -v /home/circleci

.PHONY: build test push shell run start stop logs clean release

build:
	$(DOCKER) build -t $(REPO):$(TAG) .

test:
	IMAGE=$(REPO):$(TAG) NAME=$(NAME) VERSION=$(VERSION) ../tests/test.bats

push:
	$(DOCKER) push $(REPO):$(TAG)

run: clean
	$(DOCKER) run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

start: clean
	$(DOCKER) run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

# Non-interactive and non-tty docker exec (uses LF instead of CRLF line endings)
exec:
	$(DOCKER) exec -u circleci $(NAME) bash -lc "$(CMD)"

# Interactive docker exec
exec-it:
	$(DOCKER) exec -u circleci -it $(NAME) bash -ilc "$(CMD)"

shell:
	$(DOCKER) exec -u circleci -it $(NAME) bash -il

stop:
	$(DOCKER) stop $(NAME)

logs:
	$(DOCKER) logs $(NAME)

logs-follow:
	$(DOCKER) logs -f $(NAME)

clean:
	$(DOCKER) rm -vf $(NAME) >/dev/null 2>&1 || true

release: build
	make push -e TAG=$(TAG)

default: build
