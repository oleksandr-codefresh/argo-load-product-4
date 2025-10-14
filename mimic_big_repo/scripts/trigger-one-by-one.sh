#!/bin/zsh

SCRIPT_DIR=${0:a:h}

if [[ $1 != "noGit" ]]; then
    git pull
fi

versions=("1.28.0" "1.27.5" "1.26.3" "1.25.5" "1.24.0" "1.23.4" "1.14.0" "1.14.2")

apps=("app1" "app2" "app3" "app4")

for app in "${apps[@]}"; do
    deploymentPath="$SCRIPT_DIR/../dev/$app/templates/deployment.yaml"
    chartPath="$SCRIPT_DIR/../dev/$app/Chart.yaml"

    currentVersion=`cat "$deploymentPath" | grep "image: nginx" | sed -ne "s/.*\([0-9]\.[0-9][0-9].[0-9]\).*/\1/p"`
    echo "$app currentVersion: '${currentVersion}'"

    index=0
    for ((i = 1; i <= $#versions; i++)); do
        if [[ "${versions[$i]}" = "${currentVersion}" ]]; then
            index=$i
            break
        fi
    done

    ((index=(index+1)%9))
    if [[ "$index" = 0 ]]; then 
        index=1
    fi

    newVersion=${versions[$index]}
    echo "$app newVersion: '${newVersion}'"
    yq -i ".spec.template.spec.containers[0].image = \"nginx:$newVersion\"" "$deploymentPath"

    CURRENT_VERSION=`yq '.version' < "$chartPath"`
    NEW_VERSION=`echo $CURRENT_VERSION | awk -F. '/[0-9]+\./{$NF++;print}' OFS=.`
    yq -i ".appVersion = \"$NEW_VERSION\"" "$chartPath"
    yq -i ".version = \"$NEW_VERSION\"" "$chartPath"
    
    if [[ $1 != "noGit" ]]; then
        git add "$SCRIPT_DIR/../dev"
        git commit -m "promote all!"
        git push
    fi
done

