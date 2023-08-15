import os
if "DESC_FORECASTS_KEEP_MPI" not in os.environ:
    if "SLURM_JOB_ID" not in os.environ:
        import sys
        sys.modules["mpi4py"] = None

