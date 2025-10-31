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

cd $curBuildDir

# could also find FIRECROWN DIR by doing
# FIRECROWN_DIR=$(python -c "import firecrown; print('/'.join(firecrown.__spec__.submodule_search_locations[0].split('/')[0:-1]))") + "/firecrown"

pip install --no-cache-dir -r ./pippack.txt


cd $curBuildDir
FIRECROWN_VER=1.14.0
curl -LO https://github.com/LSSTDESC/firecrown/archive/refs/tags/v$FIRECROWN_VER.tar.gz
tar xvzf v$FIRECROWN_VER.tar.gz
ln -s firecrown-$FIRECROWN_VER firecrown

cd $curBuildDir
# Find latest tag
git clone --depth 1 --branch "$(git ls-remote --tags --sort=-v:refname https://github.com/LSSTDESC/augur.git | grep -o 'refs/tags/[^{}]*' | head -n 1 | sed 's|refs/tags/||')" https://github.com/LSSTDESC/augur.git
#AUGUR_VER=1.1.1
##curl -LO https://github.com/LSSTDESC/augur/archive/refs/tags/$AUGUR_VER.tar.gz
#tar xvzf $AUGUR_VER.tar.gz
#ln -s augur-$AUGUR_VER augur
#git clone https://github.com/LSSTDESC/augur.git
cd augur
python -m pip install --no-deps .

cd $curBuildDir

export FC_DIR=$(python -c "import firecrown; print('/'.join(firecrown.__spec__.submodule_search_locations[0].split('/')[0:-1]))")""

export AG_DIR=$(python -c "import augur; print('/'.join(augur.__spec__.submodule_search_locations[0].split('/')[0:-1]))")""

conda env config vars set CSL_DIR="${CONDA_PREFIX}/cosmosis-standard-library" FIRECROWN_DIR="${FC_DIR}" AUGUR_DIR="${AG_DIR}" PYTHONNOUSERSITE=1

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
