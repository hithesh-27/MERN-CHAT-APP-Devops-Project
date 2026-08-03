FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
COPY frontend/package*.json ./frontend/

RUN npm install --legacy-peer-deps
RUN npm install --prefix frontend --legacy-peer-deps

COPY . .

RUN npm run build

ENV NODE_ENV=production

EXPOSE 5000

CMD ["npm","start"]
