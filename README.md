# desc-cosmology-env

## Using the desc-cosmology docker image on a laptop to run local Jupyter

Prerequisite: install docker on your laptop (see below)

* `docker pull lsstdesc/desc-cosmology:slac-latest-2026-07-23`
* `git clone https://github.com/paulrogozenski/augur_tutorial`
* The following will start up the container, mount the current directory to /home/lsst/work, and start up jupyter.  
* `docker run --rm -it -p 8888:8888 -v $(pwd):/home/lsst/work -e LOCAL_UID=$(id -u) -e LOCAL_GID=$(id -g) lsstdesc/desc-cosmology:slac-latest-2026-07-23  bash -c "source /opt/desc/bin/activate && jupyter lab --ip=0.0.0.0 --no-browser --port=8888"`
* Point your browser to the 3rd URL listed
* You should find the augur_tutorial under `/home/lsst/work` in Jupyter

## install the environment directly on your laptop
* `git clone https://github.com/LSSTDESC/desc-cosmology-env`
* Download Miniforge
```
url="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
curl -LO "$url"
bash ./Miniforge3-$(uname)-$(uname -m).sh -b -p $PWD/py
source $PWD/py/bin/activate
```
* Install the environment
```
conda env create -n cosmology-env -f desc-cosmology-env/slac/env-nobuild-2026-07-23.yml
```
* Start up Jupyter

`python -m ipykernel install --user --name=cosmology --display-name=cosmology jupyter notebook`


## Using the desc-cosmology docker image at SLAC S3DF with apptainer

* After logging into S3DF iana
* `apptainer pull docker://lsstdesc/desc-cosmology:slac-latest-2026-07-23`
* git clone https://github.com/LSSTDESC/minimal_mcmc

## How to install docker on your laptop

### Installing docker on Mac

* Go to https://www.docker.com/products/docker-desktop/
* Download the version for your chip (Apple Silicon or Intel)
* Open the downloaded .dmg and drag Docker to Applications
* Launch Docker from Applications and follow the setup prompts
* Verify it works:
```
docker --version
docker run hello-world
```

### Installing docker on Linux (Ubuntu)

* Update package index
`sudo apt-get update`

* Install prerequisites
`sudo apt-get install -y ca-certificates curl gnupg`

* Add Docker's official GPG key
```
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

* Add the Docker repository
```
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

* Install Docker Engine
```
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

* (Optional) Run Docker without sudo
```
sudo usermod -aG docker $USER
newgrp docker
```

* Verify installation
```
docker --version
docker run hello-world
```
