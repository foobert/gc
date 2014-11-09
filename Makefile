app:
	docker run --rm=true -p 4567:4567 -e DB=tcp://192.168.10.1:28015 -v $$PWD/app:/app gc-app-dev

web:
	docker run --rm=true -p 4000:4000 -v $$PWD/web:/web gc-web-dev

clean:
	# Remove all stopped containers
	docker ps -a -f status=exited | tail -n+2 | awk '{print $$1}' | xargs docker rm
	# Remove all stale images
	docker images | grep '^<none>' | awk '{print $$3}' | xargs docker rmi

docker: docker-app docker-db docker-web

docker-dev: docker-app-dev docker-web-dev

docker-app:
	docker build -t gc-app app

docker-db:
	docker build -t gc-db db

docker-web:
	docker build -t gc-web web

docker-app-dev:
	docker build -t gc-app-dev - < app/Dockerfile.dev

docker-web-dev:
	docker build -t gc-web-dev - < web/Dockerfile.dev

.PHONY: web app clean
