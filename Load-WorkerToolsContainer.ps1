# Prefer using PowerShell references.
docker run --rm -it --workdir=/terraform --entrypoint="/bin/bash" -v ${PWD}:/terraform -v /var/run/docker.sock:/var/run/docker.sock docker.io/library/worker-tools:0.0.1