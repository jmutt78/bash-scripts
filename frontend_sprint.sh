#!/bin/bash
set -euo pipefail

if [ -z "${CONFLUENCE_ACCESS_TOKEN}" ]; then
echo "you must set CONFLUENCE_ACCESS_TOKEN env var"
exit 1
fi

if [ -z "${CONFLUENCE_SPACE_KEY}" ]; then
echo "you must set CONFLUENCE_SPACE_KEY env var"
exit 1
fi

if [ -z "${CONFLUENCE_PARENT_PAGE_ID}" ]; then
echo "you must set CONFLUENCE_PARENT_PAGE_ID env var"
exit 1
fi

if [ -z "${CONFLUENCE_BASE_URL}" ]; then
echo "you must set CONFLUENCE_BASE_URL env var"
exit 1
fi

if [ -z "${USER_NAME}" ]; then
echo "you must set USER_NAME env var"
exit 1
fi


# Set the credentials for the Confluence REST API
AUTH="${USER_NAME}:${CONFLUENCE_ACCESS_TOKEN}"
SPACE_KEY=${CONFLUENCE_SPACE_KEY}
PARENT_PAGE_ID=${CONFLUENCE_PARENT_PAGE_ID}

# Set the base URL for the Confluence REST API
BASE_URL=${CONFLUENCE_BASE_URL}

# Get the list of all child pages in the parent page
CHILD_PAGE_RESPONSE=$(curl -u "$AUTH" -X GET "${BASE_URL}$PARENT_PAGE_ID/child/page?limit=1000")
CHILD_PAGES=$(echo "$CHILD_PAGE_RESPONSE" | jq '.results[].title')

if [ "$CHILD_PAGES" == "null" ]; then
  echo "No child pages found"
  exit 1
else
  LATEST_SPRINT=$(echo "$CHILD_PAGES" | grep -o '[0-9]\+' | sort -n | tail -1)
  # create the new sprint number by incrementing the latest sprint number
  NEXT_SPRINT=$((LATEST_SPRINT + 1))
fi

# # Set the page title with the next sprint number
PAGE_TITLE="FRNT Sprint $NEXT_SPRINT"

# prompt the user to enter the sprint dates
read -p "Enter the sprint dates: " SPRINT_DATES

# prompt the user to enter the key dates
read -p "Enter the key dates: " KEY_DATES

# package the sprint dates and key dates into a markdown table
PAGE_BODY="h3.Sprint Dates:\n$SPRINT_DATES\nh3.Key Dates:\n$KEY_DATES\nh3.Dependency Rotation:\nh3.Pharos\nh3.Backend\nh3.CMS\nh3.Other\n"


# Build the JSON payload for the new page
PAYLOAD=$(cat <<EOF
{
  "type": "page",
  "title": "$PAGE_TITLE",
  "space": {
    "key": "$SPACE_KEY"
  },
    "ancestors": [
        {
        "id": "$PARENT_PAGE_ID"
        }
    ],
  "body": {
    "storage": {
      "value": "$PAGE_BODY",
      "representation": "wiki"
    }
  }
}
EOF
)

# Send the API request to create the new page
curl -u  "$AUTH" -X POST -H 'Content-Type: application/json' -d "$PAYLOAD" "$BASE_URL"

