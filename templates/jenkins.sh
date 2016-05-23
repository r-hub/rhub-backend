
# Get the platform, the R package uses this to determine
# the packages needed
export RHUB_PLATFORM=$(docker run --user docker \
			      --rm rhub/${image} \
			      bash -c 'echo $RHUB_PLATFORM')

# Look up system requirements
# wget https://raw.githubusercontent.com/MangoTheCat/remotes/master/install-github.R
# R -e "source(\"install-github.R\")\$value(\"r-hub/sysreqs\")"

echo ">>>>>==================== Downloading and unpacking package file"

wget -O "$package" "$url"
DESC=$(tar tzf "$package" | grep "^[^/]*/DESCRIPTION$")
tar xzf "$package" "$DESC"

echo ">>>>>==================== Querying system requirements"

sysreqs=$(Rscript -e "library(sysreqs); cat(sysreq_commands(\"$DESC\"))")
rm -rf "$package" "$DESC"

echo ">>>>>==================== Installing system requirements"

# Install them, if there is anything to install
if [ ! -z "${sysreqs}" ]; then
    cont=$(docker run -d --user root rhub/${image} \
		  bash -c "$sysreqs")
    # Wait until it stops
    docker attach $cont || true
    # Save the container as an image
    newimage=$(docker commit $cont)
else
    # If there is nothing to install we just use the stock image
    cont=""
    newimage=rhub/${image}
fi

# Run the build in the new image

env=$(tempfile)
echo url=$url >> $env
echo package=$package >> $env

echo ">>>>>==================== Starting Docker container"

docker run -i --user docker --env-file $env --rm $newimage /bin/bash <<'EOF'
## The default might not be the home directory, but /
cd ~

## Configure R, local package library, and also CRAN and BioConductor
export PATH=$(ls /opt/R-* -d)/bin:$PATH
export R_LIBS=~/R
mkdir -p ~/R
echo "options(repos = c(CRAN = \"https://cran.rstudio.com/\"))" >> ~/.Rprofile
R -e "source('https://bioconductor.org/biocLite.R')"
echo "options(repos = BiocInstaller::biocinstallRepos())" >> ~/.Rprofile
echo "unloadNamespace('BiocInstaller')" >> ~/.Rprofile

echo ">>>>>==================== Querying package dependencies"

## Download the single file install script from mangothecat/remotes
## We cannot do this from R, because some R versions do not support
## HTTPS. Then we install a proper 'remotes' package with it.
curl -O https://raw.githubusercontent.com/MangoTheCat/remotes/master/install-github.R
R -e "source(\"install-github.R\")\$value(\"mangothecat/remotes\")"

## Download the submitted package
curl -L -o "$package" "$url"

echo ">>>>>==================== Installing package dependencies"

## Install the package, so its dependencies will be installed
## This is a temporary solution, until remotes::install_deps works on a 
## package bundle
R -e "remotes::install_local(\"$package\", dependencies = TRUE)"

echo ">>>>>==================== Running R CMD check"

xvfb-run R CMD check "$package"
EOF

# Destroy the new containers and the images
# Only if we needed system installs, but not the stock image
if [ ! -z "$cont" ]; then
    docker rm $cont   || true
    docker rmi $newimage || true
fi
