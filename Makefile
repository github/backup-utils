SHELL = /bin/sh

test:
	@echo "Running tests ..."
	@ls -1 test/test-*.sh | xargs -P 4 -n 1 $(SHELL)

info:
	@echo "shell is $(SHELL)"
	@rsync --version | head -1
	@echo

.PHONY: test info
