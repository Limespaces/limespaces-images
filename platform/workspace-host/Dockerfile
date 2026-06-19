# syntax=docker/dockerfile:1
FROM ubuntu:24.04

# Skip interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies, systemd, fuse
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    systemd \
    systemd-sysv \
    iptables \
    iproute2 \
    kmod \
    sudo \
    fuse3 \
    jq \
    rsync \
    && rm -rf /var/lib/apt/lists/*

# Install docker
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Install sysbox inside the container
# Use policy-rc.d to prevent daemons from starting during build
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d && \
    curl -fsSL -o /tmp/sysbox.deb https://github.com/nestybox/sysbox/releases/download/v0.7.0/sysbox-ce_0.7.0.linux_amd64.deb && \
    apt-get update && \
    apt-get install -y /tmp/sysbox.deb && \
    rm -f /usr/sbin/policy-rc.d /tmp/sysbox.deb && \
    rm -rf /var/lib/apt/lists/*

# Configure docker daemon to know about sysbox-runc runtime
# Install wrapper script that strips unsupported "time" namespace (sysbox#1011)
RUN mv /usr/bin/sysbox-runc /usr/bin/sysbox-runc.real
COPY ./sysbox-runc-wrapper.sh /usr/bin/sysbox-runc
RUN chmod +x /usr/bin/sysbox-runc
RUN mkdir -p /etc/docker && \
    echo '{"runtimes":{"sysbox-runc":{"path":"/usr/bin/sysbox-runc"}},"insecure-registries":["limespaces-registry:5000","registry:5000"]}' > /etc/docker/daemon.json

# Create container directory for sharing docker socket
# Creating outside /run (tmpfs) prevents systemd issues
RUN mkdir -p /limespaces && chmod 777 /limespaces

# Reconfigure docker systemd service to listen on both the default and limespaces socket
RUN mkdir -p /etc/systemd/system/docker.service.d
COPY ./docker-service-override.conf /etc/systemd/system/docker.service.d/override.conf

# Enabled systemd services
RUN systemctl enable docker.service containerd.service sysbox.service

VOLUME /var/lib/docker
VOLUME /var/lib/sysbox
VOLUME /limespaces

# Start systemd as PID 1
ENTRYPOINT ["/sbin/init"]