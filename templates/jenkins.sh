
# Get the platform, the R package uses this to determine
# the packages needed
export RHUB_PLATFORM=$(docker run --user docker --rm rhub/debian-gcc-release \
		       bash -c 'echo $RHUB_PLATFORM')

# Look up system requirements
# wget https://raw.githubusercontent.com/MangoTheCat/remotes/master/install-github.R
# R -e "source(\"install-github.R\")\$value(\"r-hub/sysreqs\")"
wget -O "$package" "$url"
DESC=$(tar tzf "$package" | grep "^[^/]*/DESCRIPTION$")
tar xzf "$package" "$DESC"
sysreqs=$(Rscript -e "library(sysreqs); cat(sysreqs(\"$DESC\"))")
rm -rf "$package" "$DESC"

# Install them
cont=$(docker run -d --user root rhub/debian-gcc-release \
	      apt-get install -y $sysreqs)

# Wait until it stops
docker attach $cont || true

# Save the container as an image
image=$(docker commit $cont)

# Run the build in the new image

env=$(tempfile)
echo url=$url >> $env
echo package=$package >> $env

docker run -i --user docker --env-file $env --rm $image /bin/bash <<'EOF'
## The default might not be the home directory, but /
cd ~

## Configure R
export PATH=$(ls /opt/R-* -d)/bin:$PATH
export R_LIBS=~/R
mkdir -p ~/R
echo "options(repos = c(CRAN = \"https://cran.rstudio.com/\"))" >> ~/.Rprofile

## Download the single file install script from mangothecat/remotes
## We cannot do this from R, because some R versions do not support
## HTTPS. Then we install a proper 'remotes' package with it.
curl -O https://raw.githubusercontent.com/MangoTheCat/remotes/master/install-github.R
R -e "source(\"install-github.R\")\$value(\"mangothecat/remotes\")"

## Download the submitted package
curl -o "$package" "$url"

## Install the package, so its dependencies will be installed
## This is a temporary solution, until remotes::install_deps works on a 
## package bundle
R -e "remotes::install_local(\"$package\", dependencies = TRUE)"

R CMD check "$package"
EOF

# Destroy the new containers and the images
docker rm $cont   || true
docker rmi $image || true
