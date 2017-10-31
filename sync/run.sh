#!/bin/sh

if [ -z "$POD_NAME" ]; then
  echo >&2 error: must specify POD_NAME environment variable
  exit 1
fi
if [ -z "$TARGET_CONTAINER" ]; then
  echo >&2 error: must specify TARGET_CONTAINER environment variable
fi

if [ -n "$TARGET_CONTAINER" -a -z "$SYNC_TARGET" ]; then
  while true; do
    READY=$(kubectl get pod $POD_NAME -o go-template='{{ range .status.containerStatuses }}{{ if eq .name "'$TARGET_CONTAINER'" }}{{ .ready }}{{ end }}{{ end }}')
    if [ "$READY" == "true" ]; then
      break
    fi
    echo info: waiting for target container...
    sleep 1
  done
  HAS_FIND=$(kubectl exec 2>/dev/null $POD_NAME -c $TARGET_CONTAINER -- which find)
  if [ -n "$HAS_FIND" ]; then
    CONTEXT_MARKER=$(kubectl exec 2>/dev/null $POD_NAME -c $TARGET_CONTAINER -- sh -c 'PWD="$(pwd)"
      while true; do
        FOUND=$(find "$PWD" -name .mindaro)
        if [ -n "$FOUND" ]; then
          rm -f "$FOUND"
          echo $FOUND
          break
        elif [ -n "$(echo $PWD | grep -o ^/$)" ]; then
          break
        fi
        PWD=$(dirname "$PWD")
      done')
    if [ -n "$CONTEXT_MARKER" ]; then
      SYNC_TARGET=$(dirname "$CONTEXT_MARKER")
      echo info: automatically determined sync target
    fi
  fi
fi

if [ -z "$TARGET_CONTAINER" -o -z "$SYNC_TARGET" ]; then
  echo info: target container and/or sync target are unknown\; sync is disabled
else
  echo info: target container is \"$TARGET_CONTAINER\"
  echo info: sync target is \"$SYNC_TARGET\"
fi

dcwatch | while read action file; do
  if [ -z "$TARGET_CONTAINER" -o -z "$SYNC_TARGET" ]; then
    continue
  fi
  DELETE=$(echo "$action" | grep -)
  if [ -n "$DELETE" ]; then
    echo info: deleting \"$SYNC_TARGET/$file\"
    kubectl exec $POD_NAME -c $TARGET_CONTAINER -- rm -rf "$SYNC_TARGET/$file"
  elif [ -d "$file" ]; then
    echo info: ensuring directory \"$SYNC_TARGET/$file\" exists
    kubectl exec $POD_NAME -c $TARGET_CONTAINER -- mkdir -p "$SYNC_TARGET/$file"
  else
    DIR=$(dirname "$file")
    echo info: ensuring directory \"$SYNC_TARGET/$DIR\" exists
    kubectl exec $POD_NAME -c $TARGET_CONTAINER -- mkdir -p "$SYNC_TARGET/$DIR"
    echo info: copying file \"$file\" to \"$SYNC_TARGET/$file\"
    kubectl cp "$file" $POD_NAME:"$SYNC_TARGET/$file" -c $TARGET_CONTAINER
  fi
done
