# A disposable Linux sandbox for every lesson and project in this repository.
# Nothing you do inside it can harm your own machine.
FROM ubuntu:25.10

ARG USERNAME=learner
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        bash bash-completion bats shellcheck shfmt jq bc curl wget ca-certificates \
        git make openssh-client openssh-server sudo \
        vim nano less man-db manpages tmux tree \
        procps psmisc htop lsof strace \
        iproute2 iputils-ping dnsutils net-tools netcat-openbsd nmap traceroute \
        cron rsyslog logrotate rsync tar gzip bzip2 xz-utils zip unzip \
        gawk sed grep findutils diffutils file \
        ufw nftables fail2ban auditd lynis \
        python3 \
    && rm -rf /var/lib/apt/lists/*

# Restore the man pages that minimal Ubuntu images strip out.
RUN yes | unminimize >/dev/null 2>&1 || true

# Non-root user with passwordless sudo, so privileged lessons work safely
# inside the container.
RUN (id ubuntu >/dev/null 2>&1 && userdel -r ubuntu || true) \
    && useradd -m -s /bin/bash -G sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /workspaces/Linux-Projects
CMD ["bash"]
