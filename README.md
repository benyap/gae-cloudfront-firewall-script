# gae-cloudfront-firewall-script

This script automatically adds or removes the required firewall rules to restrict your Google App Engine instance to only be accessible through a Cloudfront distribution on AWS.

The IP ranges for Cloudfront can be found [here](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/LocationsOfEdgeServers.html).

## Pre-requisites

- You must have the [Google Cloud SDK](https://cloud.google.com/sdk/install) installed on your machine.

- You must have initialised GCloud and selected the project on which you want to set the firewall rules for. Use `gcloud init` to initailise GCloud.

## Usage

Use `bash` to run this script.

To give this script executable permissions:

```bash
chmod +x set-cloudfront-only-firewall.sh
```

To execute this script:

```bash
# Enable firewall rules
./set-cloudfront-only-firewall.sh -enable

# Disable firewall rules
./set-cloudfront-only-firewall.sh -disable
```

## Notes

- Using the `-enable` option will set your default firewall rule to DENY all IP ranges.

- Using the `-disable` option will set your default firewall rule to ALLOW all IP ranges.
