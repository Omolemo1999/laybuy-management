FROM node:22-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev --no-audit --no-fund
COPY . .
RUN addgroup -S app && adduser -S app -G app && chown -R app:app /app
USER app
EXPOSE 4000
CMD ["sh","-c","node src/migrate.js && node src/server.js"]
