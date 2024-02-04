#!/bin/bash

#note_data=$1

root_dir=".."
temp="$root_dir/output.tmp"
output_file="$root_dir/output.html"

echo > "$temp"

declare -A note_data=(
  ["repo"]="something1"
  ["country"]="something2"
  ["commitHash"]="something3"
  ["commitMessage"]="something4"
  ["title"]="something5"
  ["tickets"]="something6"
  ["impact"]="something7"
  ["category"]="something8"
  ["description"]="something9"
  ["codeChanges"]="something10"
  ["testingSteps"]="something11"
  ["additionalNotes"]="something12"
  ["additionalLinks"]="something13"
)

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

for key in "${!note_data[@]}"; do
  value="${note_data[$key]}"
  chip_icon="${chip_icons[$key]}"
  subheading=$(echo "$key" | sed 's/\(.\)\([A-Z]\)/\1 \2/g')

  if [[ "${key,,}" == "title" ]]; then
    {
      echo "<div class=\"template\">";
      echo "    <div class=\"${key}\">";
      echo "        <div class=\"titleContent\">${value}</div>";
      echo "    </div>";
    } > "$output_file"
  elif [[ "${key,,}" == "repo" ]] || [[ "${key,,}" == "country" ]] || [[ "${key,,}" == "commithash" ]] || [[ "${key,,}" == "commitmessage" ]]; then
    continue
  else
    {
      echo
      echo "    <div class=\"${key}\">"
      echo "        <div class=\"chip\">"
      echo "            <div class=\"chipIcon\">"
      echo "                <span class=\"material-icons dark\">$chip_icon;</span>"
      echo "            </div>"
      echo "            <div class=\"chipContent\">"
      echo "                <div class=\"subheading\">${subheading^}</div>"
      echo "            </div>"
      echo "        </div>"
      echo "        <div class=\"${key}Content\">${value}</div>"
      echo "    </div>"
    } >> "$temp"
  fi
done

cat "$temp" >> "$output_file"
echo "</div>" >> "$output_file"
rm "$temp"