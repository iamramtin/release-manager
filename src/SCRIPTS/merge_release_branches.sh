#!/bin/bash

from_branch=$1
to_branch=$2

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

conflicts_count=0
projects_to_merge=()

echo "--------------------------------------------"
echo "Testing that there will be no conflicts when we merge from branch $1 into branch $2"
echo

for repo in "${repo_arr[@]}"; do
  repo_url="repo_url_here"
  if [[ -d $repo ]]; then
    echo "$repo has already been cloned"
    git checkout master
    git pull
  else
    git clone "$repo_url"
  fi

  cd "$repo" || exit 
  
  if [[ ! $(git branch --list -r "*$from_branch") ]]; then
    echo "Warning: The branch $from_branch does not exist on project $repo.  Skipping this project"
    continue
  fi

  if [[ ! $(git branch --list -r "*$to_branch") ]]; then
    echo "Warning: The branch $to_branch does not exist on project $repo.  Skipping this project"
    continue
  fi

  git fetch && git checkout "$from_branch"
  git checkout "$to_branch"
  git merge --no-commit --no-ff "$from_branch" > test_commit.tmp

  if [[ $(grep "CONFLICT" test_commit.tmp) ]]; then
    echo "In repo $repo the following conflicts were encountered when trying to merge:"
    cat test_commit.tmp | grep "CONFLICT"
    conflicts_count=$((conflicts_count+1))
  fi

  cat test_commit.tmp
  if [[ $(grep "Already up to date" test_commit.tmp) ]]; then
    echo "Info:  Project $repo is already up to date and doesn't need to be merged"
  else  
    git merge --abort  
    projects_to_merge+=("$repo")
  fi  

  rm test_commit.tmp
  cd ..
  printf "\n\n\n"
done

if [[ $conflicts_count -gt 0 ]]; then
  echo "Please merge the projects with conflicts manually and then run this script again"
  echo "In total there were $conflicts_count conflicts"
  exit 1
fi

echo "--------------------------------------------"
echo "Merging the projects:"
echo
for repo in "${projects_to_merge[@]}"; do
  cd "$repo" || exit 
  printf "%s\n" "$repo"

  git merge --no-edit "$from_branch"
  git tag -a "Tag_$from_branch" -m "Merged $from_branch into $to_branch"
  git push origin "Tag_$from_branch"

  git push

  cd ..
  printf "\n\n\n"
done
