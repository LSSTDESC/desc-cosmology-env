#!/bin/bash
set -e

# -----------------------------------------------------------------------------
# UID/GID remap (docker-run use case only)
#
# If we're root and LOCAL_UID/LOCAL_GID are set, remap the lsst user/group to
# match the host user, fix ownership of the dirs it needs to write to, then
# drop privileges and re-exec this same script as lsst.
#
# Under Apptainer this whole ENTRYPOINT is ignored (Apptainer runs as the
# host user directly and never invokes it), so this block never runs there.
# If invoked as non-root without LOCAL_UID/LOCAL_GID set (e.g. `docker run
# --user`), it's a no-op and falls through to the env setup below.
# -----------------------------------------------------------------------------
if [ "$(id -u)" = "0" ] && [ -n "${LOCAL_UID}" ] && [ -n "${LOCAL_GID}" ]; then
    CURRENT_UID=$(id -u lsst)
    CURRENT_GID=$(id -g lsst)

    if [ "${LOCAL_GID}" != "${CURRENT_GID}" ]; then
        groupmod -o -g "${LOCAL_GID}" lsst
    fi
    if [ "${LOCAL_UID}" != "${CURRENT_UID}" ]; then
        usermod -o -u "${LOCAL_UID}" lsst
    fi
    chown -R lsst:lsst /home/lsst /opt/desc >/dev/null 2>&1 || true

    # Re-exec as lsst so the env-setup logic below runs as the right user,
    # not as root.
    exec gosu lsst "$0" "$@"
fi

# -----------------------------------------------------------------------------
# Conda / CosmoSIS environment setup (runs regardless of how we got here —
# root-skip case above, plain non-root docker run, or Apptainer)
# -----------------------------------------------------------------------------
source /opt/desc/etc/profile.d/conda.sh
conda activate /opt/desc

# loading docker image into apptainer seems to impact some env variables, that now need to be redefined
export COSMOSIS_SRC_DIR=/opt/desc/lib/python3.13/site-packages/cosmosis
source /opt/desc/bin/cosmosis-configure 2>/dev/null || true
export PMIX_MCA_psec=native
export LD_LIBRARY_PATH="/opt/desc/lib/python3.13/site-packages/cosmosis/datablock":${LD_LIBRARY_PATH}

exec "$@"

