# Maison Parfum

A Maison Parfum precisava de um sistema robusto para vender decantes online e centralizar a operação da loja. O projeto reúne catálogo, estoque, pedidos e pagamentos em uma única aplicação, permitindo que a equipe acompanhe cada compra da confirmação do pagamento ao envio.

Para quem compra, a loja facilita a descoberta de fragrâncias com busca por nome, marca ou fragrância e um quiz olfativo que recomenda perfumes do catálogo. Os decantes permitem experimentar essas fragrâncias em pequenos volumes antes de investir em um frasco inteiro.

[Visite a loja](https://maison-parfum.onrender.com) · [![Instagram](docs/icons/instagram.png) @maisonparfumoficiall](https://www.instagram.com/maisonparfumoficiall)

## O sistema

- **Cliente** — catálogo com busca, quiz olfativo, carrinho e acompanhamento de pedidos.
- **Administração** — gestão de produtos, estoque, pedidos e regras comerciais.

## Tecnologias

| Área | Tecnologia |
| --- | --- |
| Linguagens e templates | Ruby 3.3.6, JavaScript, HTML, CSS e ERB |
| Framework e interface | Ruby on Rails 8.1, Tailwind CSS, Turbo e Stimulus |
| Banco de dados | PostgreSQL |
| Autenticação | Devise e OmniAuth |
| Tarefas e arquivos | Solid Queue e Active Storage |
| Sistema operacional e publicação | Linux (imagem Ruby Slim no Docker), Render e Ubuntu 24.04 no GitHub Actions |

## APIs e serviços externos

- ![Mercado Pago](docs/icons/mercadopago.png) **Mercado Pago Checkout Pro (Orders API)** — checkout por Pix e cartão, com confirmação via webhook.
- ![Google](docs/icons/google.png) ![Facebook](docs/icons/facebook.png) **Google OAuth 2.0 e Facebook Login** — acesso e vínculo de contas quando o provedor está habilitado.
- ![WhatsApp](docs/icons/whatsapp.png) **WhatsApp Business Cloud API (Meta)** — avisos automáticos de pedidos pagos para a loja.
- **SMTP** — envio de e-mails da loja, incluindo recuperação de senha.

## Desenvolvimento local

Se o PostgreSQL local exigir senha, defina `MAISON_PARFUM_DATABASE_PASSWORD` no `.env`.

```bash
bundle install
bin/rails db:prepare
bin/dev
```

A aplicação roda em `http://localhost:3000`. Execute os testes com `bin/rails test`.

## Configuração

- [Publicação no Render](docs/publicacao.md)
- [Mercado Pago](docs/pagamentos.md)
- [WhatsApp](docs/whatsapp.md)
- [Login social](docs/login-social.md)
