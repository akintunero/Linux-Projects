.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash

SCRIPTS := $(shell find lib projects -name '*.sh' | sort)

.PHONY: help lint fmt fmt-check test check syntax setup

help: ## Show this help
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

lint: ## Run ShellCheck on every script
	shellcheck -x $(SCRIPTS)

fmt: ## Format scripts in place with shfmt
	shfmt -w -i 4 -ci lib projects tests/test_helper.bash

fmt-check: ## Fail if any script is not formatted
	shfmt -d -i 4 -ci lib projects tests/test_helper.bash

syntax: ## bash -n on every script
	@for f in $(SCRIPTS); do bash -n "$$f" || exit 1; done; echo "syntax ok"

test: ## Run the Bats test suite
	bats --timing tests/

check: lint fmt-check syntax test ## Everything CI runs

setup: ## Install dev tools on Debian/Ubuntu
	sudo apt-get update && sudo apt-get install -y bats shellcheck shfmt jq
