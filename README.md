# Docker Swarm Deployment — Jenkins + Ansible

CI/CD пайплайн для розгортання Hello World додатку через Jenkins, Ansible і Docker Swarm на macOS.

## Архітектура

```
GitHub Repo
    │
    ▼
Jenkins Pipeline
    │
    ├─ 1. git clone
    ├─ 2. docker build
    ├─ 3. docker push → Local Registry (:5000)
    ├─ 4. ansible: перевірка Docker
    ├─ 5. ansible: перевірка/init Swarm
    └─ 6. ansible: deploy → Swarm cluster
                                │
                        ┌───────┴───────┐
                        │               │
                    Worker 1        Worker 2
                   (replica)       (replica)
```

## Структура файлів

```
docker-swarm-project/
├── Jenkinsfile                    # CI/CD пайплайн
├── setup_macos.sh                 # Скрипт налаштування macOS
├── app/
│   ├── Dockerfile                 # Docker імедж
│   ├── app.py                     # Flask Hello World
│   └── requirements.txt
└── ansible/
    ├── ansible.cfg
    ├── inventory/
    │   └── hosts.ini              # Інвентар хостів
    └── playbooks/
        ├── 01_check_docker.yml    # Перевірка Docker
        ├── 02_setup_swarm.yml     # Налаштування Swarm
        └── 03_deploy_app.yml      # Деплой додатку
```

## Швидкий старт на macOS

### 1. Запустіть скрипт налаштування

```bash
chmod +x setup_macos.sh
./setup_macos.sh
```

Скрипт встановить: Docker Desktop, Jenkins LTS, Ansible, локальний Docker Registry, ініціалізує Swarm.

### 2. Налаштуйте Docker Desktop

Відкрийте Docker Desktop → Settings → Docker Engine, додайте:

```json
{
  "insecure-registries": ["127.0.0.1:5000"]
}
```

### 3. Пушніть проект на GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/docker-swarm-project.git
git push -u origin main
```

### 4. Налаштуйте Jenkins

1. Відкрийте http://localhost:8080
2. Введіть пароль: `cat ~/.jenkins/secrets/initialAdminPassword`
3. Встановіть рекомендовані плагіни + **Docker Pipeline**, **AnsiColor**
4. Створіть **New Item** → **Pipeline**
5. У Pipeline → Definition: **Pipeline script from SCM**
6. SCM: **Git** → вкажіть URL вашого GitHub репо
7. Branch: `*/main`
8. Script Path: `Jenkinsfile`
9. **Save** → **Build Now**

## Ручний запуск Ansible плейбук

```bash
cd ansible

# Перевірка Docker
ansible-playbook -i inventory/hosts.ini playbooks/01_check_docker.yml

# Налаштування Swarm
ansible-playbook -i inventory/hosts.ini playbooks/02_setup_swarm.yml

# Деплой додатку
ansible-playbook -i inventory/hosts.ini playbooks/03_deploy_app.yml
```

## Ручний білд та пуш

```bash
cd app
docker build -t 127.0.0.1:5000/hello-world-app:latest .
docker push 127.0.0.1:5000/hello-world-app:latest
```

## Перевірка

```bash
# Статус Swarm
docker node ls

# Сервіси
docker service ls

# Логи сервісу
docker service logs hello-world-service

# HTTP тест
curl http://localhost:8080
```

## Для продакшну з реальними воркерами

Відредагуйте `ansible/inventory/hosts.ini` — замініть IP-адреси на адреси ваших реальних машин, та налаштуйте SSH-доступ:

```bash
ssh-copy-id your_user@192.168.1.101
ssh-copy-id your_user@192.168.1.102
```
