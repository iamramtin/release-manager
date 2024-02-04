#!/bin/bash

to_upper() {
  echo "$1" | tr "[:lower:]" "[:upper:]"
}

to_lower() {
  echo "$1" | tr "[:upper:]" "[:lower:]"
}

convert_to_html() {
  temp_file="$uncollated_notes_dir/output.tmp"
  output_file="$uncollated_notes_dir/output.html"

  echo > "$temp_file"

  # material icons from: https://fonts.google.com/icons
  declare -A chip_icons=(
    ["tickets"]="&#xe54e"
    ["impact"]="&#xe8e1"
    ["category"]="&#xe892"
    ["description"]="&#xe873"
    ["codeChanges"]="&#xf232"
    ["testingSteps"]="&#xe868"
    ["additionalNotes"]="&#xf1fc"
    ["additionalLinks"]="&#xe157"
  )

  for key in "${!data_map[@]}"; do
    value="${data_map[$key]}"
    chip_icon="${chip_icons[$key]}"
    subheading=$(echo "$key" | sed 's/\(.\)\([A-Z]\)/\1 \2/g')

    # TODO: change the order to match UX designs, consider not using an associative array at all
    if [[ "${key,,}" == "title" ]]; then
      {
        echo "<div class=\"uncollatedNote\">";
        echo "    <div class=\"${key}\">";
        echo "        <div class=\"titleContent\">${value}</div>";
        echo "    </div>";
      } > "$output_file"
    elif [[ "${key,,}" == "repo" ]] || [[ "${key,,}" == "country" ]] || [[ "${key,,}" == "commithash" ]] || [[ "${key,,}" == "commitmessage" ]]; then
      continue
    else
      if [ -n "$value" ]; then
        {
          echo
          echo "    <div class=\"uncollatedNoteContent\">"
          echo "        <div class=\"chip\">"
          echo "            <div class=\"chipIcon\">"
          echo "                <span class=\"material-icons dark\">${chip_icon};</span>"
          echo "            </div>"
          echo "            <div class=\"chipContent\">"
          echo "                <div class=\"subheading\">${subheading^}</div>"
          echo "            </div>"
          echo "        </div>"
          echo "        <div class=\"subheadingContent\">${value}</div>"
          echo "    </div>"
        } >> "$temp_file"
      fi
    fi
  done

  cat "$temp_file" >> "$output_file"
  echo "</div>" >> "$output_file"
  cat "$output_file" # returns file

  rm "$temp_file"
  rm "$output_file"
}


# GLOBAL VARIABLES #
# TODO: MODIFY PATHS FOR EC2
#uncollated_notes_dir="/home/ec2-user/uncollated_notes"
#cloned_repos_dir="/home/ec2-user/cloned_repos"
uncollated_notes_dir="$(pwd)/../NOTES/UNCOLLATED"
cloned_repos_dir="$(pwd)/../../.."
mkdir -p "$uncollated_notes_dir"


# loop through json data (passed as arg) & convert into functional bash associative array
json_data=$(echo "$1" | tr -d "{}" | tr -d "'")

declare -A data_map
IFS="," read -ra json_data_arr <<< "$json_data"
for t_data in "${json_data_arr[@]}"; do
  key=$(echo "$t_data" | cut -d: -f1 | tr -d " ")
  value=$(echo "$t_data" | cut -d: -f2)
  data_map[$key]=${value:1} # map data into array: repo, hash, and rest of the json data
done


# convert data into HTML format
html_note_data=$(convert_to_html)


# extract useful parts of data
repo="${data_map[repo],,}" && repo=${repo// /-}
commit_hash="${data_map[commitHash]}"
tickets="${data_map[tickets]}"

cd "$cloned_repos_dir/$repo" || exit
commit_date=$(git show --no-patch --no-notes --date=format:%Y-%m-%d --pretty="%cd" -r "$commit_hash")


# generate a title for the note: "[date]_[hash]_[tickets]"
commit_note_name="$commit_date"_"$commit_hash"
IFS=", " read -ra tickets_arr <<< "$tickets"
for ticket in "${tickets_arr[@]}"; do
  commit_note_name+="_$ticket"
done


# write note to HTML in correct directory
cd "$uncollated_notes_dir" || exit
mkdir -p "$repo"
echo "$html_note_data" > "$repo/$commit_note_name".html


# note path sent as output back to app.py
echo "$repo/$commit_note_name".html


# preserve note in repo
git reset .
git add "$repo/$commit_note_name".html
git commit -m "$(to_upper "$repo"): Added $commit_note_name"
git push
