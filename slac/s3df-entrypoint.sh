#!/bin/bash
source /opt/desc/etc/profile.d/conda.sh
conda activate /opt/desc
# loading docker image into apptainer seems to impact some env variables, that now need to be redefined
export COSMOSIS_SRC_DIR=/opt/desc/lib/python3.11/site-packages/cosmosis
source /opt/desc/bin/cosmosis-configure 2>/dev/null || true
export PMIX_MCA_psec=native
export LD_LIBRARY_PATH="/opt/desc/lib/python3.11/site-packages/cosmosis/datablock":${LD_LIBRARY_PATH}
exec "$@"
