IMAGE_NAME := techstreets/reactjs
IMAGE_TAG := 1.0.0
CONTAINER_NAME := reactjs
ENV_FILE_NAME := reactjs_env
HOST_PORT := 8102

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
current_dir := $(notdir $(patsubst %/,%,$(dir $(mkfile_path))))

MAKE_DIR := $(strip $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))

ifndef ${ENV_FILE_NAME}
	ifeq ($(shell test -s ./env && echo -n yes),yes)
		ENV_FILE := $(abspath ./env)
	else
		ENV_FILE := /dev/null
	endif
else
	ENV_FILE := ${${ENV_FILE_NAME}}
endif

.PHONY: all build clean create create_dev depend run_dev build_app deploy kill start stop restart shell docker_ip

all: create depend build_app deploy restart

build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

clean:
	docker images $(IMAGE_NAME) | grep -q $(IMAGE_TAG) && docker rmi $(IMAGE_NAME):$(IMAGE_TAG) || true

create:
	docker run --name $(CONTAINER_NAME) --restart=always --env-file $(ENV_FILE) -d -p $(HOST_PORT):80 -v $(MAKE_DIR):/opt/app $(IMAGE_NAME):$(IMAGE_TAG)

create_dev:
	docker run --name $(CONTAINER_NAME) --restart=always --env-file $(ENV_FILE) -d -p $(HOST_PORT):80 -p 3000:3000 -v $(MAKE_DIR):/opt/app $(IMAGE_NAME):$(IMAGE_TAG)

depend:
	docker exec -it $(CONTAINER_NAME) npm install

run_dev:
	docker exec -it $(CONTAINER_NAME) npm start

build_app:
	docker exec -it $(CONTAINER_NAME) npm run build

deploy:
	@cp -vrf $(MAKE_DIR)/build/* $(MAKE_DIR)/www/

dev: create_dev depend run_dev

kill:
	docker stop $(CONTAINER_NAME) && docker rm $(CONTAINER_NAME)

start:
	docker start $(CONTAINER_NAME)

stop:
	docker stop $(CONTAINER_NAME)

restart:
	docker restart $(CONTAINER_NAME)

shell:
	docker exec -it $(CONTAINER_NAME) bash

docker_ip:
	@ip addr show docker0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1
