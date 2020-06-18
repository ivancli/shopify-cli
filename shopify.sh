#!/bin/sh

# If we're not already in a shim environment but still tried to set up a shim, print out the re-installation warning
typeset -f shopify > /dev/null 2>&1
if [ "$?" != "0" ]; then
  echo "This version of Shopify App CLI is no longer supported. You’ll need to upgrade to continue using it. This process typically takes a few minutes.
Please visit this page for complete instructions:
  https://shopify.github.io/shopify-app-cli/upgrade/
"
fi