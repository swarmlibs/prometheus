docker-stack-name = test_prometheus

it:
	@echo "make [deploy|remove|clean|reset] docker-stack-name=$(docker-stack-name)"

networks:
	@docker network create --scope=swarm --driver=overlay --attachable dockerswarm_ingress > /dev/null 2>&1 || true
	@docker network create --scope=swarm --driver=overlay --attachable dockerswarm_metrics > /dev/null 2>&1 || true
	@docker network create --scope=swarm --driver=overlay --attachable prometheus_exporters > /dev/null 2>&1 || true

deploy: networks
	docker stack deploy -c docker-stack.yml $(docker-stack-name)

remove:
	docker stack rm --detach=false $(docker-stack-name)

clean:
	@sleep 10
	docker volume ls -q | grep $(docker-stack-name) | xargs docker volume rm

reset: remove clean deploy
