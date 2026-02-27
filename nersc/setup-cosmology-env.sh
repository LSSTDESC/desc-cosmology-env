#!/bin/bash

module load PrgEnv-gnu
module load cpu
module load cray-mpich-abi/8.1.30
module load cudatoolkit

export DESC_LSST_INSTALL_DIR=$1

source $DESC_LSST_INSTALL_DIR/py/bin/activate
conda activate desc-cosmology

# Need to allow --user installs
export PYTHONNOUSERSITE=0

# Set this after conda environment is setup
python_ver_major=$(python -c 'import sys; print(sys.version_info.major)')
python_ver_minor=$(python -c 'import sys; print(sys.version_info.minor)')
export DESCPYTHONVER="python$python_ver_major.$python_ver_minor"

if [ -n "$DESC_COSMO_USERBASE" ]; then
    export PYTHONUSERBASE=$DESC_COSMO_USERBASE
    unset PYTHONUSERSITE
    export PATH=$PYTHONUSERBASE/bin:$PATH
    export PYTHONPATH="$PYTHONUSERBASE/lib/$DESCPYTHONVER/site-packages:$PYTHONPATH"
    echo "using DESC_COSMO_USERBASE: $DESC_COSMO_USERBASE"
fi

# For cosmosis and firecrown.  Should try to find a better way to set these
#export CSL_DIR=$CONDA_PREFIX/lib/python3.10/site-packages/cosmosis/cosmosis-standard-library
#export FIRECROWN_SITE_PACKAGES=$CONDA_PREFIX/lib/python3.10/site-packages
#export FIRECROWN_DIR=$CONDA_PREFIX/firecrown
#export AUGUR_DIR=$CONDA_PREFIX/augur
#export FIRECROWN_EXAMPLES_DIR=$FIRECROWN_DIR/examples

# Fixes missing support in the Perlmutter libfabric:
# https://docs.nersc.gov/development/languages/python/using-python-perlmutter/#missing-support-for-matched-proberecv
export MPI4PY_RC_RECV_MPROBE=0

# Tries to prevent cosmosis from launching any subprocesses, since that is 
# not allowed on Perlmutter.
export COSMOSIS_NO_SUBPROCESS=1
