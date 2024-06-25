#!/bin/bash

image_list=$1
registry=$2

if [[ -z "$image_list" ]]; then
  echo "Usage: retag-images.sh <image_list.txt> <registry>"
  echo >&2 'image_list not specified'
  exit 1
fi

if [[ -z "$registry" ]]; then
  echo "Usage: retag-images.sh <image_list.txt> <registry>"
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

  # group log
  # https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#grouping-log-lines

  echo "::group::Sync $image"
  
  docker pull "$image"

  if [[ $? == 0 ]]; then
    echo "Pull Image: $image"
  else
    echo "Pull Image FAILED: $image"
  fi

  old_image = $(echo "$image" | awk -F'/' '{print $NF}')

  new_image="$registry"/ali-dockerhub-2024/"$old_image"
  
  docker tag "$image" "$new_image"
  if [[ $? == 0 ]]; then
    echo "Retag Image: $image => $new_image"
  else
    echo "Retag Image FAILED: $image => $new_image"
    continue
  fi

  docker push "$new_image"
  if [[ $? == 0 ]]; then
    echo "Push Image: $new_image"
  else
    echo "Push Image FAILED: $new_image"
  fi
  
  echo "::endgroup::"
  
done < "$image_list"
