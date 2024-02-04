#!/bin/bash

declare -a repos=(
  repo_one
  repo_two
  repo_three
  repo_four
  repo_five
)

create_file () {
  {
    printf '#!/bin/bash'
    printf '\n'
    printf '\nRED="\\033[1;31m"'
    printf '\nNC="\\033[0m"'
    printf '\n'
    printf '\ncurrent_branch=$(git branch --show-current)'
    printf '\nlocked_branches=('
    printf '\n  "3.5.7"'
    printf '\n  "3.5.6"'
    printf '\n  "3.5.5"'
    printf '\n  "3.5.4"'
    printf '\n  "3.5.3"'
    printf '\n  "3.5.2"'
    printf '\n  "3.5.1"'
    printf '\n  "3.5.0"'
    printf '\n)'
    printf '\n'
    printf '\nfor branch in "${locked_branches[@]}"; do'
    printf '\n  if [[ "$current_branch" == "$branch" ]]; then'
    printf '\n      printf "\\n${RED}   This release branch has been locked, please commit to a new release branch"'
    printf '\n      printf "\\n--------------------------------------------------------------------------------${NC}\\n"'
    printf '\n      exit 1'
    printf '\n  fi'
    printf '\ndone'
    printf '\n'
  } > "$file"
}

append_to_file () {
  lock_branch_exists=$(< "$file" grep "$lock_branch")

  if [[ -z $lock_branch_exists ]]; then
    sed -i "/locked_branches=(/ s/$/ \n  \"$lock_branch\"/" "$file"

    git reset .
    git add .githooks/
    git config --local core.hooksPath .githooks/
    git commit --no-verify -m "LOCKED: release branch $lock_branch" # overrides hook for this commit only
    git push
  fi
}


temp_dir="$(pwd)/temp"
mkdir -p "$temp_dir"
cd "$temp_dir" || exit

for repo_name in "${repos[@]}"; do
  repo_url="repo_url_here"
  if [[ -d $repo_name ]]; then
    echo "$repo_name has already been cloned"
    git checkout master
    git pull
  else
    git clone "$repo_url"
  fi

  cd "$repo_name" || exit

  lock_branch=$1 # branch to lock received as input
  file=.githooks/pre-commit

  # ON MASTER
  mkdir -p .githooks
  if [[ ! -f $file ]]; then
    create_file
    append_to_file
  else
    append_to_file
  fi

  # ON RELEASE BRANCH
  if [[ $(git branch --list -r "*$lock_branch") ]]; then
    git checkout "$lock_branch"
    mkdir -p .githooks
    if [[ ! -f $file ]]; then
      create_file
      append_to_file
    else
      append_to_file
    fi
  fi

  cd ..
done

cd ..
rm -rdf "$temp_dir"