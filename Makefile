SHELL = /bin/bash
REG=quay.io
ORG=integreatly
IMAGE=backup-container
TAG=latest

image/build:
	@docker build -t ${REG}/${ORG}/${IMAGE}:${TAG} ./image

image/push:
	@docker push ${REG}/${ORG}/${IMAGE}:${TAG}