#!/bin/bash

# Avoid passing parameters from this script to cosmosis
wrapcosmosis() {
    source cosmosis-configure
}

echo "RUNNING DESC-COSMOLOGY DEV VERSION"

SCRIPT=${BASH_SOURCE[0]}

usage() {  # Function: Print a help message.
  echo -e \\n"Help documentation for ${BOLD}${SCRIPT}"\\n
  echo "Command line switches are optional. The following switches are recognized."
  echo "-s  --Setup the env for shifter."
  exit 0
}


# optional parameters
while getopts "ks" flag
do
    case "${flag}" in
        s) shifterenv=1;;
    esac
done

# Check to see if this setup script has already been run in this shell
if [ $DESC_COSMOLOGY ]
then
    echo "desc-cosmology is already set up"
    return 0
fi

export DESC_COSMOLOGY=/global/cfs/cdirs/lsst/groups/MCP/cosmology
export RUBIN_SIM_DATA_DIR=/dvs_ro/cfs/cdirs/lsst/groups/MCP/software/rubin_sim_data


export DESC_COSMOLOGY_INSTALL=/global/common/software/lsst/gitlab/desc-cosmology/dev
source $DESC_COSMOLOGY_INSTALL/setup-cosmology-env.sh $DESC_COSMOLOGY_INSTALL
    
#export PYTHONPATH=$PYTHONPATH:$DESC_COSMOLOGY_INSTALL
  
wrapcosmosis

# For GCRCatalogs
export DESC_GCR_SITE='nersc'

