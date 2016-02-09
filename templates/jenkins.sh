
shfile=$(tempfile -s .sh)

echo > "${shfile}" '
cd ~
export PATH=$(ls /opt/R-* -d)/bin:$PATH
export R_LIBS=~/R
mkdir -p ~/R
echo "options(repos = c(CRAN = \"https://cran.rstudio.com/\"))" >> ~/.Rprofile
curl -O https://raw.githubusercontent.com/MangoTheCat/remotes/master/install-github.R
R -e "source(\"install-github.R\")\$value(\"mangothecat/remotes\")"

curl -o "$package" "$url"

R -e "remotes::install_local(\"$package\", dependencies = TRUE)"

R CMD check "$package"
'

env=$(tempfile)
echo url=$url >> $env
echo package=$package >> $env

docker run -i --user docker --env-file $env rhub/debian-gcc-release \
  /bin/bash -c 'cat > /tmp/build.sh; chmod +x /tmp/build.sh; /tmp/build.sh' < "${shfile}"

rm -f $env
