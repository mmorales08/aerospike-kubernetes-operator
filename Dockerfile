# Build the manager binary
FROM --platform=$BUILDPLATFORM cgr.dev/chainguard/go:latest@sha256:2ed63c9db04ba7d7e4d426ffd17afe1793df837f18194ddc251d15e90977a00b AS builder

# OS and Arch args
ARG TARGETOS
ARG TARGETARCH

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY cmd/main.go cmd/main.go
COPY api/ api/
COPY internal/ internal/
COPY pkg/ pkg/
COPY errors/ errors/

# Build
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} GO111MODULE=on go build -a -o manager cmd/main.go

# Base image
FROM cgr.dev/chainguard/static:latest@sha256:fc42af33e643f20d08baf03cddcc1c02ba57052dfb02edb0d79f3fc47bcea8d9

# Version of Operator (build arg)
ARG VERSION="4.7.0"

# Labels
LABEL name="aerospike-kubernetes-operator" \
    version="${VERSION}" \
    summary="Aerospike Kubernetes Operator" \
    description="The Aerospike Kubernetes Operator automates the deployment and management of Aerospike enterprise clusters on Kubernetes"

COPY LICENSE /LICENSE

WORKDIR /

COPY --from=builder /workspace/manager .

ENTRYPOINT ["/manager"]
