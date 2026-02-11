FROM ubuntu:22.04
LABEL maintainer="Heather Kelly <heather@slac.stanford.edu>"

#ARG DESC_PYTHON_DIR=/opt/desc
ARG DESC_PYTHON_DIR=/usr/local


RUN apt update -y && \
    apt install -y curl \
    build-essential \
    gfortran \
    git \
    patch \
    wget && \
    apt-get clean  && \
    rm -rf /var/cache/apt && \
    groupadd -g 1000 -r lsst && useradd -u 1000 --no-log-init -m -r -g lsst lsst && \
    usermod --shell /bin/bash lsst && \
    mkdir -p /usr/local && \
    mkdir /opt/tmp && cd /opt/tmp && \
    git clone https://github.com/LSSTDESC/desc-cosmology-env && \
    cd desc-cosmology-env && \
    cd conda && \ 
    bash install-mpich.sh && \
    cd /opt/tmp && \
    chown -R lsst desc-cosmology-env && \ 
    mkdir -p $DESC_PYTHON_DIR && \
    chown lsst $DESC_PYTHON_DIR && \
    chgrp lsst $DESC_PYTHON_DIR

ARG LSST_USER=lsst
ARG LSST_GROUP=lsst


WORKDIR $DESC_PYTHON_DIR
   
USER lsst

ENV PYTHONDONTWRITEBYTECODE 1

RUN cd /opt/tmp/desc-cosmology-env/conda && \ 
    bash docker-install.sh /usr/local ./condapack.txt ./pippack.txt && \
    find /$DESC_PYTHON_DIR -name "*.pyc" -delete

    
ENV HDF5_USE_FILE_LOCKING FALSE
ENV PYTHONSTARTUP ''


RUN echo "source /usr/local/py/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc
    
ENV PATH="${DESC_PYTHON_DIR}/${PY_VER}/bin:${PATH}"
SHELL ["/bin/bash", "--login", "-c"]


