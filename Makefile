# Makefile for launching a Fig/Dockerized Rails app backed by PostgreSQL

APP_PATH := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
APP_NAME := $(notdir $(APP_PATH))
APP_HOME := \/usr\/home\/$(APP_NAME)
GID := 1000
UID := 1000
VOLUME_ROOT_DIR := $(HOME)/.docker-volumes

configure:
	if [ ! -d $(VOLUME_ROOT_DIR)/$(APP_NAME)/db ] ; then mkdir -p $(VOLUME_ROOT_DIR)/$(APP_NAME)/db ; fi
	if [ ! -e $(APP_PATH)/Gemfile ] ; then echo "source 'https://rubygems.org'\ngem 'rails', '~> 4.1.0'" > Gemfile ; fi
	sed -i 's/%%app_home%%/$(APP_HOME)/' Dockerfile ;
	sed -i 's/%%gid%%/$(GID)/' Dockerfile ;
	sed -i 's/%%uid%%/$(UID)/' Dockerfile ;
	sed -i 's/%%app_home%%/$(APP_HOME)/' docker-compose.yml ;
	sed -i 's/%%app_name%%/$(APP_NAME)/' docker-compose.yml ;

install:
	dc build
	if [ ! -d $(APP_PATH)/app ] ; then \
		dc run --rm web rails new . --force --database=postgresql --skip-bundle ; \
		sudo chown -R $(UID):$(GID) . ; \
		sed -i 's/default: &default/default: \&default\n  host: db\n  username: postgres/' config/database.yml ; \
		dc build web ; \
		dc run --rm web rake db:create ; \
		dc run --rm web rake db:migrate ; \
		dc up -d web ; \
	fi ;

clean:
	$(MAKE) clean-app
	$(MAKE) clean-volumes

clean-app:
	find $(APP_PATH) -mindepth 1 -maxdepth 1 \
		-name .dockerignore -prune -o \
		-name Dockerfile -prune -o \
		-name Makefile -prune -o \
		-name docker-compose.yml -prune -o \
		-exec rm -rf "{}" \; ;
	sed -i 's/$(APP_HOME)/%%app_home%%/' Dockerfile
	sed -i 's/$(GID)/%%gid%%/' Dockerfile
	sed -i 's/$(UID)/%%uid%%/' Dockerfile
	sed -i 's/$(APP_HOME)/%%app_home%%/' docker-compose.yml
	sed -i 's/$(APP_NAME)/%%app_name%%/' docker-compose.yml

clean-volumes:
	sudo rm -rf $(VOLUME_ROOT_DIR)/$(APP_NAME)

clean-db-volume:
	sudo rm -rf $(VOLUME_ROOT_DIR)/$(APP_NAME)/db
