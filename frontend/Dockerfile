FROM node:18
WORKDIR /app
COPY . .
RUN npm install
COPY . .
EXPOSE 5173
CMD ["npm", "run", "dev"]
