#	DB := $(shell docker run -d postgres)

build:
	docker build -q -t foobert/gc-storage .

test:
	$(eval DB := $(shell docker run -d postgres))
	docker run --rm --link $(DB):DB foobert/gc-storage node_modules/.bin/mocha
	docker rm -f $(DB)

test_dev:
	$(eval DB := $(shell docker run -d postgres))
	docker run --rm --link $(DB):DB -v $$PWD:/usr/src/app foobert/gc-storage node_modules/.bin/mocha --watch
	docker rm -f $(DB)

.PHONY: test
