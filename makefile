build:
	docker image build -t huguesmcd/reverseproxy .

deploy:
	docker push huguesmcd/reverseproxy

build-and-deploy: build deploy

restart:
	docker service update --replicas 0 reverseproxy
	docker service update --replicas 1 reverseproxy