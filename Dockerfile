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

# Fix ownership of the working directory upfront
RUN chown www-data:www-data /var/www/rms

# Copy composer files first (cache-friendly)
COPY --chown=www-data:www-data composer.json composer.lock ./

# Switch to www-data for composer install to ensure correct permissions
USER www-data

# Install PHP deps at build time (composer install)
ARG APP_ENV=prod
RUN if [ "$APP_ENV" = "prod" ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction --no-progress; \
    else \
        composer install --no-interaction --no-progress; \
    fi

# Copy source code (with correct ownership)
COPY --chown=www-data:www-data . .

# Ensure writable directory is truly writable
RUN chmod -R 775 writable

# Expose port (if needed by some setups, though FPM usually via socket/9000)
EXPOSE 9000

CMD ["php-fpm"]