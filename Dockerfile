FROM mpioperator/openmpi

RUN apt update -y && \
    apt install -y curl software-properties-common && \
    curl -o /etc/apt/trusted.gpg.d/openfoam.asc https://dl.openfoam.org/gpg.key && \
    add-apt-repository "http://dl.openfoam.org/ubuntu dev" && \
    apt update -y && \
    apt install -y --no-install-recommends openfoam-dev
