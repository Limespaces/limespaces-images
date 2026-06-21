# syntax=docker/dockerfile:1
# --- Workspace image ---
FROM fedora:42

ARG W_USERNAME=limespaces
ARG W_PASSWORD=lemonade

ENV HOME=/home/${W_USERNAME}
ENV DISPLAY=:1
ENV VNC_RESOLUTION=1920x1080
ENV VNC_COL_DEPTH=24
ENV APPIMAGE_EXTRACT_AND_RUN=1

WORKDIR /home/${W_USERNAME}

# Install system dependencies
RUN --mount=type=cache,target=/var/cache/libdnf5 \
    dnf -y --setopt=keepcache=True update && \
    dnf -y --setopt=keepcache=True install \
        gnome-shell \
        gnome-session \
        gnome-menus \
        #mutter \
        gnome-session-xsession \
        gsettings-desktop-schemas \
        dbus-x11 \
        at-spi2-core \
        mesa-dri-drivers \
        #xdotool \
        #wget \
        #which \
        #python3-gobject \
        tigervnc-server \
        novnc \
        procps-ng \
        fuse-libs \
        systemd \
        sudo \
        unzip \
        gcc \
        gcc-c++ \
        make \
        gobject-introspection-devel \
        glib2-devel \
        zenity

# Raise systemd task limits (default is too low)
RUN mkdir -p /etc/systemd/system.conf.d /etc/systemd/user.conf.d /etc/systemd/logind.conf.d /etc/systemd/system/user-.slice.d && \
    printf '[Manager]\nDefaultTasksMax=infinity\n' > /etc/systemd/system.conf.d/tasks.conf && \
    printf '[Manager]\nDefaultTasksMax=infinity\n' > /etc/systemd/user.conf.d/tasks.conf && \
    printf '[Login]\nUserTasksMax=infinity\n' > /etc/systemd/logind.conf.d/tasks.conf && \
    printf '[Slice]\nTasksMax=infinity\n' > /etc/systemd/system/user-.slice.d/tasks.conf

# Copy journal config
COPY assets/systemd/journald.conf /etc/systemd/journald.conf

# Create user
RUN useradd -u 1000 -g 0 -m -d /home/${W_USERNAME} ${W_USERNAME} && \
    usermod -aG wheel ${W_USERNAME} && \
    echo "${W_PASSWORD}" | passwd --stdin ${W_USERNAME} && \
    echo "${W_USERNAME} ALL=(ALL) ALL" > /etc/sudoers.d/${W_USERNAME} && \
    chmod 440 /etc/sudoers.d/${W_USERNAME}

# Copy dbus broker config
COPY assets/systemd/dbus-broker-override.conf /etc/systemd/system/dbus-broker.service.d/override.conf

# Setup tigervnc
RUN echo ":1=${W_USERNAME}" > /etc/tigervnc/vncserver.users && \
    echo -e "session=gnome\ngeometry=${VNC_RESOLUTION}\nlocalhost=no" > /etc/tigervnc/vncserver-config-defaults

# Setup vnc password and file permissions
RUN mkdir -p /home/${W_USERNAME}/.vnc && \
    echo "${W_PASSWORD}" | vncpasswd -f > /home/${W_USERNAME}/.vnc/passwd && \
    chmod 700 /home/${W_USERNAME}/.vnc && \
    chmod 600 /home/${W_USERNAME}/.vnc/passwd && \
    chown -R 1000:0 /home/${W_USERNAME}

# Enable vnc service
RUN systemctl enable vncserver@:1.service

# Install fnm
#RUN su - lemongrass -c 'curl -fsSL https://fnm.vercel.app/install | bash'

# Install node
#RUN su - lemongrass -c 'export PATH="/home/lemongrass/.local/share/fnm:$PATH" && \
#    eval "$(fnm env --shell bash)" && \
#    fnm install 22 && \
#    fnm default 22 && \
#    npm install -g pnpm@latest-11'

# Copy api from builder
#COPY --from=builder --chown=lemongrass:root /app/dist /home/${W_USERNAME}/app/dist
#COPY --from=builder --chown=lemongrass:root /app/package.json /home/${W_USERNAME}/app/package.json
#COPY --from=builder --chown=lemongrass:root /app/pnpm-lock.yaml /home/${W_USERNAME}/app/pnpm-lock.yaml
#COPY --from=builder --chown=lemongrass:root /app/pnpm-workspace.yaml /home/${W_USERNAME}/app/pnpm-workspace.yaml

# Install node dependencies
#RUN su - lemongrass -c 'cd /home/lemongrass/app && \
#    export PATH="/home/lemongrass/.local/share/fnm/aliases/default/bin:$PATH" && \
#    pnpm install --prod --frozen-lockfile'

# Copy and enable api service
#COPY docker/workspace/assets/systemd/lemongrass-api.service /etc/systemd/system/lemongrass-api.service
#RUN systemctl enable lemongrass-api.service

# Install programs
RUN --mount=type=cache,target=/var/cache/libdnf5 \
    dnf -y --setopt=keepcache=True update && \ 
    dnf -y --setopt=keepcache=True install \
      nautilus \
      kitty \
      firefox

COPY assets/glib-schemas/wallpaper.override /usr/share/glib-2.0/schemas/10_local-wallpaper.gschema.override
COPY assets/glib-schemas/accessibility.override /usr/share/glib-2.0/schemas/10_local-accessibility.gschema.override
#COPY assets/glib-schemas/performance.override /usr/share/glib-2.0/schemas/10_local-performance.gschema.override
COPY wallpaper.jpg /usr/share/backgrounds/wallpaper.jpg

RUN glib-compile-schemas /usr/share/glib-2.0/schemas/

# Copy and enable systemd services
COPY assets/systemd/novnc.service /etc/systemd/system/novnc.service
COPY assets/systemd/limespaces-supervisor.service /etc/systemd/system/limespaces-supervisor.service
RUN systemctl enable novnc.service limespaces-supervisor.service

# Use systemd to start the session
CMD ["/sbin/init"]