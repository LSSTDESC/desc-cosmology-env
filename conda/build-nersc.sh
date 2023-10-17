#!/bin/bash

module load PrgEnv-gnu
module load cpu
module load cray-mpich-abi/8.1.25
module load evp-patch

unset PYTHONPATH

# Set to 1 to install into the common sofware area
installFlag=$1

export BUILD_ID_DATE=`echo "$(date "+%F-%M-%S")"`
export CI_COMMIT_REF_NAME=integration
export CI_PIPELINE_ID=$BUILD_ID_DATE

commonIntBuildDir=/global/common/software/lsst/gitlab/desc-forecasts-int
commonDevBuildDir=/global/common/software/lsst/gitlab/desc-forecasts-dev
commonProdBuildDir=/global/common/software/lsst/gitlab/desc-forecasts-prod


if [ "$CI_COMMIT_REF_NAME" = "integration" ];  # integration
then
    curBuildDir=$commonIntBuildDir/$CI_PIPELINE_ID
    echo "Integration Install Build: " $curBuildDir
elif [ "$CI_COMMIT_REF_NAME" = "dev" ];  # dev
then
    curBuildDir=$commonDevBuildDir/$CI_PIPELINE_ID
    echo "Dev Install Build: " $curBuildDir
elif [[ "$installFlag" ]];  # Install Prod
then
    if [[ -z "$CI_COMMIT_TAG" ]];
    then
        prodBuildDir=$CI_PIPELINE_ID
    else
        prodBuildDir=$CI_COMMIT_TAG
    fi
    curBuildDir=$commonProdBuildDir/$prodBuildDir
    echo "Prod Build: " $curBuildDir
fi

mkdir -p $curBuildDir
cp conda/condapack.txt $curBuildDir
#cp conda/post-conda-build.sh $curBuildDir
cp conda/pippack.txt $curBuildDir
cp nersc/setup_forecasts_env.sh $curBuildDir
cp nersc/sitecustomize.py $curBuildDir
sed -i 's|$1|'$curBuildDir'|g' $curBuildDir/setup_forecasts_env.sh
cd $curBuildDir


# Build Steps

# Try Mambaforge latest
url="https://github.com/conda-forge/miniforge/releases/latest/download"
url="$url/Mambaforge-Linux-x86_64.sh"
curl -LO "$url"

bash ./Mambaforge-Linux-x86_64.sh -b -p $curBuildDir/py
#source $curBuildDir/py/etc/profile.d/conda.sh
#conda activate base
source $curBuildDir/py/bin/activate
#
export PYTHONNOUSERSITE=1

conda create -y --name desc-forecasts compilers
conda activate desc-forecasts

python -m pip cache purge

mamba install -c conda-forge -y mpich=4.1.2=external_* 
 
cd $curBuildDir
#mamba install -c conda-forge -y --file ./condapack.txt

# Install firecrown in dev mode this will pull in CCL,cobaya, cosmosis
git clone https://github.com/LSSTDESC/firecrown.git
#echo -e "\nmpich=4.1.2=external_*" >> firecrown/environment.yml
mamba env update --name desc-forecasts -f firecrown/environment.yml
conda activate desc-forecasts
mamba install -c conda-forge -y mpich=4.1.2=external_* 
source ${CONDA_PREFIX}/bin/cosmosis-configure
cosmosis-build-standard-library

export CSL_DIR=${PWD}/cosmosis-standard-library
export FIRECROWN_DIR=${PWD}/firecrown
export PYTHONPATH=${FIRECROWN_DIR}/build/lib

cd firecrown
python setup.py build
python -m pytest -vv

cd $curBuildDir

#export COSMOSIS_SRC_DIR=${CONDA_PREFIX}/lib/python3.11/site-packages/cosmosis
#export COSMOSIS_ALT_COMPILERS=1
#export CC=gcc
#export CXX=g++
#export FC=gfortran
#export MPIFC=ftn
#export MPIF90=ftn
#export COSMOSIS_OMP=1

# Environment variables for compilation
#export LAPACK_LINK="-L$CRAY_LIBSCI_PREFIX_DIR/lib -lsci_gnu"
#export GSL_DIR=${CONDA_PREFIX}
#export FFTW_LIBRARY=${CONDA_PREFIX}/lib
#export GSL_INC=$GSL_DIR/include
#export GSL_LIB=$GSL_DIR/lib
#export FFTW_INCLUDE_DIR=${CONDA_PREFIX}/include
#export CFITSIO_DIR=${CONDA_PREFIX}
#export CFITSIO_INC=$CFITSIO_DIR/include
#export CFITSIO_LIB=$CFITSIO_DIR/lib
    


# Download and build the CosmoSIS standard library
# in a directory under the CosmoSIS python directory
#cosmosis-build-standard-library 
#-i
#git clone https://github.com/joezuntz/cosmosis-standard-library
#cd cosmosis-standard-library
#make

#cosmosis-build-standard-library -i

#conda env config vars set CSL_DIR="${PWD}/cosmosis-standard-library" FIRECROWN_DIR="${PWD}/firecrown" PYTHONPATH="${PWD}/firecrown/build/lib" AUGUR_DIR="${PWD}/augur" PYTHONNOUSERSITE=1
#conda env config vars set CSL_DIR="$CONDA_PREFIX/lib/python3.10/site-packages/cosmosis/cosmosis-standard-library" FIRECROWN_DIR="${PWD}/firecrown" PYTHONPATH="${PWD}/firecrown/build/lib" AUGUR_DIR="${PWD}/augur" PYTHONNOUSERSITE=1
conda env config vars set CSL_DIR="${PWD}/cosmosis-standard-library" FIRECROWN_DIR="${PWD}/firecrown" PYTHONPATH="${PWD}/firecrown/build/lib" AUGUR_DIR="${PWD}/augur" PYTHONNOUSERSITE=1

#pip install --no-cache-dir -r ./pippack.txt

# Grab firecrown source so we have the examples subdirectory
#firecrown_ver=$(conda list firecrown | grep firecrown|tr -s " " | cut -d " " -f 2)
#echo $firecrown_ver
#curl -LO https://github.com/LSSTDESC/firecrown/archive/refs/tags/v$firecrown_ver.tar.gz
#tar xvzf v$firecrown_ver.tar.gz
# Set up a common directory name without version info to set FIRECROWN_DIR more easily
#ln -s firecrown-$firecrown_ver firecrown

#cd ${PWD}/firecrown
#python setup.py build
#export FIRECROWN_DIR="$curBuildDir/firecrown"
#python -m pytest -vv

#cd $curBuildDir
#git clone https://github.com/LSSTDESC/TJPCov.git
#cd TJPCov
#python -m pip install .\[full\]

cd $curBuildDir
git clone https://github.com/LSSTDESC/augur.git
pip install --no-deps augur/
#cd augur
#python setup.py install

cd $curBuildDir

#mamba install -c conda-forge -y --file ./packlist.txt

python -m compileall $curBuildDir/py
conda clean -y -a 

# Additional build steps
#bash ./post-conda-build.sh

#CONDA_PREFIX="" pip install -v  --no-cache cosmosis
#cd $curBuildDir
#git clone https://github.com/joezuntz/cosmosis-standard-library
#cd cosmosis-standard-library
#make

conda config --set env_prompt "(desc-forecasts-env-$1)" --env

conda env export --no-builds > $curBuildDir/desc-forecasts-env-nersc-$CI_PIPELINE_ID-nobuildinfo.yml
conda env export > $curBuildDir/desc-forecasts-nersc-$CI_PIPELINE_ID.yml


# Set permissions
setfacl -R -m group::rx $curBuildDir
setfacl -R -d -m group::rx $curBuildDir

setfacl -R -m user:desc:rwx $curBuildDir
setfacl -R -d -m user:desc:rwx $curBuildDir
