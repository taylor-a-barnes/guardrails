#!/bin/sh

IMAGE=$(cat .podman/image_name)
PORT="${1:-0}"

podman build -t "$IMAGE" .

# Copy the run script from the image
CID=$(podman create $IMAGE)
podman cp $CID:/.podman/interface.sh .interface.sh > /dev/null
podman rm -v $CID > /dev/null

# Run the image's interface script
if [ "$PORT" -eq 0 ]; then
    bash .interface.sh $IMAGE
else
    bash .interface.sh $IMAGE $PORT
fi
