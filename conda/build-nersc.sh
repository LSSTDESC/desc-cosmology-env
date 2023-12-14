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
source $curBuildDir/py/bin/activate
#
export PYTHONNOUSERSITE=1

conda create -y --name desc-forecasts compilers
conda activate desc-forecasts

python -m pip cache purge

mamba install -c conda-forge -y mpich=4.1.2=external_* 
 
cd $curBuildDir

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

mamba install -c conda-forge -y --file ./condapack.txt
#
cd firecrown
python setup.py build
python -m pytest -vv

cd $curBuildDir

conda env config vars set CSL_DIR="${PWD}/cosmosis-standard-library" FIRECROWN_DIR="${PWD}/firecrown" PYTHONPATH="${PWD}/firecrown/build/lib" AUGUR_DIR="${PWD}/augur" PYTHONNOUSERSITE=1

#pip install --no-cache-dir -r ./pippack.txt

#install TJPCov cclv3 branch
cd $curBuildDir
git clone https://github.com/LSSTDESC/TJPCov.git
cd TJPCov
git checkout cclv3
python -m pip install -e .
pytest -vv tests/test_covariance_gaussian_fsky.py


cd $curBuildDir
git clone https://github.com/LSSTDESC/augur.git
pip install --no-deps augur/
#cd augur
#python setup.py install

cd $curBuildDir

#install data-registry
git clone https://github.com/LSSTDESC/dataregistry.git
cd dataregistry
python3 -m pip install .

cd $curBuildDir
python3 -c "import dataregistry; print(dataregistry.__version__)"


python -m compileall $curBuildDir/py
conda clean -y -a 

# Additional build steps
#bash ./post-conda-build.sh

conda config --set env_prompt "(desc-forecasts-env-$1)" --env

conda env export --no-builds > $curBuildDir/desc-forecasts-env-nersc-$CI_PIPELINE_ID-nobuildinfo.yml
conda env export > $curBuildDir/desc-forecasts-nersc-$CI_PIPELINE_ID.yml


# Set permissions
setfacl -R -m group::rx $curBuildDir
setfacl -R -d -m group::rx $curBuildDir

setfacl -R -m user:desc:rwx $curBuildDir
setfacl -R -d -m user:desc:rwx $curBuildDir
