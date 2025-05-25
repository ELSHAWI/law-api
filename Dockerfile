# Use official PHP image with Apache
FROM php:8.1-apache

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    libpq-dev \
    libpng-dev \
    libonig-dev \
    libxml2-dev && \
    docker-php-ext-install pdo pdo_pgsql zip mbstring exif pcntl bcmath gd

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy composer files first (for caching)
COPY composer.json composer.lock ./

# Install PHP dependencies without dev (with retry for network issues)
RUN composer install --no-dev --optimize-autoloader --no-interaction || \
    (sleep 5 && composer install --no-dev --optimize-autoloader --no-interaction) || \
    (sleep 10 && composer install --no-dev --optimize-autoloader --no-interaction)

# Copy rest of the application files
COPY . .

# Set permissions for storage and cache
RUN chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

# Generate application key if not set (safer approach)
RUN if [ ! -f ".env" ]; then \
        cp .env.example .env && \
        php artisan key:generate; \
    fi

# Clear config cache
RUN php artisan config:clear

# Expose port 80
EXPOSE 80

# Start Apache in the foreground
CMD ["apache2-foreground"]
