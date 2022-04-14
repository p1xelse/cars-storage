docker_name := cars_db:latest
docker_name_test := cars_db_test:latest
container_name := cars-storage
run_flags := --rm -it -d

PORT := 8081

docker_build:
	sudo docker build -t ${docker_name} . 
docker_build_test:
	sudo docker build -f ${CURDIR}/Dockerfile_test -t ${docker_name_test} . 
	
docker_run:
	sudo docker run ${run_flags} --name ${container_name} \
		-p ${PORT}:8081 \
		-e PORT=8081 \
        ${docker_name}
	
docker_run_test:
	sudo docker run ${run_flags} --name ${container_name} \
        ${docker_name_test}	
	docker exec -i -t cars-storage bash

	

	

docker_stop:
	sudo docker stop ${container_name}
