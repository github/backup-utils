FROM debian:stretch-slim

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

WORKDIR /backup-utils
ADD https://github.com/github/backup-utils/archive/stable.tar.gz /
RUN tar xzvf /stable.tar.gz --strip-components=1 -C /backup-utils && \
    rm -r /stable.tar.gz

RUN chmod +x /backup-utils/share/github-backup-utils/ghe-docker-init

ENTRYPOINT ["/backup-utils/share/github-backup-utils/ghe-docker-init"]
CMD ["ghe-host-check"]
