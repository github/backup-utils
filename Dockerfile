FROM debian:jessie-slim

RUN apt-get -q -y update && \
    apt-get install -y --no-install-recommends \
    tar \
    rsync \
    ca-certificates \
    ssh \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /backup-utils-stable
ADD https://github.com/github/backup-utils/archive/stable.tar.gz /
RUN tar xzvf /stable.tar.gz --strip-components=1 -C /backup-utils-stable && \
    rm -r /stable.tar.gz

COPY share/github-backup-utils/ghe-docker-init /backup-utils-stable/share/github-backup-utils/ghe-docker-init
RUN chmod +x /backup-utils-stable/share/github-backup-utils/ghe-docker-init

ENTRYPOINT ["/backup-utils-stable/share/github-backup-utils/ghe-docker-init"]
CMD ["ghe-host-check"]
