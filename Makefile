
BASE?=riedmiki/gromacs-plumed-python
VERSION=2021
IMAGE=${BASE}:${VERSION}

.PHONY: build
build:
	docker build -t ${IMAGE} .

.PHONY: all
all: build wrapper push

.PHONY: wrapper
wrapper:
	sed 's?%IMAGE%?${IMAGE}?' gmx-docker.in >gmx-docker
	chmod +x gmx-docker

.PHONY: push
push:
	docker push ${IMAGE}
