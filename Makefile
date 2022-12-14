IMAGE_REPO=mataelang/snort-base
SNORT_VERSION=3.1.47.0
LIBDAQ_VERSION=3.0.9
TARGET_PLATFORMS=linux/amd64 linux/arm64

comma:= ,
empty:=
space:= $(empty) $(empty)
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
CYAN   := $(shell tput -Txterm setaf 6)
RESET  := $(shell tput -Txterm sgr0)

build: ## Build docker image then load it to local
	@docker build -f dockerfiles/debian.dockerfile -t snort-base

build-push: ## Build docker image for all OS and ARCH then push it to repos
	@docker buildx bake -f docker-bake.hcl --pull --push

build-alpine: ## Build docker image using alpine then load it to local
	@docker build -f dockerfiles/alpine.dockerfile -t snort-base

help: ## Show this help.
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf "    ${YELLOW}%-20s${GREEN}%s${RESET}\n", $$1, $$2} \
		else if (/^## .*$$/) {printf "  ${CYAN}%s${RESET}\n", substr($$1,4)} \
		}' $(MAKEFILE_LIST)