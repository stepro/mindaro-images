#!/bin/sh

if [ -z "$POD_NAME" ]; then
  echo >&2 error: must specify POD_NAME environment variable
  exit 1
fi
if [ -z "$TARGET_CONTAINER" ]; then
  echo >&2 error: must specify TARGET_CONTAINER environment variable
  exit 1
fi
if [ -z "$TARGET_DIR" ]; then
  echo >&2 error: must specify TARGET_DIR environment variable
  exit 1
fi

dcwatch | while read action file; do
  DELETE=$(echo "$action" | grep -)
  if [ -n "$DELETE" ]; then
    echo kubectl exec $POD_NAME -c $TARGET_CONTAINER -- rm -rf \"$TARGET_DIR/$file\"
    kubectl exec $POD_NAME -c $TARGET_CONTAINER -- rm -rf "$TARGET_DIR/$file"
  elif [ -d "$file" ]; then
    echo kubectl exec $POD_NAME -c $TARGET_CONTAINER -- mkdir -p \"$TARGET_DIR/$file\"
    kubectl exec $POD_NAME -c $TARGET_CONTAINER -- mkdir -p "$TARGET_DIR/$file"
  else
    DIR=$(dirname "$file")
    echo kubectl exec $POD_NAME -c $TARGET_CONTAINER -- mkdir -p \"$TARGET_DIR/$DIR\"
    kubectl exec $POD_NAME -c $TARGET_CONTAINER -- mkdir -p "$TARGET_DIR/$DIR"
    echo kubectl cp \"$file\" $POD_NAME:\"$TARGET_DIR/$file\" -c $TARGET_CONTAINER
    kubectl cp "$file" $POD_NAME:"$TARGET_DIR/$file" -c $TARGET_CONTAINER
  fi
done
