
shfile=$(tempfile -s .sh)

echo > "${shfile}" '
export PATH=$(ls /opt/R-* -d)/bin:$PATH
export R_LIBS=~/R
mkdir -p ~/R
echo "options(repos = c(CRAN = \"https://cran.rstudio.com/\"))" >> ~/.Rprofile
curl -o "$package" "$url"
R CMD check "$package"
'

docker run -i --user docker rhub/debian-gcc-release \
  /bin/bash -c 'cat > /tmp/build.sh; chmod +x /tmp/build.sh; /tmp/build.sh' < "${shfile}"
