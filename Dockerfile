# Alpine Image
FROM alpine:3.20.3

# Build Arguments
ARG ALPINE_VERSION="3.20.3" \
        IMAGE_VERSION="2.5.5" \
        PIP_VERSION="24.2.0" \
        PIPX_VERSION="1.7.1" \
        PYTHON_VERSION="3.12.6" \
        PYTHON_VERSION_SHORT="3.12" \
        VDIRSYNCER_VERSION="0.19.3"

# Set up Environment
    # Set Vdirsyncer config location
ENV VDIRSYNCER_CONFIG=/vdirsyncer/config \
        # Set log file
        LOG=/vdirsyncer/vdirsyncer.log \
        # Set Autodiscover
        AUTODISCOVER=false \
        # Set Autosync
        AUTOSYNC=false \
        # Set Cron Time
        CRON_TIME='*/15 * * * *' \
        # Set Timezone
        TZ=Europe/Vienna \
        # Set script path to run after sync complete
        POST_SYNC_SCRIPT_FILE= \
        # Set Pipx home
        PIPX_HOME="/opt/pipx" \
        # Set Pipx bin dir
        PIPX_BIN_DIR="/usr/local/bin" \
        # Supercronic log level
        LOG_LEVEL=

# Update and install packages
RUN echo "**** UID:GID is ${UID}:${GID} ****"
RUN echo "**** UID:GID is ${UID}:${GID} ****" && \
        apk update \
        && apk add --no-cache --upgrade apk-tools \
        && apk upgrade --no-cache --available \
        # Install Pip
        && apk add --no-cache py3-pip \
        # Update Pip
        && pip install --upgrade --break-system-packages pip \
        # Install Pipx
        && pip install --upgrade --break-system-packages pipx \
        # For Curl Commands
        && apk add --no-cache curl \                    
        # For TS
        && apk add --no-cache moreutils \               
        # For Timezone
        && apk add --no-cache tzdata \                  
        # For Sudo Commands
        #&& apk add --no-cache sudo \                    
        # For Usermod                                
        #&& apk add --no-cache shadow \
        # For Scripts and Shell
        && apk add --no-cache bash \
        # Nano Editor
        && apk add --no-cache nano \
        # Cron Update
        #&& apk add --update busybox-suid \
        # Supercronic instead of Cron (for cronjobs)
        && apk add --no-cache supercronic \
        # Clear cache
        && rm -rf /var/cache/apk/*

# Set up Workdir
WORKDIR /vdirsyncer

# Add Files
ADD files /files/

# Set up Timezone
RUN cp "/usr/share/zoneinfo/${TZ}" /etc/localtime \
        && echo "${TZ}" > /etc/timezone

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=1 \
  CMD ps -ef | grep -e "supercronic" | grep -v -e "grep" || exit 1

# Labeling
LABEL maintainer="Bleala" \
        version="${IMAGE_VERSION}" \
        description="Vdirsyncer ${VDIRSYNCER_VERSION} on Alpine ${ALPINE_VERSION}, Pip ${PIP_VERSION}, Pipx ${PIPX_VERSION}, Python ${PYTHON_VERSION}" \
        org.opencontainers.image.source="https://github.com/Bleala/Vdirsyncer-DOCKERIZED" \
        org.opencontainers.image.url="https://github.com/Bleala/Vdirsyncer-DOCKERIZED"

# Vdirsyncer installation
RUN PIPX_HOME="${PIPX_HOME}" PIPX_BIN_DIR="${PIPX_BIN_DIR}" pipx install "vdirsyncer==${VDIRSYNCER_VERSION}" \
        # For Vdirsyncer 0.18.0
        #&& pip install requests-oauthlib
        # For Vdirsyncer 0.19.x (Pip install)
        #&& pip install aiohttp-oauthlib \
        #&& pip install vdirsyncer[google] \
        # For Vdirsyncer 0.19.x (Pipx install)
        && PIPX_HOME="${PIPX_HOME}" PIPX_BIN_DIR="${PIPX_BIN_DIR}" pipx inject vdirsyncer aiohttp-oauthlib \
        && PIPX_HOME="${PIPX_HOME}" PIPX_BIN_DIR="${PIPX_BIN_DIR}" pipx inject vdirsyncer vdirsyncer[google] \
        # Update Path for Pipx
        && PIPX_HOME="${PIPX_HOME}" PIPX_BIN_DIR="${PIPX_BIN_DIR}" pipx ensurepath


# Fix Google redirect uri
# For Vdirsyncer 0.19.1 (Pip Install) 
#RUN sed -i 's~f"http://{host}:{local_server.server_port}"~"http://127.0.0.1:8088"~g' /home/vdirsyncer/.local/lib/python3.10/site-packages/vdirsyncer/storage/google.py
# For Vdirsyncer 0.19.1 (Pipx Install) 
#RUN sed -i 's~f"http://{host}:{local_server.server_port}"~"http://127.0.0.1:8088"~g' "/home/${VDIRSYNCER_USER}/.local/pipx/venvs/vdirsyncer/lib/python3.11/site-packages/vdirsyncer/storage/google.py"
# For Vdirsyncer 0.19.1 (Pipx, Global Install) 
#RUN sed -i 's~f"http://{host}:{local_server.server_port}"~"http://127.0.0.1:8088"~g' "${PIPX_HOME}/venvs/vdirsyncer/lib/python${PYTHON_VERSION_SHORT}/site-packages/vdirsyncer/storage/google.py"
#For Vdirsyncer 0.18.0 - User install
#RUN sed -i 's~urn:ietf:wg:oauth:2.0:oob~http://127.0.0.1:8088~g' /home/vdirsyncer/.local/lib/python3.10/site-packages/vdirsyncer/storage/google.py
#For Vdirsyncer 0.18.0 - Root install
#RUN sed -i 's~urn:ietf:wg:oauth:2.0:oob~http://127.0.0.1:8088~g' /usr/lib/python3.10/site-packages/vdirsyncer/storage/google.py

# Set up permissions
RUN chmod -R +x /files/scripts

# Entrypoint
ENTRYPOINT ["bash","/files/scripts/start.sh"]
