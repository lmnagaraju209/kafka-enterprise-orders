FROM node:20 AS build
WORKDIR /app

# Copy only the React subfolder
COPY web-frontend/package*.json ./
RUN npm install

COPY web-frontend/ ./
RUN npm run build

FROM nginx:latest
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/build /usr/share/nginx/html

