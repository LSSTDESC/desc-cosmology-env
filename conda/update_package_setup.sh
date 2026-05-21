#!/bin/bash

#if [ "$USER" != "desctd" ]; then
#    echo "Error: must be run as 'desctd'"
#    echo "ssh to dtn.nersc.gov and run 'collabsu desctd' first"
#    exit 1
#fi


# Allows --user install
unset PYTHONNOUSERSITE

# Point to the area where --user packages should be installed
export PYTHONUSERBASE=$COSMOLOGY_EXTRA_PACKAGES

echo "Ready to pip install packages\n"
echo "pip install --user --no-deps --no-build-isolation <packageName>\n"
echo "If updating a package include the -U option\n"

