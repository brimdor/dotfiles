FROM ubuntu:22.04

LABEL maintainer="Brimdor <https://homelab.eaglepass.io>"

ARG USER=brimdor
ARG group=brimdor
ARG uid=1000
ARG DEBIAN_FRONTEND=noninteractive

ENV TZ="America/Chicago"

USER ${USER}
USER root

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
  sudo \
  curl \
  git-core \
  gnupg \
  locales \
  tzdata \
  wget && \
  apt-get autoremove -y

RUN locale-gen en_US.UTF-8

RUN adduser --quiet --disabled-password \
  --shell /bin/bash --home /home/${USER} \
  --gecos "User" ${USER}

RUN mkdir -p /etc/sudoers.d && \
  touch /etc/sudoers.d/${USER} && \
  echo "%${group} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${USER} && \
  groupadd docker && \
  usermod -aG docker ${USER}

RUN chown -R ${USER}:${group} /home/${USER}
USER ${USER}

COPY --chown=${USER}:${group} bin/dotfiles /home/${USER}/dotfiles

RUN \
  mkdir -p /home/${USER}/.ansible-vault && \
  touch /home/${USER}/.ansible-vault/vault.secret && \
  echo '$vault_secret' > /home/${USER}/.ansible-vault/vault.secret

# RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/Brimdor/dotfiles/main/bin/dotfiles)"
RUN git clone --quiet https://github.com/Brimdor/dotfiles.git /home/${USER}/.dotfiles
COPY --chown=${USER}:${group} ansible.cfg /home/${USER}/.dotfiles/ansible.cfg
RUN bash -c "/home/${USER}/dotfiles"

RUN rm ~/.ansible-vault/vault.secret

# CMD []
#
# ENTRYPOINT ["/bin/bash"]
