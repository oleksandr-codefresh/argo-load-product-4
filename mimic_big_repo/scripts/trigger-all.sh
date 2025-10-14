#!/bin/zsh

SCRIPT_DIR=${0:a:h}

# Handle optional 'noGit' argument
noGitMode=false
appArgs=()

for arg in "$@"; do
  if [[ "$arg" == "noGit" ]]; then
    noGitMode=true
  else
    appArgs+=("$arg")
  fi
done

# Use provided apps or fallback to default
if [[ ${#appArgs[@]} -gt 0 ]]; then
  apps=("${appArgs[@]}")
else
  apps=(`ls "${SCRIPT_DIR}/../dev"`)
fi

# Image versions to cycle through
versions=("1.28.0" "1.27.5" "1.26.3" "1.25.5" "1.24.0" "1.23.4" "1.14.0" "1.14.2")

# Git pull if not in noGit mode
if [[ $noGitMode == false ]]; then
  git pull
fi

# Main loop
for app in "${apps[@]}"; do
  valuesPath="$SCRIPT_DIR/../dev/$app/values.yaml"
  chartPath="$SCRIPT_DIR/../dev/$app/Chart.yaml"

  currentVersion=`yq ".base.version" "$valuesPath"`
  echo "$app currentVersion: '${currentVersion}'"

  index=0
  for ((i = 1; i <= $#versions; i++)); do
    if [[ "${versions[$i]}" == "${currentVersion}" ]]; then
      index=$i
      break
    fi
  done

  ((index=(index+1)%9))
  if [[ "$index" == 0 ]]; then 
    index=1
  fi

  newVersion=${versions[$index]}
  echo "$app newVersion: '${newVersion}'"
  yq -i ".base.version = \"$newVersion\"" "$valuesPath"

  CURRENT_VERSION=$(yq '.version' < "$chartPath")
  NEW_VERSION=$(echo $CURRENT_VERSION | awk -F. '/[0-9]+\./{$NF++;print}' OFS=.)
  yq -i ".appVersion = \"$NEW_VERSION\"" "$chartPath"
  yq -i ".version = \"$NEW_VERSION\"" "$chartPath"
done

# Git commit and push if not in noGit mode
if [[ $noGitMode == false ]]; then
  git add "$SCRIPT_DIR/../dev"
  git commit -m "promote all!"
  git push
fi
