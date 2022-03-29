ARG XX_VERSION=1.1.0

FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

# Build the manager binary
FROM --platform=$BUILDPLATFORM golang:1.17-alpine AS builder

# Copy the build utilities.
COPY --from=xx / /

ARG TARGETPLATFORM

# Configure workspace.
WORKDIR /workspace

# copy modules manifests
COPY go.mod go.mod
COPY go.sum go.sum

# Copy this, which should not change often; and, needs to be in place
# before `go mod download`.
COPY api/ api/

# cache modules
RUN go mod download

# copy source code
COPY main.go main.go
COPY controllers/ controllers/
COPY internal/ internal/

# build without giving the arch, so that it gets it from the machine
ENV CGO_ENABLED=0
RUN xx-go build -a -o image-reflector-controller main.go

FROM registry.access.redhat.com/ubi8/ubi

LABEL org.opencontainers.image.source="https://github.com/fluxcd/image-reflector-controller"

ARG TARGETPLATFORM
RUN yum install -y ca-certificates

COPY --from=builder /workspace/image-reflector-controller /usr/local/bin/

USER 65534:65534

ENTRYPOINT [ "image-reflector-controller" ]
