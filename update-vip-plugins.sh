#!/bin/bash

# Updates plugins in a VIP repository from the WordPress.org plugins directory
# Run this from the root of your VIP repository directory
# Will use the current git branch name and the directory name to fetch updates available from the matching VIP environment
# Depends on the VIP CLI, jq, and curl.

# Get the name of the current Git branch
branch=$(git rev-parse --abbrev-ref HEAD)

# Get the name of the current directory without the full path
current_directory=$(basename $(pwd))

# Create a temporary directory to download the zip files
temp_dir=$(mktemp -d)

# Initialize the update counts
success_count=0
fail_count=0

# Loop through the plugins and download the latest version of each one that has an update available
json_response=$(vip @$current_directory.$branch --yes -- wp plugin list --format=json --skip-plugins --skip-themes)
for row in $(echo "${json_response}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

    name=$(_jq '.name')
    update=$(_jq '.update')

    if [[ "$update" == "available" ]]; then
        # Download the latest version of the plugin from WordPress.org to the temporary directory
        if curl -s --fail -o "$temp_dir/$name".zip https://downloads.wordpress.org/plugin/"$name".latest-stable.zip; then
            echo "$name,updated"

            # Increment success counter
            ((success_count++))
            
            # Extract the zip file to the "plugins" subdirectory of the current directory, overwriting any existing files
            mkdir -p plugins
            unzip -oq "$temp_dir/$name".zip -d plugins

            # Delete the zip file from the temporary directory
            rm "$temp_dir/$name".zip
        else
            echo "$name,notfound"
            # Increment fail count
            ((fail_count++))
        fi
    fi
done

# Display the update counts
echo "Update succeeded for $success_count plugins."
echo "Update failed for $fail_count plugins."

# Do something with the downloaded files here...

# Remove the temporary directory and its contents
rm -rf "$temp_dir"
