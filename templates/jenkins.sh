
shfile=$(tempfile -s .sh)

echo > "${shfile}" '
cd ~
export PATH=$(ls /opt/R-* -d)/bin:$PATH
export R_LIBS=~/R
mkdir -p ~/R
echo "options(repos = c(CRAN = \"https://cran.rstudio.com/\"))" >> ~/.Rprofile
curl -o "$package" "$url"
R CMD check "$package"
'

env=$(tempfile)
echo url=$url >> $env
echo package=$package >> $env

docker run -i --user docker --env-file $env rhub/debian-gcc-release \
  /bin/bash -c 'cat > /tmp/build.sh; chmod +x /tmp/build.sh; /tmp/build.sh' < "${shfile}"

rm -f $env
