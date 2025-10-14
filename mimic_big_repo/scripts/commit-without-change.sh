#!/bin/zsh
echo "starting commit without changes"


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

# Git pull if not in noGit mode
if [[ $noGitMode == false ]]; then
  git pull
fi

# Main loop
for app in "${apps[@]}"; do
  valuesPath="$SCRIPT_DIR/../dev/$app/values.yaml"

  currentCommitLabel=`yq ".base.metadata.label.commit" "$valuesPath"`
  echo "$app currentLabel: '${currentCommitLabel}'"

  CURRENT_COMMIT_NUM=$(yq '.base.metadata.label.commit' < "$valuesPath")

  NEW_VERSION=$(echo $CURRENT_COMMIT_NUM | awk -F. '/[0-9]+\./{$NF++;print}' OFS=.)
  yq -i ".base.metadata.label.commit = \"$NEW_VERSION\"" "$valuesPath"

done

# Git commit and push if not in noGit mode
if [[ $noGitMode == false ]]; then
  git add "$SCRIPT_DIR/../dev"
  git commit -m "commit with no real change!"
  git push
fi
