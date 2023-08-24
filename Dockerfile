# Multi stage build for backup-utils
# Build layer is for compiling rsync from source
# Runtime layer is for running backup-utils
# https://docs.docker.com/develop/develop-images/multistage-build/
# https://docs.docker.com/engine/userguide/eng-image/multistage-build/

# Build layer
FROM ubuntu:focal AS build

# Install build dependencies
RUN apt-get update && apt-get install --no-install-recommends -y \
    gcc \
    g++ \
    gawk \
    autoconf \
    make \
    automake \
    python3-cmarkgfm \
    acl \
    libacl1-dev \
    attr \
    libattr1-dev \
    libxxhash-dev \
    libzstd-dev \
    liblz4-dev \
    libssl-dev \
    git \
    jq \
    bc \
    curl \
    tar \
    gzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download rsync source from https://github.com/WayneD/rsync/archive/refs/tags/[TAG].tar.gz pinned to specified tag
ARG RSYNC_TAG=v3.2.7
RUN curl https://github.com/WayneD/rsync/archive/refs/tags/${RSYNC_TAG}.tar.gz -L -o ${RSYNC_TAG}.tar.gz
RUN mkdir -p /rsync-${RSYNC_TAG}&& tar -xzf ${RSYNC_TAG}.tar.gz -C /rsync-${RSYNC_TAG} --strip-components=1 && ls -la
# Change to the working directory of the rsync source
WORKDIR /rsync-${RSYNC_TAG}
RUN ls -la && ./configure
RUN make
RUN make install

# Reset working directory
WORKDIR /

# Runtime layer
FROM ubuntu:focal AS runtime

# Install runtime dependencies -  bash, git, OpenSSH 5.6 or newer, and jq v1.5 or newer.
RUN apt-get update && apt-get install --no-install-recommends -y \
    bash \
    git \
    openssh-client \
    jq \
    bc \
    moreutils \
    gawk \
    ca-certificates \
    xxhash \
    && rm -rf /var/lib/apt/lists/*

# Copy rsync from build layer
COPY --from=build /usr/local/bin/rsync /usr/local/bin/rsync

# Copy backup-utils from repository into /backup-utils
COPY ./ /backup-utils/

WORKDIR /backup-utils

RUN chmod +x /backup-utils/share/github-backup-utils/ghe-docker-init

ENTRYPOINT ["/backup-utils/share/github-backup-utils/ghe-docker-init"]
CMD ["ghe-host-check"]
