# 1. Imagem Base
FROM php:8.2-fpm

ARG user=teste
ARG uid=1000

RUN apt-get update && \
    apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    gnupg2 \
    ca-certificates \
    apt-transport-https \
    netcat-openbsd && \
    curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copiar apenas os arquivos de dependências primeiro
COPY composer.json composer.lock ./
COPY package.json package-lock.json* ./

# Criar grupo e usuário antes de instalar dependências
RUN groupadd -g $uid $user || true && \
    useradd -G www-data -g $user -u $uid -d /home/$user -s /bin/bash $user

RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Copiar o restante dos arquivos
COPY --chown=$user:www-data . .

# Criar diretórios necessários com permissões corretas
RUN mkdir -p storage/framework/{sessions,views,cache} \
    && mkdir -p storage/logs \
    && mkdir -p bootstrap/cache \
    && mkdir -p vendor \
    && mkdir -p node_modules \
    && chown -R $user:www-data storage bootstrap/cache vendor node_modules resources public \
    && chmod -R 775 storage bootstrap/cache vendor node_modules

USER $user

EXPOSE 9000

CMD ["sh", "-c", "composer install --no-interaction && npm install && php-fpm"]
