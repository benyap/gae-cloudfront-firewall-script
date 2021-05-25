# set-gae-firewall

This script automatically adds or removes the required firewall rules to
restrict your Google App Engine instance to only be accessible through a list of
given IPs.

The example in this repository, `cloudfront-ips.txt`, lists the IP ranges for
AWS Cloudfront which can be found
[here](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/LocationsOfEdgeServers.html).

## Pre-requisites

- You must have the [Google Cloud SDK](https://cloud.google.com/sdk/install)
  installed on your machine.

- You must have initialised GCloud and selected the project on which you want to
  set the firewall rules for. Use `gcloud init` to initailise GCloud.

## Usage

Create text file that contains a list of IP ranges that should be allowed by the
firewall. Optionally provide a description for the IP range on the same line,
separated by a comma. See `cloudfront-ips.txt` for an example.

Use `bash` to run the script. To give this script executable permissions:

```bash
chmod +x set-gae-firewall.sh
```

Run the following command to update GAE firewall rules:

```bash
./set-gae-firewall.sh --action enable|disable --project <project_id> --file <file_name>
```

### Arguments

**`--action`**

Using `enable` option will enable the Firewall by adding **allow** rules for the
IP ranges listed in the file, and setting the default rule to DENY.

Using the `disable` option will disable the Firewall by removing the rules for
the IP ranges listed in the file, and setting the default rule to ALLOW.

**`--project`**

Use this argument to specify the GCP project to run this script on. The user
must be currently logged in using `gcloud auth login` to an account with access
to the specified project.

**`--file`**

Use this argument to specify the path to a text file that contains a list of IP
ranges (and optionally descriptions) to use.
