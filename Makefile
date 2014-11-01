web:
	cd web && jekyll serve

docker-clean:
	# remove all stopped containers
	docker ps -a -f status=exited | tail -n+2 | awk '{print $$1}' | xargs docker rm

.PHONY: web
