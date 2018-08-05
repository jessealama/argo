.PHONY: clean test

clean:
	find . -mindepth 1 -maxdepth 1 -type f -name '*~' -delete
	find . -mindepth 1 -maxdepth 1 -type d -exec basename {} ';' | parallel --jobs=1 $(MAKE) -C {} clean

test:
	racket ../../../../schema.rkt schema.json
	find . -mindepth 1 -maxdepth 1 -type d -exec basename {} ';' | parallel --jobs=1 --halt-on-error now,fail=1 $(MAKE) -C {} test
