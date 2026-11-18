# Entrar com Google e Facebook

O cadastro por e-mail e senha continua disponível. Os provedores sociais aparecem nas telas de entrar/cadastrar e no perfil somente quando o par de credenciais correspondente estiver preenchido no ambiente do servidor. Reinicie o Rails após alterar as variáveis. Em produção, defina também `OAUTH_BASE_URL` com o endereço HTTPS público da loja; o retorno usa esse endereço fixo para não confiar no cabeçalho Host de quem acessa o site.

## Google

1. No [Google Auth Platform](https://console.cloud.google.com/auth/overview), crie ou selecione o projeto da loja e configure nome, público, contatos e URLs da tela de consentimento.
2. Crie um cliente OAuth do tipo aplicativo da Web. Cadastre a URI de redirecionamento exata:
   - Desenvolvimento: `http://localhost:3000/usuarios/auth/google_oauth2/callback`
   - Produção: `https://SEU-DOMINIO/usuarios/auth/google_oauth2/callback`
3. Em ambiente de teste, adicione os usuários de teste autorizados. Conclua as exigências de publicação do Google antes de liberar para todos.
4. Configure `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET` no servidor ou no `.env` local ignorado pelo Git.

## Facebook

1. No [Meta for Developers](https://developers.facebook.com/), crie/configure o aplicativo da loja e o Facebook Login com a opção de login para consumidores apropriada ao seu aplicativo.
2. Cadastre a URI de redirecionamento OAuth válida e exata: `https://SEU-DOMINIO/usuarios/auth/facebook/callback`. Para desenvolvimento, use um ambiente de teste permitido pela Meta; se o painel exigir HTTPS, use um domínio HTTPS de desenvolvimento.
3. Cadastre domínio, política de privacidade e instruções de exclusão de dados. A loja já tem páginas em `/privacidade` e `/atendimento`; revise a política e explique como solicitar exclusão antes de publicar o aplicativo.
4. Configure `FACEBOOK_APP_ID` e `FACEBOOK_APP_SECRET` no servidor.
5. Em modo de desenvolvimento, só os usuários autorizados no aplicativo podem testar. Conclua as verificações e permissões solicitadas pela Meta para liberar o acesso público. A loja solicita apenas nome e e-mail.

```dotenv
OAUTH_BASE_URL=https://SEU-DOMINIO
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
FACEBOOK_APP_ID=
FACEBOOK_APP_SECRET=
```

Nunca envie as credenciais no chat nem faça commit do `.env`. Os parâmetros de autorização são filtrados dos logs. Tokens de acesso dos provedores não são persistidos pela loja.

## Comportamento

- Um novo cadastro social cria sempre um cliente; o provedor não pode conceder permissão administrativa.
- A identidade é identificada pelo par provedor/UID, com índice único no banco.
- Contas existentes com o mesmo e-mail não são vinculadas automaticamente. O cliente entra pelo acesso que já possui, abre Meu perfil e usa Conectar Google/Facebook. Se esqueceu sua senha, usa a recuperação por e-mail. Isso preserva os pedidos e evita vincular contas somente por coincidência de e-mail.
- Um usuário conectado pode associar um Google e um Facebook. Uma identidade já associada a outra conta não pode ser transferida.
- Se o provedor não fornecer e-mail, o cadastro social não é concluído. Ofereça e-mail/senha como alternativa. Um novo cadastro via Google exige e-mail verificado.
- O cliente social completa telefone e endereço no perfil antes de finalizar a compra. Não há telefone inventado.
- As requisições de início do OAuth usam POST com proteção CSRF; os callbacks são validados pelo OmniAuth. Não habilite `provider_ignores_state` nem inicie login por GET.

## Preparar e testar

Execute `bundle install` e `bin/rails db:migrate` (produção: com o ambiente de produção definido). Reinicie o servidor e teste cada provedor com uma conta nova, retorno de usuário, cancelamento e conexão de conta existente. Testes automatizados usam respostas simuladas e não substituem a homologação das credenciais e domínios reais.

Referências: [Google OAuth para aplicações Web](https://developers.google.com/identity/protocols/oauth2/web-server), [estratégia Google](https://github.com/zquestz/omniauth-google-oauth2), [estratégia Facebook](https://github.com/simi/omniauth-facebook), [CSRF no OmniAuth/Rails](https://github.com/cookpad/omniauth-rails_csrf_protection).
