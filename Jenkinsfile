pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = '127.0.0.1:5000'
        IMAGE_NAME      = 'hello-world-app'
        IMAGE_TAG       = "${BUILD_NUMBER}"
        FULL_IMAGE      = "${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        LATEST_IMAGE    = "${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
        GITHUB_REPO     = 'https://github.com/Yaromyros/docker-swarm-project.git'
        ANSIBLE_DIR     = 'ansible'
    }

    stages {

        // =========================================================
        // ЕТАП 1: Клонування репозиторію з GitHub
        // =========================================================
        stage('Clone Repository') {
            steps {
                echo '📥 Клонування репозиторію...'
                git branch: 'main',
                    url: "${GITHUB_REPO}"
            }
        }

        // =========================================================
        // ЕТАП 2: Build Docker імеджу
        // =========================================================
        stage('Build Docker Image') {
            steps {
                echo '🔨 Збірка Docker імеджу...'
                dir('app') {
                    sh """
                        docker build -t ${FULL_IMAGE} .
                        docker tag ${FULL_IMAGE} ${LATEST_IMAGE}
                    """
                }
            }
        }

        // =========================================================
        // ЕТАП 3: Push в Docker Registry
        // =========================================================
        stage('Push to Docker Registry') {
            steps {
                echo '📤 Пуш імеджу в Docker Registry...'
                sh """
                    docker push ${FULL_IMAGE}
                    docker push ${LATEST_IMAGE}
                """
            }
        }

        // =========================================================
        // ЕТАП 4: Ansible — Перевірка Docker на воркерах
        // =========================================================
        stage('Ansible: Check Docker') {
            steps {
                echo '🔍 Перевірка Docker на всіх воркерах...'
                dir("${ANSIBLE_DIR}") {
                    sh """
                        ansible-playbook \
                            -i inventory/hosts.ini \
                            playbooks/01_check_docker.yml \
                            -v
                    """
                }
            }
        }

        // =========================================================
        // ЕТАП 5: Ansible — Налаштування Swarm кластеру
        // =========================================================
        stage('Ansible: Setup Swarm') {
            steps {
                echo '🐝 Перевірка та налаштування Docker Swarm...'
                dir("${ANSIBLE_DIR}") {
                    sh """
                        ansible-playbook \
                            -i inventory/hosts.ini \
                            playbooks/02_setup_swarm.yml \
                            -v
                    """
                }
            }
        }

        // =========================================================
        // ЕТАП 6: Ansible — Деплой в Swarm
        // =========================================================
        stage('Ansible: Deploy to Swarm') {
            steps {
                echo '🚀 Розгортання додатку в Docker Swarm...'
                dir("${ANSIBLE_DIR}") {
                    sh """
                        ansible-playbook \
                            -i inventory/hosts.ini \
                            playbooks/03_deploy_app.yml \
                            -e "app_image_tag=${IMAGE_TAG}" \
                            -v
                    """
                }
            }
        }
    }

    post {
        success {
            echo """
            ✅ ====================================
            ✅  ДЕПЛОЙ УСПІШНИЙ!
            ✅ ====================================
            ✅  Імедж: ${FULL_IMAGE}
            ✅  Сервіс: http://localhost:8080
            ✅ ====================================
            """
        }
        failure {
            echo """
            ❌ ====================================
            ❌  ДЕПЛОЙ ПРОВАЛИВСЯ!
            ❌ ====================================
            """
        }
        always {
            echo '🧹 Очистка...'
            sh "docker image prune -f || true"
        }
    }
}
