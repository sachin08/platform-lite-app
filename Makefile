# Start application
start:
	docker compose up --build -d

# Stop application
stop:
	docker compose down

# Restart application
restart:
	docker compose down && docker compose up --build -d

# View logs
logs:
	docker compose logs -f

# Clean containers and volumes
clean:
	docker compose down -v

# Show running containers
status:
	docker compose ps