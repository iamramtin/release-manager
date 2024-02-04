#!/bin/bash

temp_file=""
echo > "$temp_file"

CYAN='\033[1;36m'
NC='\033[0m'

# USER INPUT #
release_version=$1 # or default to master?
date_from=$2
data=$3

declare -a list_of_notes
declare -a list_of_repos

declare -a map
# map of notes per repo - 2d array hack in bash using split functionality on array of strings, ex:
#   repo_one:2021-08-22_5f91f71_SR-55225.html,2021-09-22_5f91f71_SR-55225.html,
#   repo_two:2021-09-08_6afcf8b_FIN-1799.html,
#   repo_three:2022-01-07_d20d141.html,

# convert python dictionary (read as string) into a bash list
IFS=', ' read -r -a arr <<< "${data:1:${#data}-2}"
for n in "${arr[@]}"; do
  note_path="${n:1:${#n}-2}"
  list_of_notes+=("$note_path")

  # create list of repo names
  IFS='/' read -r -a arr2 <<< "$note_path"
  repo_name_only="${arr2[0]}"
  note_name_only="${arr2[1]}"
  flag="true"

  for r in "${list_of_repos[@]}"; do
    if [ "$r" == "$repo_name_only" ]; then
      flag="false"
    fi
  done

  if [ "$flag" == "true" ]; then
    list_of_repos+=("$repo_name_only")
    map+=("$repo_name_only":)
  fi

  map[${#map[@]}-1]="${map[${#map[@]}-1]}$note_name_only,"
done


# DIRECTORIES & FILE PATHS #
if [[ "$(pwd)" == *"SCRIPTS"* ]]; then
  this_dir="$(pwd)"
else
  this_dir="$(pwd)/../SCRIPTS"
fi

uncollated_notes_dir="$this_dir/../NOTES/Uncollated"
elements_dir="$this_dir/../NOTES/Elements"
output_dir="$this_dir/../NOTES/Collated"
mkdir -p "$output_dir"

style_sheet="$elements_dir"/style.css
cover_image="$elements_dir"/base64_cover_pdf.txt
introduction_text="$elements_dir"/introduction.txt

release_notes_temp="$output_dir"/release_notes_temp.html
release_note_modified="$output_dir"/release_note_modified.html
release_notes_final="$output_dir/Release Notes $release_version.html"

# FUNCTIONS #
printf "\nRelease Notes Version: %s" "$release_version"
printf "\nFrom date: %s" "$date_from"
printf "\nOutput of release note: %s\n\n" "$release_notes_final"

echo > "$release_notes_temp"
printf "<!DOCTYPE html>" > "$release_notes_final"
{
  printf "\n<html lang=\"en\">"

  # HEAD
  printf "\n<head>"
  printf "\n<meta charset=\"UTF-8\">"
  printf "\n<link href=\"https://fonts.googleapis.com/icon?family=Material+Icons\" rel=\"stylesheet\">"
  printf "\n<style>\n"
  cat "$style_sheet"
  printf "\n</style>"
  printf "\n<title>%s</title>" "Release Notes Suite $release_version"
  printf "\n</head>"

  # BODY
  printf "\n<body>"

  # COVER PAGE
  printf "\n<div class=\"frontCover\">"
  printf "<img src=\"" && cat "$cover_image" && printf "\">"
  printf "\n<div class=\"frontCoverVersion\">%s</div>" "Release Notes Suite $release_version"
  printf "\n<div class=\"frontCoverDate\">%s</div>" "$(date --date="today" +"%d %b %Y")"
  printf "\n</div>"

  printf "\n<div class=\"all\">" # open all tag

  # INTRODUCTION PAGE: EXECUTIVE SUMMARY
  printf "\n<div class=\"documentHeadingWithBreak\">Executive Summary</div>"
  printf "\n<div class=\"introductionContent\"><br/>"
  cat "$introduction_text"
  printf "</div>"

  # INTRODUCTION PAGE: INCLUDED PRODUCTS
  printf "\n<div class=\"documentHeading\">Included In This Release</div>"
  printf "\n<div class=\"productsList\">"

  for repo in "${list_of_repos[@]}"; do
    repo_name="${repo^^}"
    repo_name="${repo_name//-/$' '}"
    repo_name="${repo_name//_/$' '}"
    printf "\n<li><b>%s</b></li><br/>" "$repo_name"
  done

  printf "\n</div>"

  # TABLE OF CONTENTS PAGE HEADINGS
  printf "\n<div class=\"documentHeadingWithBreak\">Table of Contents</div>"
  printf "\n<div class=\"tableOfContentsHeading1Group\">"
  printf "\n<div class=\"tableOfContentsHeading1\">%s</div>" "Tickets Included In This Release"
  printf "\n</div>"
  printf "\n<div class=\"tableOfContents\">\n"
} >> "$release_notes_final"

repo_heading_without_break="true"

echo "--------------------------------------------------" >> "$temp_file"
for m in "${map[@]}"; do
  r=$(echo "$m" | cut -d ":" -f 1)
  n=$(echo "$m" | cut -d ":" -f 2)
  echo "$repo1" >> "$temp_file"
done

repo_count=1
for m in "${map[@]}"; do
  r=$(echo "$m" | cut -d ":" -f 1)
  r=${r^^}
  n=$(echo "$m" | cut -d ":" -f 2)

  printf "\n<div class=\"tableOfContentsHeading2\">%s</div>" "$repo_count. $r" | tr "-" " " | tr "_" " " >> "$release_notes_final"
  if [[ "$repo_heading_without_break" == "true" ]]; then
    repo_heading_without_break="false"
    printf "\n<div class=\"repoHeadingWithoutBreak\">%s</div>" "$repo_count. $r" | tr "-" " " | tr "_" " "  >> "$release_notes_temp"
  else
    printf "\n<div class=\"repoHeading\">%s</div>" "$repo_count. $r" | tr "-" " " | tr "_" " "  >> "$release_notes_temp"
  fi

  cd "$uncollated_notes_dir/$r" || exit

  note_count=1
  IFS=',' read -ra note_arr <<< "$n"
  for release_note in "${note_arr[@]}"; do
    title=$(cat "$release_note" | sed -nE "s/.*<div\sclass=\"titleContent\">(.*?)<\/div>.*?/\1/p" | cut -f 1 -d "<")

    {
      printf "\n<div class=\"tableOfContentsHeading3\">"
      printf "\n<a href=\"#%s\">%s</a><br/>" "$release_note" "$repo_count.$note_count $title"
      printf "\n</div>"
    } >> "$release_notes_final"

    # ACTUAL RELEASE NOTE CONTENT
    printf "\n<a id=\"%s\"></a>" "$release_note" >> "$release_notes_temp"

    sed -r -e 's|<div class="titleContent">|<div class="titleContent">'"${repo_count}"'.'"${note_count}"' |g' "$release_note" > "$release_note_modified"

    # TODO: if first note not if only one note
    if [[ "$note_count" -eq 1 ]]; then
      sed -r -e 's|<div class="uncollatedNote">|<div class="firstUncollatedNote">|g' "$release_note_modified" >> "$release_notes_temp"
    else
      cat "$release_note_modified" >> "$release_notes_temp"
    fi

    ((note_count++))
  done

  ((repo_count++))
done

cd ../..

{
  printf "\n</div>"

  # PRINT CONTENT
  printf "\n<div class=\"documentHeadingWithBreak\">Tickets Included In This Release</div>"
  cat "$release_notes_temp"

  printf "\n</div>" # closes all tag
  printf "\n</body>"
  printf "\n</html>"
} >> "$release_notes_final"

printf "${CYAN}Release notes have been produced${NC}\n"

rm "$release_notes_temp"
rm "$release_note_modified"