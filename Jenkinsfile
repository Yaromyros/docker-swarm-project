pipeline {
    agent any

    environment {
        PATH = "/usr/local/bin:/opt/homebrew/bin:/Users/yaromyrm/ansible-venv/bin:${env.PATH}"
        DOCKER_REGISTRY = '127.0.0.1:5000'
        IMAGE_NAME      = 'hello-world-app'
        IMAGE_TAG       = "${BUILD_NUMBER}"
        FULL_IMAGE      = "${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        LATEST_IMAGE    = "${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
    }

    stages {

        stage('Clone Repository') {
            steps {
                echo '📥 Клонування репозиторію...'
                git branch: 'main',
                    url: 'https://github.com/Yaromyros/docker-swarm-project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🔨 Збірка Docker імеджу...'
                sh """
                    docker build -t ${FULL_IMAGE} -f Dockerfile .
                    docker tag ${FULL_IMAGE} ${LATEST_IMAGE}
                """
            }
        }

        stage('Push to Docker Registry') {
            steps {
                echo '📤 Пуш імеджу в Docker Registry...'
                sh """
                    docker push ${FULL_IMAGE}
                    docker push ${LATEST_IMAGE}
                """
            }
        }

        stage('Ansible: Check Docker') {
            steps {
                echo '🔍 Перевірка Docker на всіх воркерах...'
                sh "ansible-playbook -i hosts.ini 01_check_docker.yml -v"
            }
        }

        stage('Ansible: Setup Swarm') {
            steps {
                echo '🐝 Перевірка та налаштування Docker Swarm...'
                sh "ansible-playbook -i hosts.ini 02_setup_swarm.yml -v"
            }
        }

        stage('Ansible: Deploy to Swarm') {
            steps {
                echo '🚀 Розгортання додатку в Docker Swarm...'
                sh "ansible-playbook -i hosts.ini 03_deploy_app.yml -e app_image_tag=${IMAGE_TAG} -v"
            }
        }
    }

    post {
        success {
            echo '✅ ДЕПЛОЙ УСПІШНИЙ!'
        }
        failure {
            echo '❌ ДЕПЛОЙ ПРОВАЛИВСЯ!'
        }
        always {
            sh "docker image prune -f || true"
        }
    }
}
