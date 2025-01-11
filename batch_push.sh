#!/bin/bash

# Check if git repository exists
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not a git repository"
    exit 1
fi

# Get list of all untracked and modified files
FILES=$(git status --porcelain | grep -E "^\?\?|^ M|^MM|^M" | cut -c4-)

# Check if there are any files to push
if [ -z "$FILES" ]; then
    echo "No files to push"
    exit 0
fi

# Convert files string to array
IFS=$'\n' read -rd '' -a FILE_ARRAY <<< "$FILES"

# Calculate total number of files
TOTAL_FILES=${#FILE_ARRAY[@]}
BATCH_SIZE=100

echo "Total files to push: $TOTAL_FILES"

# Counter for processed files
COUNTER=0

while [ $COUNTER -lt $TOTAL_FILES ]; do
    echo "Processing files $((COUNTER + 1)) to $((COUNTER + BATCH_SIZE))"

    # Reset any staged changes
    git reset --mixed HEAD

    # Add next batch of files
    for ((i = COUNTER; i < COUNTER + BATCH_SIZE && i < TOTAL_FILES; i++)); do
        FILE="${FILE_ARRAY[i]}"
        echo "Adding: $FILE"
        git add "$FILE"
    done

    # Commit and push this batch
    git commit -m "Adding files $((COUNTER + 1)) to $((COUNTER + BATCH_SIZE))"
    git push

    if [ $? -ne 0 ]; then
        echo "Error pushing files. Stopping."
        exit 1
    fi

    # Increment counter
    COUNTER=$((COUNTER + BATCH_SIZE))

    echo "Batch completed successfully"
    echo "-------------------------------------------"
done

echo "All files pushed successfully"
