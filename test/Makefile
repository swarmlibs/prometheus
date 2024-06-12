make:
	docker network create --scope=swarm --driver=overlay --attachable dockerswarm_ingress || true
	docker network create --scope=swarm --driver=overlay --attachable dockerswarm_metrics || true
	docker network create --scope=swarm --driver=overlay --attachable prometheus_exporters || true
	docker stack deploy -c docker-stack.yml --detach=false prometheus_test

remove:
	docker stack rm prometheus_test
