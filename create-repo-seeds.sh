#!/bin/bash
set -euo pipefail

repos=(
	"generic https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git"
	"aws https://git.launchpad.net/~canonical-kernel/ubuntu/+source/linux-aws/+git"
)
releases=(resolute noble jammy)

for repo in "${repos[@]}"; do
	read flavor baseurl <<< "$repo"
	for release in "${releases[@]}"; do
		echo "flavor:  $flavor"
		echo "release: $release"
		echo "url:     $baseurl/$release"

		if ! test -d "$flavor"; then
			git clone --bare "$baseurl/$release" "$flavor"
			( cd "$flavor" && \
				git remote rename origin "$release")

			continue
		fi

		(cd "$flavor" && \
			(git remote get-url "$release" >/dev/null 2>&1 || git remote add "$release" "$baseurl/$release") && \
			git fetch "$release" --tags)
	done

	while test -f ./$flavor/objects/maintenance.lock; do
		sleep 1
	done

	(cd "$flavor" && \
		tar -c --owner=root:0 --group=root:0 -f ../repo-seed/$flavor.tar.new . && \
		mv -v ../repo-seed/$flavor.tar.new ../repo-seed/$flavor.tar)
done
