.PHONY: clean test

clean:
	find . -mindepth 1 -maxdepth 1 -type f -name '*~' -delete
	find . -mindepth 1 -maxdepth 1 -type d -exec basename {} ';' | parallel --jobs=1 $(MAKE) -C {} clean

test:
	find . -maxdepth 1 -mindepth 1 -type f -name '*.json' | parallel --jobs=1 --timeout 10 --halt-on-error now,fail=1 racket ../../../../../main.rkt --quiet ../schema.json {}
