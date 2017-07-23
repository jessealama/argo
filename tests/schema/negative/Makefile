.PHONY: clean test

clean:
	find . -mindepth 1 -maxdepth 1 -type f -name '*~' -delete
	find . -mindepth 1 -maxdepth 1 -type d -exec basename {} ';' | parallel --jobs=1 $(MAKE) -C {} clean

test:
	find . -maxdepth 1 -type d -exec basename {} ';' | parallel --jobs=1 --halt now,fail=1 racket test.rkt {}
