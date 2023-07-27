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

commonIntBuildDir=/global/common/software/lsst/gitlab/example_env-int
commonDevBuildDir=/global/common/software/lsst/gitlab/example_env-dev
commonProdBuildDir=/global/common/software/lsst/gitlab/exa,ple_env-prod


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
cp conda/packlist.txt $curBuildDir
cp conda/post-conda-build.sh $curBuildDir
cp conda/piplist.txt $curBuildDir
cp nersc/setup_example_env.sh $curBuildDir
cp nersc/sitecustomize.py $curBuildDir
sed -i 's|$1|'$curBuildDir'|g' $curBuildDir/setup_example_env.sh
cd $curBuildDir


# Build Steps

mamba install -c conda-forge -y mpich=4.3.*=external_*

mamba install -c conda-forge -y --file ./packlist.txt
pip install --no-cache-dir -r ./piplist.txt

conda clean -y -a 



# Grab firecrown source so we have the examples subdirectory
firecrown_ver=$(conda list firecrown | grep firecrown|tr -s " " | cut -d " " -f 2)
echo $firecrown_ver
curl -LO https://github.com/LSSTDESC/firecrown/archive/refs/tags/v$firecrown_ver.tar.gz
tar xvzf v$firecrown_ver.tar.gz
# Set up a common directory name without version info to set FIRECROWN_DIR more easily
ln -s firecrown-$firecrown_ver firecrown

# Additional build steps
bash ./post-conda-build.sh


python -m compileall $curBuildDir


conda config --set env_prompt "(example-env-$1)" --system

conda env export --no-builds > $curBuildDir/example_env-nersc-$CI_PIPELINE_ID-nobuildinfo.yml
conda env export > $curBuildDir/example_env-nersc-$CI_PIPELINE_ID.yml


# Set permissions
setfacl -R -m group::rx $curBuildDir
setfacl -R -d -m group::rx $curBuildDir

setfacl -R -m user:desc:rwx $curBuildDir
setfacl -R -d -m user:desc:rwx $curBuildDir
