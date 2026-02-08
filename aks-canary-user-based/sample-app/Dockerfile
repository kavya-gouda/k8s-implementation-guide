# Build two images for POC:
#   docker build --build-arg APP_VERSION=1 -t canary-demo:v1 .
#   docker build --build-arg APP_VERSION=2 -t canary-demo:v2 .
FROM node:20-alpine AS base
WORKDIR /app
ARG APP_VERSION=1
ENV APP_VERSION=${APP_VERSION}
ENV NODE_ENV=production
COPY app/package.json app/server.js ./
EXPOSE 8080
USER node
CMD ["node", "server.js"]
