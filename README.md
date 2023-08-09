# Gromacs + Plumed + Python Docker Container

Prebuild Gromacs patched with Plumed, wrapped in Docker container for convenient use. Supports multiple CPU architectures and NVIDIA GPUs.
Currently Cuda 11.2 is used, which requires NVIDIA drivers 450.80.02 and later (https://docs.nvidia.com/deploy/cuda-compatibility/index.html)

Versions of Gromacs and Docker are specified in Dockerfile here.

Multiple Python versions are added for testing against using github actions.  
By default, 3.9, 3.10, 3.11 are made available.

## Build

To build the docker container, set the name you like in the make file and run:

	$make

The container will be tagged like riedmiki/gromacs-plumed-python:GROMACS_VERSION  

To point the wrapper `gmx-docker.sh` to the new image run  

	$make wrapper

And push to a registry with

	$make push

All combined in

	$make all


## Run in Docker

At least Docker version 19 is required to run with GPU support, see https://github.com/NVIDIA/nvidia-docker for details

Typical usage

	docker run --gpus all -u $(id -u) -w /work -v $PWD:/work riedmiki/gromacs-plumed-python:2021 gmx ....

or use gmx_d for double precision (does not support GPU). The current working directory is visible to Gromacs due to the -w and -v options, all GPUs are available.
Effective UID is preserved with -u.  
Alternatively, run `gmx-docker`, see help `gmx-docker -h`

```
usage: ./gmx-docker options [--] gromacs_args ...

options are:
        -n              MPI processes
        -d              double precision
        -a arch         enforce specific CPU architecture (SSE2, AVX2_256, AVX_512)
        -r              enforce RDTSCP (should be detected)
        -w              select working directory relative to shared one for current enumeration
        -R              disable RDTSCP
        -c              cleanup -- just remove docker image 
        -p              use podman instead of docker
        -i              specify char input for gromacs
        -m              specify string input for gromacs
        -v version      use specific docker image version (riedmiki/gromacs-plumed-python:2021 by default)
```

Both might require `sudo` for gpu access.



