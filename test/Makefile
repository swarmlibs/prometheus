docker-stack-name = test_prometheus

it:
	@echo "make [deploy|remove|clean|reset] docker-stack-name=$(docker-stack-name)"

deploy:
	docker network create --scope=swarm --driver=overlay --attachable dockerswarm_ingress || true
	docker network create --scope=swarm --driver=overlay --attachable dockerswarm_metrics || true
	docker network create --scope=swarm --driver=overlay --attachable prometheus_exporters || true
	docker stack deploy -c docker-stack.yml $(docker-stack-name)

remove:
	docker stack rm --detach=false $(docker-stack-name)

clean:
	@sleep 10
	docker volume ls -q | grep $(docker-stack-name) | xargs docker volume rm

reset: remove clean deploy
