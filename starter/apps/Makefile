THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
THIS_DIR      := $(dir $(realpath $(THIS_MAKEFILE)))

.PHONY: compose-all compose-build compose-stop compose-start 

compose-all: stop build start 

compose-stop:
	@cd $(THIS_DIR) && docker compose down 

compose-start:
	@cd $(THIS_DIR) && docker compose up -d 

compose-build:
	@cd $(THIS_DIR) && docker compose build --no-cache
