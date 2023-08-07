#!/bin/bash

module load PrgEnv-gnu
module load cpu
module load cray-mpich-abi/8.1.25
module load evp-patch

unset PYTHONPATH

# Set to 1 to install into the common sofware area
installFlag=$1

export BUILD_ID_DATE=`echo "$(date "+%F-%M-%S")"`
export CI_COMMIT_REF_NAME=prod
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
#cp conda/packlist.txt $curBuildDir
cp conda/post-conda-build.sh $curBuildDir
#cp conda/piplist.txt $curBuildDir
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
source $curBuildDir/py/etc/profile.d/conda.sh
conda activate base

mamba install -c conda-forge -y mpich=4.0.3=external_* 

# Install firecrown in dev mode this will pull in CCL,cobaya, cosmosis
git clone https://github.com/LSSTDESC/firecrown.git
conda env update --name desc-forecasts -f firecrown/environment.yml
source ${CONDA_PREFIX}/bin/cosmosis-configure
# Download and build the CosmoSIS standard library
# in a directory under the CosmoSIS python directory
cosmosis-build-standard-library 
#-i

conda env config vars set CSL_DIR="${PWD}/cosmosis-standard-library" FIRECROWN_DIR="${PWD}/firecrown" PYTHONPATH="${PWD}/firecrown/build/lib"

#mamba install -c conda-forge -y --file ./packlist.txt
#pip install --no-cache-dir -r ./piplist.txt

conda clean -y -a 


# Additional build steps
#bash ./post-conda-build.sh


python -m compileall $curBuildDir

conda config --set env_prompt "(desc-forecasts-env-$1)" --system

conda env export --no-builds > $curBuildDir/desc-forecasts-env-nersc-$CI_PIPELINE_ID-nobuildinfo.yml
conda env export > $curBuildDir/desc-forecasts-nersc-$CI_PIPELINE_ID.yml


# Set permissions
setfacl -R -m group::rx $curBuildDir
setfacl -R -d -m group::rx $curBuildDir

setfacl -R -m user:desc:rwx $curBuildDir
setfacl -R -d -m user:desc:rwx $curBuildDir
