docker_name := cars_db:latest
container_name := cars-storage
run_flags := --rm -it -d

PORT := 8081

docker_build:
	sudo docker build -t ${docker_name} .
	
docker_run:
	sudo docker run ${run_flags} --name ${container_name} \
		-p ${PORT}:8081 \
		-e PORT=8081 \
        ${docker_name}

docker_stop:
	sudo docker stop ${container_name}
