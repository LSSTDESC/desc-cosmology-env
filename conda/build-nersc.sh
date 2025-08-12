#!/bin/bash

module load PrgEnv-gnu
module load cpu
module load cray-mpich-abi/8.1.30

unset PYTHONPATH

# Set to 1 to install into the common sofware area
installFlag=$1

export BUILD_ID_DATE=`echo "$(date "+%F-%M-%S")"`
export CI_COMMIT_REF_NAME=integration
export CI_PIPELINE_ID=$BUILD_ID_DATE

commonIntBuildDir=/global/common/software/lsst/gitlab/desc-cosmology-int
commonDevBuildDir=/global/common/software/lsst/gitlab/desc-cosmology-dev
commonBuildDir=/global/common/software/lsst/gitlab/desc-cosmology


if [ "$CI_COMMIT_REF_NAME" = "integration" ];  # integration
then
    curBuildDir=$commonBuildDir/$CI_PIPELINE_ID
    echo "Integration Install Build: " $curBuildDir
elif [ "$CI_COMMIT_REF_NAME" = "dev" ];  # dev
then
    curBuildDir=$commonBuildDir/$CI_PIPELINE_ID
    echo "Dev Install Build: " $curBuildDir
elif [[ "$installFlag" ]];  # Install Prod
then
    if [[ -z "$CI_COMMIT_TAG" ]];
    then
        prodBuildDir=$CI_PIPELINE_ID
    else
        prodBuildDir=$CI_COMMIT_TAG
    fi
    curBuildDir=$commonBuildDir/$prodBuildDir
    echo "Prod Build: " $curBuildDir
fi

mkdir -p $curBuildDir
cp conda/condapack.txt $curBuildDir
#cp conda/post-conda-build.sh $curBuildDir
cp conda/pippack.txt $curBuildDir
cp nersc/setup-cosmology-env.sh $curBuildDir
cp nersc/sitecustomize.py $curBuildDir
sed -i 's|$1|'$curBuildDir'|g' $curBuildDir/setup-cosmology-env.sh
cd $curBuildDir


# Build Steps

# Try Mambaforge latest
url="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
curl -LO "$url"

bash ./Miniforge3-Linux-x86_64.sh -b -p $curBuildDir/py
source $curBuildDir/py/bin/activate
#
export PYTHONNOUSERSITE=1

mamba clean --all -y
export CONDA_PKGS_DIRS=$curBuildDir/pkgs

conda create -y --name desc-cosmology compilers
conda activate desc-cosmology

python -m pip cache purge

mamba install -c conda-forge -y mpich=3.4.*=external_* 
 
cd $curBuildDir

mamba install -c conda-forge -y --file ./condapack.txt
conda deactivate
conda activate desc-cosmology 
conda env config vars set CSL_DIR=${CONDA_PREFIX}/cosmosis-standard-library
cd ${CONDA_PREFIX}
source ${CONDA_PREFIX}/bin/cosmosis-configure
cosmosis-build-standard-library main

#export CSL_DIR=${PWD}/cosmosis-standard-library
#export FIRECROWN_DIR=${PWD}/firecrown
#export PYTHONPATH=${FIRECROWN_DIR}/build/lib


#conda env config vars set CSL_DIR="${PWD}/cosmosis-standard-library" FIRECROWN_DIR="${PWD}/firecrown" PYTHONPATH="${PWD}/firecrown/build/lib" AUGUR_DIR="${PWD}/augur" PYTHONNOUSERSITE=1

pip install --no-cache-dir -r ./pippack.txt

#install TJPCov cclv3 branch
#cd $curBuildDir
#git clone https://github.com/LSSTDESC/TJPCov.git
#cd TJPCov
#git checkout cclv3
#python -m pip install -e .
#pytest -vv tests/test_covariance_gaussian_fsky.py


cd $curBuildDir
git clone https://github.com/LSSTDESC/augur.git
export AUGUR_DIR=$PWD/augur
cd augur
python -m pip install --no-deps .
#cd augur
#python setup.py install

cd $curBuildDir

python -m pip install lsstdesc-dataregistry
python3 -c "import dataregistry; print(dataregistry.__version__)"

python -m compileall $curBuildDir/py
conda clean -y -a 

# Additional build steps
#bash ./post-conda-build.sh

conda config --set env_prompt "(desc-cosmology-$1)" --env

conda env export --no-builds > $curBuildDir/desc-cosmology-nersc-$CI_PIPELINE_ID-nobuildinfo.yml
conda env export > $curBuildDir/desc-cosmology-nersc-$CI_PIPELINE_ID.yml


# Set permissions
setfacl -R -m group::rx $curBuildDir
setfacl -R -d -m group::rx $curBuildDir

setfacl -R -m user:desc:rwx $curBuildDir
setfacl -R -d -m user:desc:rwx $curBuildDir
