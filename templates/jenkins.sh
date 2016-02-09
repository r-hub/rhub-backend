
env=$(tempfile)
echo url=$url >> $env
echo package=$package >> $env

docker run -i --user docker --env-file $env rhub/debian-gcc-release \
  /bin/bash <<'EOF'
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
