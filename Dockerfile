FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
# LibreOffice converts Word files with equations to PDF for AI extraction.
# Build with --build-arg WITH_LIBREOFFICE=false for a smaller API-only image.
ARG WITH_LIBREOFFICE=true
RUN if [ "$WITH_LIBREOFFICE" = "true" ]; then \
      apk add --no-cache libreoffice-writer libreoffice-math font-dejavu font-noto-arabic; \
    fi
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/dist ./dist
COPY public ./public
EXPOSE 3000
CMD ["node", "dist/main.js"]
