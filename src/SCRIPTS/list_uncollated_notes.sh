#!/bin/bash

# DIRECTORIES & FILE PATHS #
if [[ "$(pwd)" == *"SCRIPTS"* ]]; then
  this_dir="$(pwd)"
else
  this_dir="$(pwd)/../SCRIPTS"
fi

json_array() {
  printf '"notes_list": ['

  while [ $# -gt 0 ]; do
    x=${1//\\/\\\\}
    echo \"${x//\"/\\\"}\"
    [ $# -gt 1 ] && echo ', '
    shift
  done

  printf  "]"
}

uncollated_notes_dir="$this_dir/../NOTES/Uncollated"

cd "$uncollated_notes_dir" || exit
repos=($(ls -d */ | sed "s#/##"))

printf '{ "data": ['
for repo in "${repos[@]}"; do
  if [ "$(ls -A "$repo")" ]; then
    printf "{"
    cd "$repo" || exit
    printf '"repo_name": "%s",' "${PWD##*/}"
    notes=($(ls -A *.html))
    json_array "${notes[@]}"
    cd ..
    printf "}, "
  fi
done
printf "]}"