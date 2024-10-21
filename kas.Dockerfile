# Custom layer atop kas standard image to provide required dependencies
#
# References:
#   - Naming convention: https://docs.docker.com/build/concepts/dockerfile/#filename

# TODO: read these args from kas-container script or refactored env file
ARG KAS_IMAGE_VERSION="4.5"
ARG KAS_CONTAINER_IMAGE_NAME="kas"
ARG KAS_CONTAINER_IMAGE_PATH="ghcr.io/siemens/kas"
ARG KAS_IMAGE_FULL_PATH=${KAS_CONTAINER_IMAGE_PATH}/${KAS_CONTAINER_IMAGE_NAME}:${KAS_IMAGE_VERSION}
FROM ${KAS_IMAGE_FULL_PATH} as kas_base

ARG KAS_UPSTREAM_LOCAL_BASE_PATH

# Install packages and tools used by kas shell invocations
## debian packages
RUN sudo apt-get update && sudo apt-get install --no-install-recommends -y bsdmainutils gettext-base tree util-linux wget
## manual installs
RUN mkdir /tmp/bindl \
    && wget https://github.com/jqlang/jq/releases/latest/download/jq-linux-amd64 -O /tmp/bindl/jq \
    && wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /tmp/bindl/yq \
    && wget https://storage.googleapis.com/git-repo-downloads/repo -O /tmp/bindl/repo \
    && chmod 755 /tmp/bindl/* \
    && sudo mv /tmp/bindl/* /usr/local/bin \
    && echo 'export PATH=/usr/local/bin:${PATH}' | sudo tee -a /etc/profile && cat /etc/profile

# re-install entrypoint script with new content (pulled from my fork/branch in Makefile)
COPY ${KAS_UPSTREAM_LOCAL_BASE_PATH}/container-entrypoint / 
