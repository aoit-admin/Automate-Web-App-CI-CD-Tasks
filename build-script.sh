#!/bin/bash 
echo "O'Brien the build script is starting..."
rm -rf {build, customer-web-portal}
echo " O'Brien please wait, your repo project is cloning"
git clone https://github.com/vdespa/customer-web-portal
echo "Create the directory structure"
mkdir -p build/public/{js,css}
echo "Add empty index.html files to public directories"
touch build/public/index.html 
touch build/public/js/index.html 
touch build/public/css/index.html 
echo "Add build information"
echo "Created on: $(date)" > build/build-info.txt
echo "Created by: $USER" >> build/build-info.txt
cat build/build-info.txt
echo "Compile the application"
g++ customer-web-portal/web-app.cpp -o build/public/web-app.cgi
cp -r customer-web-portal/js/. build/public/js
cp -r customer-web-portal/css/. build/public/css
echo "Test the application"
build/public/web-app.cgi | grep "Customer Web Portal"
if [ $? -eq 0 ]
then
  echo "Test successful."
else
  echo "Aborting build. Test failed."
  exit 1
fi
echo "Generate a new Git tag"
cd ~/code/customer-web-portal
latest_git_tag="$(git describe --tags --abbrev=0)"
echo "Latest Git tag: $latest_git_tag"
latest_version="${latest_git_tag:1}"
echo "Latest version: $latest_version"
next_version="$((latest_version + 1))"
echo "Next version: $next_version"
git tag "v$next_version"
echo "Create release notes"
cd ~/code
wget -O build/release-notes.txt https://gist.githubusercontent.com/vdespa/f0fdbfe2de231651fc7bcbce2e02c66d/raw/b153e22c76c7ba1d741e2ba017797221673b7e79/release-notes.template.txt
sed -i "s/#DATE#/$(date)/g" build/release-notes.txt
sed -i "s/#VERSION#/$next_version/g" build/release-notes.txt
git -C customer-web-portal log $latest_git_tag..HEAD --oneline
git -C customer-web-portal log $latest_git_tag..HEAD --oneline >> build/release-notes.txt
if [ $archive_size -lt 50000 ]
then
  echo "The tar.gz file is too small"
  exit 1
fi
echo "Package application"
mkdir -p releases
tar -czvf releases/release-v$next_version.tar.gz build
archive_size=$(ls -l releases/release-v$next_version.tar.gz | awk '{print $5}')
if [ $archive_size -lt 50000 ]
then
  echo "The tar.gz file is too small"
  exit 1
fi
echo "Build Completed!"
exit
