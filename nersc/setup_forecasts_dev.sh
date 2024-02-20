#!/bin/bash

# Avoid passing parameters from this script to cosmosis
wrapcosmosis() {
    source cosmosis-configure
}


echo "RUNNING DESC_FORECASTS_ENV INTEGRATION VERSION"

SCRIPT=${BASH_SOURCE[0]}

usage() {  # Function: Print a help message.
  echo -e \\n"Help documentation for ${BOLD}${SCRIPT}"\\n
  echo "Command line switches are optional. The following switches are recognized."
  echo "-k  --Setup the env without doing module purge."
  echo "-s  --Setup the env for shifter."
  exit 0
}


# optional parameters
while getopts "ks" flag
do
    case "${flag}" in
        k) keepenv=1;;
        s) shifterenv=1;;
    esac
done

# Check to see if this setup script has already been run in this shell
if [ $DESC_FORECASTS ]
then
    echo "desc_forecasts_env is already set up"
    return 0
fi

export DESC_FORECASTS=/global/cfs/cdirs/lsst/groups/MCP/forecasts
export RUBIN_SIM_DATA_DIR=/dvs_ro/cfs/cdirs/lsst/groups/MCP/software/rubin_sim_data


if [[ -z "$keepenv" ]] && [[ -z $SHIFTER_RUNTIME ]];
then
  module purge
fi


#if [ $shifterenv ] || [ $SHIFTER_RUNTIME ]
#then

#fi

export DESC_FORECASTS_INSTALL=/global/common/software/lsst/gitlab/desc-forecasts-int/dev
#source $DESC_FORECASTS_INSTALL/py/etc/profile.d/conda.sh
#conda activate desc-forecasts
source $DESC_FORECASTS_INSTALL/setup_forecasts_env.sh
    
export PYTHONPATH=$PYTHONPATH:$DESC_FORECASTS_INSTALL
  
wrapcosmosis

# For GCRCatalogs
export DESC_GCR_SITE='nersc'

