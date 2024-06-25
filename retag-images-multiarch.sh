#!/bin/bash

image_list=$1
registry=$2
archs="linux/amd64,linux/arm64"

if [[ -z "$image_list" ]]; then
  echo "Usage: retag-images-multiarch.sh <image_list.txt> <registry>"
  echo >&2 'image_list not specified'
  exit 1
fi

if [[ -z "$registry" ]]; then
  echo "Usage: retag-images-multiarch.sh <image_list.txt> <registry>"
  echo >&2 'registry not specified'
  exit 1
fi

while read image; do

  if [[ -z "$image" ]]; then
    continue
  fi

  if [[ "$image" == //* ]]; then
    continue
  fi

  old_image=$(echo "$image" | awk -F'/' '{print $NF}')
  new_image="$registry"/ali-dockerhub-2024/"$old_image"

  # group log
  # https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#grouping-log-lines
  
  echo "FROM $image" > Dockerfile
  
  echo "::group::Sync $image"
  
  docker buildx build --push --platform="$archs" --force-rm --pull \
  		-t "$new_image" \
  		-f Dockerfile \
  		.
  
  if [[ $? == 0 ]]; then
    echo "Sync Image SUCCESS: $image => $new_image"
  else
    echo "Sync FAILED: $image => $new_image"
    continue
  fi

  docker buildx prune -f
  rm -f Dockerfile
  
  echo "::endgroup::"
  
done < "$image_list"
