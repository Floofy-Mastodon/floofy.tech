default:
	just --list

build: clean build-mastodon build-docker

clean:
	rm -rf build

update-mastodon: clean
    git clone https://github.com/glitch-soc/mastodon.git build/mastodon
    git -C build/mastodon log -n 1 --pretty=format:"%H" > .current

build-mastodon:
	#!/usr/bin/env bash
	set -euo pipefail
	mkdir -p build
	git clone https://github.com/glitch-soc/mastodon.git build/mastodon
	git -C build/mastodon checkout $(cat .current) .
	for file in ./patches/*; do
		echo "Applying ${file}"
		if [[ "$file" == *.diff ]]; then
			git -C build/mastodon -c commit.gpgsign=false apply "../.${file}"
		elif [[ "$file" == *.patch ]]; then
			git -C build/mastodon -c commit.gpgsign=false am "../.${file}"
		fi
	done

build-docker:
	TARGETPLATFORM=linux/amd64 docker buildx build build/mastodon -t ghcr.io/floofy-mastodon/mastodon:custom --build-arg MASTODON_VERSION_METADATA=floofy-custom --load -f build/mastodon/Dockerfile
	TARGETPLATFORM=linux/amd64 docker buildx build build/mastodon -t ghcr.io/floofy-mastodon/mastodon-streaming:custom --build-arg MASTODON_VERSION_METADATA=floofy-custom --load -f build/mastodon/streaming/Dockerfile

push-docker:
	docker push ghcr.io/floofy-mastodon/mastodon:custom
	docker push ghcr.io/floofy-mastodon/mastodon-streaming:custom

update-patches:
    #!/usr/bin/env python3
    import tomllib
    from urllib.request import urlretrieve
    import os

    with open('patches.toml', 'rb') as f:
       data = tomllib.load(f)

    for patch in data['patches']:
        name = data['patches'][patch]['name'] or f'{patch}.{data["patches"][patch]["mode"]}'
        path = os.path.join(data['patches_dir'], name)
        urlretrieve(data['patches'][patch]['url'], path)
