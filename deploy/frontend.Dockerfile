# Production image for AdMento-frontend on the VPS.
# Build context: AdMento-frontend/   (see deploy/docker-compose.yml)
FROM node:24.18.0 AS build
WORKDIR /app

COPY package*.json ./
# --ignore-scripts skips husky's git hook install (no .git in the build context)
RUN npm ci --ignore-scripts --no-audit --no-fund

COPY . .

# Copy the committed template; VITE_* build args below override what matters.
RUN cp .env_base .env
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}

RUN npm run generate-types
RUN NODE_OPTIONS="--max-old-space-size=4096" npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
# "deploy" is an extra build context (the repo's deploy/ folder), set in docker-compose.yml
COPY --from=deploy frontend-nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
