docker-stack-name = default_node_exporter

it:
	@echo "make [deploy|remove|clean|reset] docker-stack-name=$(docker-stack-name)"

deploy:
	docker stack deploy -c docker-stack.yml $(docker-stack-name)

remove:
	docker stack rm --detach=false $(docker-stack-name)

clean:
	@sleep 10
	docker volume ls -q | grep $(docker-stack-name) | xargs docker volume rm

reset: remove clean deploy
