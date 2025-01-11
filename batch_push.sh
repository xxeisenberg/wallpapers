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
BATCHES=$(( (TOTAL_FILES + BATCH_SIZE - 1) / BATCH_SIZE ))

echo "Total files to push: $TOTAL_FILES"
echo "Will push in $BATCHES batches of $BATCH_SIZE files"

# Process files in batches
for ((i = 0; i < TOTAL_FILES; i += BATCH_SIZE)); do
    echo "Processing batch $((i/BATCH_SIZE + 1)) of $BATCHES"

    # Add files in current batch
    for ((j = i; j < i + BATCH_SIZE && j < TOTAL_FILES; j++)); do
        FILE="${FILE_ARRAY[j]}"
        echo "Adding: $FILE"
        git add "$FILE"
    done

    # Commit current batch
    git commit -m "Batch $((i/BATCH_SIZE + 1))/$BATCHES: Adding files $((i+1)) to $((i + BATCH_SIZE))"

    # Push current batch
    git push

    if [ $? -ne 0 ]; then
        echo "Error pushing batch $((i/BATCH_SIZE + 1)). Stopping."
        exit 1
    fi

    echo "Batch $((i/BATCH_SIZE + 1)) completed successfully"
    echo "-------------------------------------------"
done

echo "All batches pushed successfully"
