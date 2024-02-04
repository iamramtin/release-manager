#!/bin/bash

# TODO: e.g. when creating branch 3.5.y, automatically lock 3.5.x and merge it back into master, then create 3.5.y

# 1st parameter: new version (e.g. 3.5.3)
# 2nd parameter (optional): branch to base off of (e.g. 3.5.4)

release_version=$1
base_branch=$2 # or default to master?

cur_dir="$(pwd)/temp"

declare -a repo_arr=(
    repo_one
    repo_two
    repo_three
    repo_four
    repo_five
)

mkdir -p "$cur_dir"
cd "$cur_dir" || exit

for repo_name in "${repo_arr[@]}"; do
  repo_url="repo_url_here"
  if [[ -d $repo_name ]]; then
    echo "$repo_name has already been cloned"
    git checkout master
    git pull
  else
    git clone "$repo_url"
  fi

  cd "$repo_name" || exit

  if [[ ! $(git branch --list -r "*$base_branch") ]]; then
    echo "Error: The base branch $base_branch does not exist on project $repo_name"
    exit 1
  fi

  git checkout "$base_branch"

  echo

  if [[ $(git branch --list -r "*$release_version") ]]; then
    echo "Remote branch $release_version already exists"
  else
      echo

      if [[ $(git ls-remote --tags --quiet "$repo_url" "Release_$release_version") ]]; then
        git checkout -b "$release_version" "Release_$release_version"
      else
        git checkout -b "$release_version" "$base_branch"
        echo
        echo "Release Notes tag doesn't exist... branching off latest commit"
        git tag -a "Release_$release_version" -m "Release Notes $release_version"
        git push origin "Release_$release_version"
      fi
      git push -u origin "$release_version"

      echo "Created branch $release_version"
  fi
  echo
  cd ..
done

echo "Branch $release_version has been created for all repos"