# Build this image:  docker build -t mpi .
#

FROM ubuntu:latest
# FROM phusion/baseimage

MAINTAINER Ole Weidner <ole.weidner@ed.ac.uk>

ENV USER mpirun

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/${USER} 
    
RUN apt update -y && \
    apt install -y curl software-properties-common && \
    curl -o /etc/apt/trusted.gpg.d/openfoam.asc https://dl.openfoam.org/gpg.key && \
    add-apt-repository "http://dl.openfoam.org/ubuntu dev"
    
RUN apt update -y && \
    apt install -y --no-install-recommends sudo apt-utils && \
    apt install -y --no-install-recommends openssh-server openfoam-dev libopenmpi-dev openmpi-bin openmpi-common openmpi-doc binutils && \
    apt clean && apt-get purge && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /var/run/sshd
RUN echo 'root:${USER}' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# ------------------------------------------------------------
# Add an 'mpirun' user
# ------------------------------------------------------------

RUN adduser --disabled-password --gecos "" ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ------------------------------------------------------------
# Set-Up SSH with our Github deploy key
# ------------------------------------------------------------

ENV SSHDIR ${HOME}/.ssh/

RUN mkdir -p ${SSHDIR}

ADD ssh/config ${SSHDIR}/config
ADD ssh/id_rsa.mpi ${SSHDIR}/id_rsa
ADD ssh/id_rsa.mpi.pub ${SSHDIR}/id_rsa.pub
ADD ssh/id_rsa.mpi.pub ${SSHDIR}/authorized_keys

RUN chmod -R 600 ${SSHDIR}* && \
    chown -R ${USER}:${USER} ${SSHDIR}

USER ${USER}

# ------------------------------------------------------------
# Configure OpenMPI
# ------------------------------------------------------------

USER root

RUN rm -fr ${HOME}/.openmpi && mkdir -p ${HOME}/.openmpi
ADD default-mca-params.conf ${HOME}/.openmpi/mca-params.conf
RUN chown -R ${USER}:${USER} ${HOME}/.openmpi

# ------------------------------------------------------------
# Add bashrc to mpirun user's bashrc
# ------------------------------------------------------------

RUN echo "source /opt/openfoam-dev/etc/bashrc" >> /home/mpirun/.bashrc
ENV TRIGGER 1

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
