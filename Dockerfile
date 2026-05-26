FROM node:18 AS build

WORKDIR /usr/src/app

RUN corepack enable

# Copia as configurações essenciais do Yarn
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

# Instala todas as dependências (incluindo devDependencies para o build)
RUN yarn install --immutable

# Copia o código fonte e gera o build
COPY . .
RUN yarn run build

# Remove APENAS as devDependencies, mas MANTÉM os zips de produção e cache necessários
RUN yarn workspaces focus --production

# --- Estágio Final de Produção ---
FROM node:18-alpine3.19

WORKDIR /usr/src/app

RUN corepack enable

# 1. Copia o build do NestJS
COPY --from=build /usr/src/app/dist ./dist

# 2. Copia os manifestos e arquivos de mapa do Yarn PnP
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/yarn.lock ./yarn.lock
COPY --from=build /usr/src/app/.yarnrc.yml ./.yarnrc.yml
COPY --from=build /usr/src/app/.pnp.cjs ./.pnp.cjs

# 3. Copia a pasta .yarn inteira (que agora contém os zips de produção e o release do Yarn)
COPY --from=build /usr/src/app/.yarn ./.yarn

EXPOSE 3000

CMD ["yarn", "run", "start:prod"]