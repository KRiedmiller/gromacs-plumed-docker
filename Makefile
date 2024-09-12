
BASE?=riedmiki/gromacs-plumed-python
VERSION=2023.5-plumed

GROMACS_VERSION=2023.5
GROMACS_MD5=fb85104d9cd1f753fde761bcbf842566
# GROMACS_VERSION=2021
# GROMACS_MD5=176f7decc09b23d79a495107aaedb426

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
