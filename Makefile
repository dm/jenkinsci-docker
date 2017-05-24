CONTAINER_NAME = jenkinsci
NAME = dmacedo/jenkinsci
USER = jenkins
VERSION = 2.62

.PHONY: all build test tag_latest release ssh

## [default] Build and run
all: build run

## Build Jenkins tagged container
build:
	docker build -t ${NAME}:${VERSION} .

## Build Jenkins tagged container without cache
build-nc:
	docker build --no-cache -t ${NAME}:${VERSION} .

## Run Jenkins container on assigned ports
run:
	docker run -i -t --rm -p 8080:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home --name="${CONTAINER_NAME}" ${NAME}:${VERSION}

## Stop and remove container
stop:
	docker stop ${CONTAINER_NAME}

## Run tests
test:
	cd tests && bats tests

## Docker tagging
tag: tag_latest tag_version

## Tag latest release
tag_latest:
	@echo 'create tag latest'
	docker tag ${NAME} ${NAME}:latest

## Tag version release
tag_version:
	docker tag ${NAME} $(APP_NAME):$(VERSION)

## Push latest release
release: tag_latest
	@if ! docker images ${NAME} | awk '{ print $$2 }' | grep -q -F ${VERSION}; then echo "${NAME} version ${VERSION} is not yet built. Please run 'make build'"; false; fi
	docker push ${NAME}
	@echo "*** Don't forget to create a tag by creating an official GitHub release."


## Connect to container with default jenkins user
connect:
	@ID=$$(docker ps | grep -F "${NAME}:${VERSION}" | awk '{ print $$1 }') && \
		if test "$$ID" = ""; then echo "Container ${NAME}:${VERSION} not running."; exit 1; fi && \
	docker exec -i -t $$ID /bin/bash


## Print this help
help:
	@awk -v skip=1 \
		'/^##/ { sub(/^[#[:blank:]]*/, "", $$0); doc_h=$$0; doc=""; skip=0; next } \
		 skip  { next } \
		 /^#/  { doc=doc "\n" substr($$0, 2); next } \
		 /:/   { sub(/:.*/, "", $$0); printf "\033[34m%-30s\033[0m\033[1m%s\033[0m %s\n\n", $$0, doc_h, doc; skip=1 }' \
		$(MAKEFILE_LIST)
