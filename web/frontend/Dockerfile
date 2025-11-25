# Stage 1: React build
FROM node:20 AS build

WORKDIR /app

# Copy dependency files
COPY package*.json ./

RUN npm install

# Copy full source code
COPY . .

RUN npm run build

# Stage 2: Nginx serving
FROM nginx:latest

COPY nginx.conf /etc/nginx/nginx.conf

COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

