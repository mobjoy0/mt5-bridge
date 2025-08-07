FROM node:22.12.0

WORKDIR /app

COPY package*.json ./

RUN npm install --production
COPY . .

EXPOSE 8891

CMD ["node", "index.js"]
