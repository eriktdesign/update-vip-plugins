# update-vip-plugins

Bulk update plugins in a WordPress VIP repository that are available in the WordPress.org plugins directory.

## Introduction

Updating plugins on a WordPress VIP install can be a chore. Because the VIP filesystem is locked down, plugin updates must be made outside of WordPress. The VIP Dashboard lets you automatically create pull requests, but only to update one plugin at a time.

Using this script and a locally cloned copy of a site's VIP repository, you can automatically update all plugins that are available on the WordPress.org plugin directory.

## How to use

Open a terminal and `cd` to the root directory of your repository. Make sure the branch you wish to update plugins for is checked out in Git. Run the script and the plugins with available updates will be downloaded to a temporary directory and unzipped into your `plugins` folder.

## How it works

1. The current directory is assumed to be the VIP application name. The current branch is assumed to be the environment name. The script accepts optional `--app` and `--env` flags to override these values.
2. The script uses the VIP CLI to run the `wp plugin list` command against the VIP application and environment, fetching the list of plugins in JSON format.
3. Next, the script uses `jq` to extract and loop through the plugin slug and update status of each plugin.
4. If the plugin has an update available, the script uses `curl` to attempt to download the plugin from WordPress.org to a temporary directory.
5. If the download is successful, the plugin is extracted into the plugin directory, and the slug and "updated" are output to the terminal. If the download fails, the plugin slug and "notfound" are output to the terminal. This information can then be used to determine plugins that will need manual updates (e.g., those not on the WordPress.org plugin directory).
6. Finally, a count of successes and failures is displayed, and the temporary directory is deleted.

## How to install

1. Download the `update-vip-plugins.sh` file.
2. `$ chmod +x update-vip-plugins.sh`
3. `$ mv update-vip-plugins.sh /usr/local/bin/update-vip-plugins`

## Dependencies

1. [WordPress VIP CLI](https://docs.wpvip.com/technical-references/vip-cli/)
2. [jq](https://stedolan.github.io/jq/)

## Usage

To use the script, run the following command in a terminal:

```bash
$ update-vip-plugins [--app <directory>] [--env <environment_name>] [--help]
```

- `--app`: Specify the directory name to override the current_directory variable.
- `--env`: Specify the environment name to override the branch variable.
- `--help`: Display this help message.

The script will download plugin updates for a WordPress VIP site, updating only the plugins that are publicly available on the WordPress.org plugin directory.
