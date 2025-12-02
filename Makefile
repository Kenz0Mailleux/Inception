# **************************************************************************** #
#                                   Makefile                                   #
# **************************************************************************** #

NAME          := inception
COMPOSE_FILE  := srcs/docker-compose.yml
ENV_FILE      := srcs/.env

# DATA_DIR      := /home/kmailleu/data
# DB_DIR        := $(DATA_DIR)/mariadb
# WP_DIR        := $(DATA_DIR)/wordpress
DATA_DIR      	:= /home/kenzo/data
DB_DIR        	:= $(DATA_DIR)/mariadb
WP_DIR       	 := $(DATA_DIR)/wordpress


all: up

.PHONY: up build down restart logs ps clean fclean re prune

prepare_dirs:
	@sudo mkdir -p $(DB_DIR) $(WP_DIR)
	@sudo chown -R $$USER:$$USER $(DB_DIR) $(WP_DIR)
	@echo "✅ Dossiers de données prêts: $(DB_DIR) / $(WP_DIR)"

up: prepare_dirs
	@docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) up -d --build
	@echo "🚀 $(NAME) up"

build:
	@docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) build --no-cache

down:
	@docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down

restart:
	@docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) restart

logs:
	@docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f --tail=200

ps:
	@docker compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) ps

clean: down
	@docker volume rm -f mariadb_data_kmailleu wordpress_data_kmailleu || true
	@echo "🧹 Volumes Docker supprimés"

fclean: clean
	@sudo rm -rf $(DB_DIR) $(WP_DIR)
	@echo "🗑️  Dossiers de données supprimés"

re: fclean all

prune:
	@docker system prune -af --volumes
