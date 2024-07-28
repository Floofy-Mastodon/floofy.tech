default:
	just --list

build: clean build-mastodon build-docker commit-current-commit

clean:
	rm -rf build

build-mastodon:
	#!/usr/bin/env sh
	set -euo pipefail
	mkdir -p build
	git clone --depth 1 https://github.com/glitch-soc/mastodon.git build/mastodon
	for file in ./patches/*; do

		if [[ "$file" == *.diff ]]; then
		    echo "Applying ${file}"
			git -C build/mastodon -c commit.gpgsign=false apply "../.${file}"
		elif [[ "$file" == *.patch ]]; then
		    echo "Applying ${file}"
			git -C build/mastodon -c commit.gpgsign=false am "../.${file}"
		fi
	done


build-docker:
	TARGETPLATFORM=linux/amd64 docker buildx build build/mastodon -t ghcr.io/floofy-mastodon/mastodon:custom --build-arg MASTODON_VERSION_METADATA=floofy-custom --load -f build/mastodon/Dockerfile
	TARGETPLATFORM=linux/amd64 docker buildx build build/mastodon -t ghcr.io/floofy-mastodon/mastodon-streaming:custom --build-arg MASTODON_VERSION_METADATA=floofy-custom --load -f build/mastodon/streaming/Dockerfile

push-docker:
	docker push ghcr.io/floofy-mastodon/mastodon:custom
	docker push ghcr.io/floofy-mastodon/mastodon-streaming:custom

commit-current-commit:
	git -C build/mastodon log -n 1 --pretty=format:"%H" > .current

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
