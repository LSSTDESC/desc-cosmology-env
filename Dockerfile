# Build container
FROM continuumio/miniconda3:latest as conda

ARG DESC_PYTHON_DIR=/opt/desc
ENV PYTHONDONTWRITEBYTECODE=1
RUN echo $PWD && \
    ls .
ADD conda/desc-cosmology-lock.yml /locks/conda-linux-64.lock
ADD conda/install-mpich.sh /locks/install-mpich.sh


RUN conda install -y -c conda-forge condax && \
    condax install -c conda-forge conda-lock && \
    mkdir $DESC_PYTHON_DIR && \
    ~/.local/bin/conda-lock install --mamba -p $DESC_PYTHON_DIR /locks/conda-linux-64.lock && \
    find /$DESC_PYTHON_DIR -name "*.pyc" -delete && \
    (find $DESC_PYTHON_DIR -name "doc" | xargs rm -Rf) || true 
    
FROM ubuntu:24.04
MAINTAINER Heather Kelly <heather@slac.stanford.edu>

ARG DESC_PYTHON_DIR=/opt/desc
RUN mkdir $DESC_PYTHON_DIR && \
    groupadd -g 1001 -r lsst && useradd -u 1001 --no-log-init -m -r -g lsst lsst && \
    usermod --shell /bin/bash lsst
    
COPY --from=conda $DESC_PYTHON_DIR $DESC_PYTHON_DIR
COPY --from=conda /locks /locks

RUN apt update -y && \
    apt install -y curl \
    build-essential \
    gfortran \
    git \
    patch \
    wget && \
    apt-get clean  && \
    rm -rf /var/cache/apt && \
    chown -R lsst $DESC_PYTHON_DIR && \
    chgrp -R lsst $DESC_PYTHON_DIR && \
    ls -la $DESC_PYTHON_DIR && \
    cd /locks && \
    bash install-mpich.sh 

ARG LSST_USER=lsst
ARG LSST_GROUP=lsst
   
USER lsst

ENV PYTHONDONTWRITEBYTECODE=1

ENV HDF5_USE_FILE_LOCKING=FALSE
ENV PYTHONSTARTUP=''

RUN echo "source /opt/desc/bin/activate" >> ~/.bashrc && \
    echo "source cosmosis-configure" >> ~/.bashrc && \
    echo "export COSMOSIS_NO_SUBPROCESS=1" >> ~/.bashrc && \
    echo "export MPI4PY_RC_RECV_MPROBE=0" >> ~/.bashrc
    
#ENV PATH="${DESC_PYTHON_DIR}/${PY_VER}/bin:${PATH}"
SHELL ["/bin/bash", "--login", "-c"]
