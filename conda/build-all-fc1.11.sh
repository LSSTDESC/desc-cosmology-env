#!/bin/bash


export DESC_INSTALL_DIR=/global/common/software/lsst/gitlab/desc-forecasts-int
export DESC_INSTALL_BUILD=2025-07-22
bash ./Miniforge3-Linux-x86_64.sh -b -p $DESC_INSTALL_DIR/$DESC_INSTALL_BUILD

module load PrgEnv-gnu
module load cpu
module load cray-mpich-abi/8.1.30

source $DESC_INSTALL_DIR/$DESC_INSTALL_BUILD/bin/activate

export PYTHONNOUSERSITE=1

#export CONDA_CACHE_DIR=$PWD/py-all/pkgs  # HMK No longer in use
mamba clean --all -y
export CONDA_PKGS_DIRS=$DESC_INSTALL_BUILD/pkgs
python -m pip cache purge

# NaMaster does now support 3.13
mamba create -y --name desc-firecrown-cosmosis mpi4py compilers mpich=3.4.*=external_* firecrown==1.11.0 ipykernel jupyter rubin_sim python==3.13 namaster tjpcov psycopg2
conda deactivate
conda activate desc-firecrown-cosmosis
conda env config vars set CSL_DIR=${CONDA_PREFIX}/cosmosis-standard-library
cd ${CONDA_PREFIX}
source ${CONDA_PREFIX}/bin/cosmosis-configure
cosmosis-build-standard-library main

curl -LO https://github.com/LSSTDESC/firecrown/archive/refs/tags/v1.11.0.tar.gz
tar xvzf v1.11.0.tar.gz
ln -s firecrown-1.11.0 firecrown


git clone https://github.com/LSSTDESC/augur.git
export AUGUR_DIR=$PWD/augur
cd augur
python -m pip install --no-deps .

cd $DESC_INSTALL_DIR

python -m pip install lsstdesc-dataregistry

# Set permissions
chgrp -R lsst $DESC_INSTALL_DIR/$DESC_INSTALL_BUILD
setfacl -R -m group::rx $DESC_INSTALL_DIR
setfacl -R -d -m group::rx $DESC_INSTALL_DIR

setfacl -R -m user:desc:rwx $DESC_INSTALL_DIR
setfacl -R -d -m user:desc:rwx $DESC_INSTALL_DIR


