#!/bin/bash
# =============================================================
# setup_macos.sh — Налаштування всього на macOS
# =============================================================
# Запуск: chmod +x setup_macos.sh && ./setup_macos.sh
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE} Налаштування Jenkins + Docker Swarm + Ansible${NC}"
echo -e "${BLUE} macOS — без віртуальних машин${NC}"
echo -e "${BLUE}============================================${NC}"

# -----------------------------------------------------------
# 1. Перевірка Homebrew
# -----------------------------------------------------------
echo -e "\n${YELLOW}[1/7] Перевірка Homebrew...${NC}"
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Homebrew не знайдений. Встановіть з https://brew.sh${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Homebrew знайдений${NC}"

# -----------------------------------------------------------
# 2. Встановлення Docker Desktop
# -----------------------------------------------------------
echo -e "\n${YELLOW}[2/7] Перевірка Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Встановлення Docker Desktop...${NC}"
    brew install --cask docker
    echo -e "${YELLOW}⚠️  Відкрийте Docker Desktop вручну і дочекайтесь запуску${NC}"
    echo -e "${YELLOW}   Потім запустіть цей скрипт знову${NC}"
    exit 0
else
    echo -e "${GREEN}✅ Docker $(docker --version)${NC}"
fi

# Перевірка що Docker daemon працює
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker daemon не запущений. Відкрийте Docker Desktop${NC}"
    exit 1
fi

# -----------------------------------------------------------
# 3. Встановлення Jenkins
# -----------------------------------------------------------
echo -e "\n${YELLOW}[3/7] Налаштування Jenkins...${NC}"
if ! brew list jenkins-lts &> /dev/null 2>&1; then
    echo "Встановлення Jenkins LTS..."
    brew install jenkins-lts
fi
echo -e "${GREEN}✅ Jenkins встановлений${NC}"

# Запуск Jenkins
echo "Запуск Jenkins..."
brew services start jenkins-lts || true
echo -e "${GREEN}✅ Jenkins запущений на http://localhost:8080${NC}"

# -----------------------------------------------------------
# 4. Встановлення Ansible
# -----------------------------------------------------------
echo -e "\n${YELLOW}[4/7] Налаштування Ansible...${NC}"
if ! command -v ansible &> /dev/null; then
    echo "Встановлення Ansible..."
    brew install ansible
fi
echo -e "${GREEN}✅ Ansible $(ansible --version | head -1)${NC}"

# -----------------------------------------------------------
# 5. Запуск Docker Registry (локальний)
# -----------------------------------------------------------
echo -e "\n${YELLOW}[5/7] Запуск локального Docker Registry...${NC}"
if ! docker ps | grep -q registry; then
    docker run -d \
        --name registry \
        --restart always \
        -p 5000:5000 \
        registry:2
    echo -e "${GREEN}✅ Docker Registry запущений на localhost:5000${NC}"
else
    echo -e "${GREEN}✅ Docker Registry вже працює${NC}"
fi

# -----------------------------------------------------------
# 6. Ініціалізація Docker Swarm
# -----------------------------------------------------------
echo -e "\n${YELLOW}[6/7] Ініціалізація Docker Swarm...${NC}"
SWARM_STATUS=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)
if [ "$SWARM_STATUS" != "active" ]; then
    docker swarm init --advertise-addr 127.0.0.1 || true
    echo -e "${GREEN}✅ Docker Swarm ініціалізовано${NC}"
else
    echo -e "${GREEN}✅ Docker Swarm вже активний${NC}"
fi

# -----------------------------------------------------------
# 7. Налаштування Docker daemon для insecure registry
# -----------------------------------------------------------
echo -e "\n${YELLOW}[7/7] Перевірка Docker daemon config...${NC}"
DOCKER_CONFIG="$HOME/.docker/daemon.json"
if [ -f "$DOCKER_CONFIG" ]; then
    if ! grep -q "127.0.0.1:5000" "$DOCKER_CONFIG"; then
        echo -e "${YELLOW}⚠️  Додайте до Docker Desktop → Settings → Docker Engine:${NC}"
        echo '  "insecure-registries": ["127.0.0.1:5000"]'
    else
        echo -e "${GREEN}✅ Insecure registry вже налаштований${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Додайте до Docker Desktop → Settings → Docker Engine:${NC}"
    echo '  "insecure-registries": ["127.0.0.1:5000"]'
fi

# -----------------------------------------------------------
# Результат
# -----------------------------------------------------------
echo -e "\n${BLUE}============================================${NC}"
echo -e "${GREEN} ✅ Все готово!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e " Jenkins:        ${GREEN}http://localhost:8080${NC}"
echo -e " Docker Registry: ${GREEN}http://localhost:5000${NC}"
echo -e " App (після деплою): ${GREEN}http://localhost:8080${NC}"
echo ""
echo -e " ${YELLOW}Наступні кроки:${NC}"
echo -e " 1. Відкрийте Jenkins: http://localhost:8080"
echo -e " 2. Пароль: cat ~/.jenkins/secrets/initialAdminPassword"
echo -e " 3. Встановіть плагіни: Git, Pipeline, Docker Pipeline, AnsiColor"
echo -e " 4. Створіть Pipeline job → вкажіть ваш GitHub repo"
echo -e " 5. Запустіть білд!"
echo ""
echo -e " ${YELLOW}Для GitHub:${NC}"
echo -e " cd docker-swarm-project"
echo -e " git init && git add . && git commit -m 'Initial commit'"
echo -e " git remote add origin https://github.com/YOUR_USERNAME/docker-swarm-project.git"
echo -e " git push -u origin main"
echo -e "${BLUE}============================================${NC}"
