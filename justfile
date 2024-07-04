default:
	just --list

build: clean build-mastodon build-docker commit-current-commit

clean:
	rm -rf build

build-mastodon:
	mkdir -p build
	git clone --depth 1 https://github.com/glitch-soc/mastodon.git build/mastodon
	git -C build/mastodon -c commit.gpgsign=false apply ../../patches/0000-podman-compat.diff
	git -C build/mastodon -c commit.gpgsign=false am ../../patches/0001-emoji-reactions.patch
	git -C build/mastodon -c commit.gpgsign=false apply ../../patches/0002-redis-sentinel.diff

build-docker:
	TARGETPLATFORM=linux/amd64 docker buildx build build/mastodon -t ghcr.io/floofy-mastodon/mastodon:custom --build-arg MASTODON_VERSION_METADATA=floofy-custom --load -f build/mastodon/Dockerfile
	TARGETPLATFORM=linux/amd64 docker buildx build build/mastodon -t ghcr.io/floofy-mastodon/mastodon-streaming:custom --build-arg MASTODON_VERSION_METADATA=floofy-custom --load -f build/mastodon/streaming/Dockerfile

push-docker:
	docker push ghcr.io/floofy-mastodon/mastodon:custom
	docker push ghcr.io/floofy-mastodon/mastodon-streaming:custom

commit-current-commit:
	git -C build/mastodon log -n 1 --pretty=format:"%H" > .current
