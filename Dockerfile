FROM ubuntu:latest

ARG port=2222

RUN apt update && apt install -y --no-install-recommends \
			openssh-server \
			openssh-client \
            libcap2-bin \
		&& rm -rf /var/lib/apt/lists/*
# Add priviledge separation directoy to run sshd as root.
RUN mkdir -p /var/run/sshd
# Add capability to run sshd as non-root.
RUN setcap CAP_NET_BIND_SERVICE=+eip /usr/sbin/sshd
RUN apt remove libcap2-bin -y

# Allow OpenSSH to talk to containers without asking for confirmation
# by disabling StrictHostKeyChecking.
# mpi-operator mounts the .ssh folder from a Secret. For that to work, we need
# to disable UserKnownHostsFile to avoid write permissions.
# Disabling StrictModes avoids directory and files read permission checks.
RUN sed -i "s/[ #]\(.*StrictHostKeyChecking \).*/ \1no/g" /etc/ssh/ssh_config \
    && echo "    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config \
    && sed -i "s/[ #]\(.*Port \).*/ \1$port/g" /etc/ssh/ssh_config \
    && sed -i "s/#\(StrictModes \).*/\1no/g" /etc/ssh/sshd_config \
    && sed -i "s/#\(Port \).*/\1$port/g" /etc/ssh/sshd_config

RUN useradd -s /bin/bash -m mpiuser 
WORKDIR /home/mpiuser
# Configurations for running sshd as non-root.
COPY --chown=mpiuser sshd_config .sshd_config
RUN echo "Port $port" >> /home/mpiuser/.sshd_config

RUN apt update \
    && apt install -y --no-install-recommends openmpi-bin \
    && rm -rf /var/lib/apt/lists/*

RUN apt update -y && \
    apt install -y curl software-properties-common && \
    curl -o /etc/apt/trusted.gpg.d/openfoam.asc https://dl.openfoam.org/gpg.key && \
    add-apt-repository "http://dl.openfoam.org/ubuntu dev" && \
    apt update -y && \
    apt install -y --no-install-recommends git openfoam-dev

RUN echo "source /opt/openfoam-dev/etc/bashrc" >> /home/mpiuser/.bashrc

RUN mkdir /home/mpiuser/case

