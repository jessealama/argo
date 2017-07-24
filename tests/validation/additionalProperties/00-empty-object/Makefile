.PHONY: clean test

clean:
	find . -mindepth 1 -maxdepth 1 -type f -name '*~' -delete
	find . -mindepth 1 -maxdepth 1 -type d -exec basename {} ';' | parallel --jobs=1 $(MAKE) -C {} clean

test:
	test -f schema.json
	find positive -maxdepth 1 -mindepth 1 -type f -name '*.json' | parallel --halt-on-error racket ../../../../argo.rkt --quiet schema.json {}
	find negative -maxdepth 1 -mindepth 1 -type f -name '*.json' | parallel --jobs=1 "../../../../invert-exit-code.sh racket ../../../../argo.rkt --quiet schema.json"
