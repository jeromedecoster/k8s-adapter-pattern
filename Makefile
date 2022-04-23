.SILENT:
.PHONY: vote metrics

help:
	{ grep --extended-regexp '^[a-zA-Z_-]+:.*#[[:space:]].*$$' $(MAKEFILE_LIST) || true; } \
	| awk 'BEGIN { FS = ":.*#[[:space:]]*" } { printf "\033[1;32m%-15s\033[0m%s\n", $$1, $$2 }'

redis: # run redis alpine docker image
	./make.sh redis

vote: # run vote website using npm - dev mode (livereload + nodemon)
	./make.sh vote

compose-dev: # run the project using docker-compose (same as redis + vote + ...)
	./make.sh compose-dev

docker-build: # build the vote + metrics docker images
	./make.sh docker-build

prometheus: # run prometheus
	./make.sh prometheus

metrics: # run metrics server using npm
	./make.sh metrics

grafana: # run grafana
	./make.sh grafana

configure: # configure grafana
	./make.sh configure
