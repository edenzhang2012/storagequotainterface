all: build

########################################################################
##                             GOLANG                                 ##
########################################################################

# If GOPATH isn't defined then set its default location.
ifeq (,$(strip $(GOPATH)))
GOPATH := $(HOME)/go
else
# If GOPATH is already set then update GOPATH to be its own
# first element.
GOPATH := $(word 1,$(subst :, ,$(GOPATH)))
endif
export GOPATH

GOBIN := $(shell go env GOBIN)
ifeq (,$(strip $(GOBIN)))
GOBIN := $(GOPATH)/bin
endif


########################################################################
##                             PROTOC                                 ##
########################################################################

# Only set PROTOC_VER if it has an empty value.
ifeq (,$(strip $(PROTOC_VER)))
PROTOC_VER := 25.2
endif

PROTOC_OS := $(shell uname -s)
ifeq (Darwin,$(PROTOC_OS))
PROTOC_OS := osx
endif

PROTOC_ARCH := $(shell uname -m)
ifeq (i386,$(PROTOC_ARCH))
PROTOC_ARCH := x86_32
else ifeq (arm64,$(PROTOC_ARCH))
PROTOC_ARCH := aarch_64
endif

PROTOC_ZIP := protoc-$(PROTOC_VER)-$(PROTOC_OS)-$(PROTOC_ARCH).zip
PROTOC_URL := https://github.com/protocolbuffers/protobuf/releases/download/v$(PROTOC_VER)/$(PROTOC_ZIP)
PROTOC_TMP_DIR := .protoc
PROTOC := $(PROTOC_TMP_DIR)/bin/protoc

$(GOBIN)/protoc-gen-go: ./go.mod
	go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.33.0
$(GOBIN)/protoc-gen-go-grpc:
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0

$(PROTOC):
	-mkdir -p "$(PROTOC_TMP_DIR)" && \
	  curl -L $(PROTOC_URL) -o "$(PROTOC_TMP_DIR)/$(PROTOC_ZIP)" && \
	  unzip "$(PROTOC_TMP_DIR)/$(PROTOC_ZIP)" -d "$(PROTOC_TMP_DIR)" && \
	  chmod 0755 "$@"
	stat "$@" > /dev/null 2>&1

PROTOC_ALL := $(GOBIN)/protoc-gen-go $(GOBIN)/protoc-gen-go-grpc $(PROTOC)

########################################################################
##                              PATH                                  ##
########################################################################

# Update PATH with GOBIN. This enables the protoc binary to discover
# the protoc-gen-go binary
export PATH := $(GOBIN):$(PATH)


########################################################################
##                              BUILD                                 ##
########################################################################
SQI_PROTO := ./sqi/sqi.proto
SQI_PKG_SUB := ./sqi/pb
SQI_GO := $(SQI_PKG_SUB)/sqi.pb.go
SQI_GRPC := $(SQI_PKG_SUB)/sqi_grpc.pb.go

# This recipe generates the go language bindings
$(SQI_GO) $(SQI_GRPC): $(SQI_PROTO) $(PROTOC_ALL)
	@mkdir -p "$(@D)"
	$(PROTOC) -I./sqi/ --go-grpc_out=$(SQI_PKG_SUB) --go_out=$(SQI_PKG_SUB) \
		--go_opt=paths=source_relative --go-grpc_opt=paths=source_relative \
		"$(<F)"

build: $(SQI_GO) $(SQI_GRPC)

clean:
	go clean -i ./...
	rm -rf "$(SQI_PKG_SUB)"

clobber: clean
	rm -fr "$(PROTOC_TMP_DIR)"

.PHONY: clean clobber