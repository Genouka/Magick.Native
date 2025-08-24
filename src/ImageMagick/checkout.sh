#!/bin/bash
set -e

clone()
{
  local repo=$1
  local folder=$2

  echo ''
  echo "Cloning $repo"

  if [ -z "$folder" ]; then
    folder=$repo
  fi

  if [ -d "$folder" ]; then
    cd $folder
  else
    git clone https://github.com/Genouka/$repo.git $folder
    if [ $? != 0 ]; then
      echo "Error during checkout";
      exit;
    fi

    cd $folder
    git remote add sshpush git@github.com:Genouka/$repo.git
    git config remote.pushDefault sshpush
  fi

  git reset --hard
  git pull origin main
  cd ..
}

clone_imagemagick()
{
  commit=$(<ImageMagick.commit)

  clone ImageMagick
  cd ImageMagick

  if [ "$commit" != "latest" ]; then
    echo "Checking out commit $commit"
    git checkout $commit
  else
    echo "Checking out latest commit"
  fi

  cd ..
}

download_configure()
{
  ./ImageMagick/.github/build/windows/download-configure.sh
}

clone_dependencies()
{
  echo "Cloning Dependencies"
  clone Dependencies
  cd Dependencies

  ./clone-dependencies.sh

  cd ..
}

download_dependencies()
{
  local dependencies_artifact=$1

  ./ImageMagick/.github/build/windows/download-dependencies.sh --dependencies-artifact $dependencies_artifact
  if [[ "$OSTYPE" != "msys" ]]; then
    echo "Moving Artifacts directory to /tmp/dependencies"
    rm -Rf /tmp/dependencies
    mv Artifacts /tmp/dependencies
  fi
}

configure=true
development=false
dependencies_artifact=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --development)
      development=true
      shift 1
      ;;
    --dependencies-artifact)
      dependencies_artifact=$2
      shift 2
      ;;
    --no-configure)
      configure=false
      shift 1
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

clone_imagemagick
if [ "$configure" == true ]; then
  download_configure
fi

if [ "$development" == true ]; then
  clone_dependencies
else
  download_dependencies $dependencies_artifact
fi
