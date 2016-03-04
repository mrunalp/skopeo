FROM fedora

RUN dnf -y update && dnf install -y make git golang golang-github-cpuguy83-go-md2man python-pip m2crypto swig redhat-rpm-config

# Install three versions of the registry. The first is an older version that
# only supports schema1 manifests. The second is a newer version that supports
# both. This allows integration-cli tests to cover push/pull with both schema1
# and schema2 manifests. Install registry v1 also.
ENV REGISTRY_COMMIT_SCHEMA1 ec87e9b6971d831f0eff752ddb54fb64693e51cd
ENV REGISTRY_COMMIT 47a064d4195a9b56133891bbb13620c3ac83a827
RUN set -x \
	&& export GOPATH="$(mktemp -d)" \
	&& git clone https://github.com/docker/distribution.git "$GOPATH/src/github.com/docker/distribution" \
	&& (cd "$GOPATH/src/github.com/docker/distribution" && git checkout -q "$REGISTRY_COMMIT") \
	&& GOPATH="$GOPATH/src/github.com/docker/distribution/Godeps/_workspace:$GOPATH" \
		go build -o /usr/local/bin/registry-v2 github.com/docker/distribution/cmd/registry \
	&& (cd "$GOPATH/src/github.com/docker/distribution" && git checkout -q "$REGISTRY_COMMIT_SCHEMA1") \
	&& GOPATH="$GOPATH/src/github.com/docker/distribution/Godeps/_workspace:$GOPATH" \
		go build -o /usr/local/bin/registry-v2-schema1 github.com/docker/distribution/cmd/registry \
	&& rm -rf "$GOPATH" \
	&& export DRV1="$(mktemp -d)" \
	&& git clone https://github.com/docker/docker-registry.git "$DRV1" \
	&& pip install --ignore-installed "$DRV1/depends/docker-registry-core" \
	&& pip install --ignore-installed file://"$DRV1#egg=docker-registry[bugsnag,newrelic,cors]" \
	&& patch $(python -c 'import boto; import os; print os.path.dirname(boto.__file__)')/connection.py \
		< "$DRV1/contrib/boto_header_patch.diff"

ENV GOPATH /usr/share/gocode:/go
WORKDIR /go/src/github.com/runcom/skopeo

COPY . /go/src/github.com/runcom/skopeo

#ENTRYPOINT ["hack/dind"]