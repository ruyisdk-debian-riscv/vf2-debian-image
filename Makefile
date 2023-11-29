unmatched:
	sudo rm -rf ./image/*
	DOCKER_BUILDKIT=1 docker-compose build vf2 
	docker-compose up vf2 


clean:
	sudo rm -rf ./image/*
	DOCKER_BUILDKIT=1 docker-compose build --no-cache
	docker-compose up
