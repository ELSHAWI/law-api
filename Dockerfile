# Use official PHP image with Apache
FROM php:8.1-apache

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    libzip-dev zip unzip git curl && \
    docker-php-ext-install pdo pdo_mysql zip

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy composer files first (for caching)
COPY composer.json composer.lock ./

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install PHP dependencies without dev
RUN composer install --no-dev --optimize-autoloader

# Copy rest of the application files
COPY . .

# Copy .env file if exists (or use ENV in Render dashboard)
# If you're using Render's Environment Variables dashboard, no need to copy .env manually.

# Generate Laravel app key (only if .env exists or APP_KEY already set)
RUN php artisan config:clear && php artisan key:generate || echo "Skipping key generate"

# Set permissions for storage and cache
RUN chown -R www-data:www-data storage bootstrap/cache

# Expose port 80
EXPOSE 80

# Start Apache in the foreground
CMD ["apache2-foreground"]
