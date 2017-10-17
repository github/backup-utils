FROM debian:jessie-slim
ARG bkup_version=2.11.1
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get install -y wget rsync ssh git && \
    apt-get clean && apt-get autoremove -q && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man /tmp/*
RUN wget https://github.com/github/backup-utils/releases/download/v${bkup_version}/github-backup-utils_${bkup_version}_amd64.deb
RUN export DEBIAN_FRONTEND=noninteractive && \
    export DEBIAN_PRIORITY=critical && \
    /usr/bin/dpkg -i github-backup-utils_${bkup_version}_amd64.deb && \
    rm github-backup-utils_${bkup_version}_amd64.deb
COPY share/github-backup-utils/ghe-docker-init /usr/share/github-backup-utils/ghe-docker-init
RUN chmod +x /usr/share/github-backup-utils/ghe-docker-init
ENTRYPOINT ["/usr/share/github-backup-utils/ghe-docker-init"]
CMD ["ghe-host-check"]
