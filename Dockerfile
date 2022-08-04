FROM debian:buster-slim

RUN apt-get -q -y update && \
    apt-get install -y --no-install-recommends \
    tar \
    rsync \
    ca-certificates \
    ssh \
    git \
    moreutils \
    gawk \
    && rm -rf /var/lib/apt/lists/*

COPY ./ /backup-utils/
WORKDIR /backup-utils

RUN chmod +x /backup-utils/share/github-backup-utils/ghe-docker-init

ENTRYPOINT ["/backup-utils/share/github-backup-utils/ghe-docker-init"]
CMD ["ghe-host-check"]
