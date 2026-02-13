#!/bin/bash

setup_conda() {
  source $curBuildDir/py/etc/profile.d/conda.sh
  conda activate base
}

wrap_cosmosis() {
  source ${CONDA_PREFIX}/bin/cosmosis-configure
  cosmosis-build-standard-library main
}

if [ -z "$1" ]
then
	echo "Please provide a full path install directory"
	exit 1
fi

if [ -z "$2" ]
then
	echo "Please provide a conda pack txt file"
	exit 1
fi

if [ -z "$3" ]
then
	echo "Please provide a pip pack txt file"
	exit 1
fi

unset PYTHONPATH

curBuildDir=$1

mkdir -p $curBuildDir
cp $2 $curBuildDir
#cp conda/post-conda-build.sh $curBuildDir
cp $3 $curBuildDir
#cp nersc/setup-cosmology-env.sh $curBuildDir
#cp nersc/sitecustomize.py $curBuildDir
sed -i 's|$1|'$curBuildDir'|g' $curBuildDir/setup-cosmology-env.sh
cd $curBuildDir


# Build Steps

# Try Mambaforge latest
url="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
curl -LO "$url"

bash ./Miniforge3-Linux-x86_64.sh -b -p $curBuildDir/py
setup_conda
#source $curBuildDir/py/bin/activate
#
export PYTHONNOUSERSITE=1

mamba clean --all -y
export CONDA_PKGS_DIRS=$curBuildDir/pkgs

conda config --add channels conda-forge/label/mpi-external
conda config --set channel_priority strict

#conda create -y --name desc-cosmology compilers
#conda activate desc-cosmology

python -m pip cache purge

#mamba install -c conda-forge -y compilers mpich=4.3.2=external_* 
#conda install -c conda-forge/label/mpi-external -y mpich
#conda install -y conda-forge/label/mpi-external:mpich=4.3.2
conda install -y "conda-forge/label/mpi-external::mpich[version='>=4.3']"
mamba install -c conda-forge -y compilers
 
cd $curBuildDir

conda install -c conda-forge/label/mpi-external -c conda-forge -y --file $2
conda install -y "conda-forge/label/mpi-external::mpich[version='>=4.3']"
#conda deactivate
#conda activate desc-cosmology 
conda env config vars set CSL_DIR=${CONDA_PREFIX}/cosmosis-standard-library
cd ${CONDA_PREFIX}
#source ${CONDA_PREFIX}/bin/cosmosis-configure
#cosmosis-build-standard-library main
wrap_cosmosis

#export CSL_DIR=${PWD}/cosmosis-standard-library
#export FIRECROWN_DIR=${PWD}/firecrown
#export PYTHONPATH=${FIRECROWN_DIR}/build/lib

cd $curBuildDir

# could also find FIRECROWN DIR by doing
# FIRECROWN_DIR=$(python -c "import firecrown; print('/'.join(firecrown.__spec__.submodule_search_locations[0].split('/')[0:-1]))") + "/firecrown"

pip install --no-cache-dir -r $3


cd $curBuildDir
FIRECROWN_VER=1.14.0
curl -LO https://github.com/LSSTDESC/firecrown/archive/refs/tags/v$FIRECROWN_VER.tar.gz
tar xvzf v$FIRECROWN_VER.tar.gz
ln -s firecrown-$FIRECROWN_VER firecrown

cd $curBuildDir
# Find latest tag
git clone --depth 1 --branch "$(git ls-remote --tags --sort=-v:refname https://github.com/LSSTDESC/augur.git | grep -o 'refs/tags/[^{}]*' | head -n 1 | sed 's|refs/tags/||')" https://github.com/LSSTDESC/augur.git
cd augur
python -m pip install --no-deps .

cd $curBuildDir

export FC_DIR=$(python -c "import firecrown; print('/'.join(firecrown.__spec__.submodule_search_locations[0].split('/')[0:-1]))")""

export AG_DIR=$(python -c "import augur; print('/'.join(augur.__spec__.submodule_search_locations[0].split('/')[0:-1]))")""

conda env config vars set CSL_DIR="${CONDA_PREFIX}/cosmosis-standard-library" FIRECROWN_DIR="${FC_DIR}" AUGUR_DIR="${AG_DIR}" 

#python -m pip install lsstdesc-dataregistry
#python3 -c "import dataregistry; print(dataregistry.__version__)"

python -m compileall $curBuildDir/py
conda clean -y -a 

conda config --set env_prompt "(desc-cosmology)" --env

conda env export --no-builds > $curBuildDir/desc-cosmology-nobuildinfo.yml
conda env export > $curBuildDir/desc-cosmology-$CI_PIPELINE_ID.yml


# Set permissions
#setfacl -R -m group::rx $curBuildDir
#setfacl -R -d -m group::rx $curBuildDir
chmod -R g+rx $curBuildDir
