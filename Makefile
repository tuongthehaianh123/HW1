# SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>
#
# SPDX-License-Identifier: Apache-2.0

export CGO_ENABLED=1
export GO111MODULE=on

.PHONY: build

ONOS_HW_VERSION := v0.3.2
ONOS_PROTOC_VERSION := v0.6.6
BUF_VERSION := 0.27.1

build: # @HELP build the Go binaries and run all validations (default)
build:
	GOPRIVATE="github.com/tuongthehaianh123/HW/HW/*" go build -o build/_output/onos-hw ./cmd/onos-hw

build-tools:=$(shell if [ ! -d "./build/build-tools" ]; then cd build && git clone https://github.com/onosproject/build-tools.git; fi)
include ./build/build-tools/make/onf-common.mk

test: # @HELP run the unit tests and source code validation
test: build deps linters license
	go test -race github.com/tuongthehaianh123/HW/HW/pkg/...
	go test -race github.com/tuongthehaianh123/HW/HW/cmd/...

jenkins-test:  # @HELP run the unit tests and source code validation producing a junit style report for Jenkins
jenkins-test: deps license linters
	TEST_PACKAGES=github.com/tuongthehaianh123/HW/HW/... ./build/build-tools/build/jenkins/make-unit

buflint: #@HELP run the "buf check lint" command on the proto files in 'api'
	docker run -it -v `pwd`:/go/src/github.com/tuongthehaianh123/HW \
		-w /go/src/github.com/tuongthehaianh123/HW/HW/api \
		bufbuild/buf:${BUF_VERSION} check lint

protos: # @HELP compile the protobuf files (using protoc-go Docker)
protos:
	docker run -it -v `pwd`:/go/src/github.com/tuongthehaianh123/HW \
		-w /go/src/github.com/tuongthehaianh123/HW \
		--entrypoint build/bin/compile-protos.sh \
		onosproject/protoc-go:${ONOS_PROTOC_VERSION}

helmit-kpm: integration-test-namespace # @HELP run MHO tests locally
	helmit test -n test ./cmd/onos-hw-test --timeout 30m --no-teardown \
			--secret sd-ran-username=${repo_user} --secret sd-ran-password=${repo_password} \
			--suite kpm

helmit-ha: integration-test-namespace # @HELP run MHO HA tests locally
	helmit test -n test ./cmd/onos-hw-test --timeout 30m --no-teardown \
			--secret sd-ran-username=${repo_user} --secret sd-ran-password=${repo_password} \
			--suite ha

integration-tests: helmit-kpm helmit-ha # @HELP run all MHO integration tests locally

onos-hw-docker: # @HELP build onos-hw Docker image
onos-hw-docker:
	@go mod vendor
	docker build . -f build/onos-hw/Dockerfile \
		-t onosproject/onos-hw:${ONOS_HW_VERSION}
	@rm -rf vendor

images: # @HELP build all Docker images
images: build onos-hw-docker

kind: # @HELP build Docker images and add them to the currently configured kind cluster
kind: images
	@if [ "`kind get clusters`" = '' ]; then echo "no kind cluster found" && exit 1; fi
	kind load docker-image onosproject/onos-hw:${ONOS_HW_VERSION}

all: build images

publish: # @HELP publish version on github and dockerhub
	./build/build-tools/publish-version ${VERSION} onosproject/onos-hw

jenkins-publish: jenkins-tools # @HELP Jenkins calls this to publish artifacts
	./build/bin/push-images
	./build/build-tools/release-merge-commit

clean:: # @HELP remove all the build artifacts
	rm -rf ./build/_output ./vendor ./cmd/onos-hw/onos-hw ./cmd/onos/onos
	go clean -testcache github.com/tuongthehaianh123/HW/HW/...

