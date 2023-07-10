#!/bin/bash

# Initialize variables
app_override=false
environment_override=false

# Function to display usage instructions
display_usage() {
    echo "Usage: $0 [--app <directory>] [--env <environment_name>] [--help]"
    echo "  --app      : Specify the VIP app name or ID from which the plugin version list should be retrieved. Defaults to the current directory name."
    echo "  --env      : Specify the environment name from which to retrieve plugins. Defaults to the current git branch."
    echo "  --help     : Display this help message."
    echo ""
    echo "Downloads plugin updates for a WordPress VIP site. Only plugins publicly available on the WordPress.org plugin directory will be updated. Run from the root directory of a locally cloned VIP repository."
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --app)
            current_directory="$2"
            app_override=true
            shift
            ;;
        --env)
            branch="$2"
            environment_override=true
            shift
            ;;
        --help)
            display_usage
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1"
            display_usage
            exit 1
            ;;
    esac
    shift
done

# Function to display error message and installation links
display_error_message() {
    echo "Error: The required command '$1' is not available on your system."
    echo "Please install '$1' to use this script."
    echo "Installation links:"
    echo "$2"
    exit 1
}

# Check if 'vip' command is available
if ! command -v vip &> /dev/null; then
    display_error_message "vip" "https://docs.wpvip.com/technical-references/vip-cli/"
fi

# Check if 'jq' command is available
if ! command -v jq &> /dev/null; then
    display_error_message "jq" "https://stedolan.github.io/jq/"
fi

# Get the name of the current Git branch
if [[ "$environment_override" = false ]]; then
    branch=$(git rev-parse --abbrev-ref HEAD)
fi

# Get the name of the current directory without the full path
if [[ "$app_override" = false ]]; then
    current_directory=$(basename "$(pwd)")
fi

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
