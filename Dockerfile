# Use Debian/Ubuntu PHP image
FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libzip-dev \
    unzip \
    zip \
    git \
    curl \
    && docker-php-ext-install mysqli pdo pdo_mysql intl zip \
    && docker-php-ext-enable mysqli pdo_mysql intl zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer from official image
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# Set working dir
WORKDIR /var/www/rms

# Copy composer files first (cache-friendly)
COPY composer.json composer.lock ./

# Install PHP deps at build time (composer install)
ARG APP_ENV=prod
RUN if [ "$APP_ENV" = "prod" ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction --no-progress; \
    else \
        composer install --no-interaction --no-progress; \
    fi

# Copy source code
COPY . .

# Fix permissions (CodeIgniter writable dirs)
RUN chown -R www-data:www-data writable && chmod -R 775 writable

# Use www-data user
USER www-data