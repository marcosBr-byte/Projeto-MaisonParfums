# Publicação no Render

O Blueprint `render.yaml` configura um serviço Docker com 1 CPU e 2 GB de RAM (`1c-2g`), PostgreSQL Basic na mesma região e um disco persistente de 10 GB em `/rails/storage`. Os recursos são pagos. O Render gera os segredos do Rails e fornece a conexão interna ao serviço. O primeiro boot prepara o banco e os schemas da fila, do cache e do Action Cable. A fila Solid Queue roda dentro do Puma.

Use a URL HTTPS fornecida pelo Render para configurar o Checkout Pro em modo de teste. Para um domínio próprio, vincule-o ao serviço e defina `APP_HOST` com o domínio, sem protocolo.

- No Mercado Pago, configure o evento **Order (Mercado Pago)** com a URL da loja seguida de `/pagamentos/mercado-pago/notificacoes`. Cadastre o token de teste e a assinatura do webhook no painel da loja ou em **Environment** no Render. Siga [a homologação de pagamentos](pagamentos.md).
- No Render, adicione as variáveis da [integração WhatsApp](whatsapp.md). No painel da loja, configure o número de destino e ative os avisos. Confira a entrega de um aviso em um pedido pago elegível.

## Criar o serviço

1. Envie a versão atual da loja e o `render.yaml` para a branch `main` do GitHub. Mantenha `.env`, chaves e senhas fora do commit.
2. No Render, abra **New → Blueprint**. Conecte o repositório `marcosBr-byte/Projeto-MaisonParfums` e selecione a branch `main` e o caminho `render.yaml`.
3. Revise os serviços e os custos antes de clicar em **Deploy Blueprint**.
4. Abra o serviço `maison-parfum`. Quando estiver **Live**, confira a página inicial e `/up` na URL `.onrender.com`.

O primeiro deploy cria um banco novo. O Rails prepara as tabelas e os seeds de produção deixam produtos, clientes, pedidos e mídias cadastradas vazios. O banco local permanece intacto.

## Criar o primeiro administrador

No serviço `maison-parfum`, abra **Shell** e cole o bloco abaixo. Digite a senha no prompt oculto.

```sh
bin/rails runner - <<'RUBY'
require "io/console"

terminal = IO.console || abort("Abra o Shell interativo do Render.")
terminal.print "Nome do administrador: "
nome = terminal.gets&.strip
terminal.print "E-mail do administrador: "
email = terminal.gets&.strip
senha = terminal.getpass("Senha do administrador: ")
abort("Informe uma senha.") if senha.blank?

Usuario.create!(nome: nome, email: email, password: senha, role: :admin)
puts "Administrador criado."
RUBY
```

Entre com esse acesso e cadastre o catálogo pelo painel.

## Alterar o e-mail do administrador

Entre no painel e abra **Perfil → Editar perfil**. Atualize **E-mail de acesso**, confirme com a senha atual e salve. Use o novo endereço no próximo login. A conta mantém a função de administrador.

Se o cliente esqueceu a senha e ainda recebe mensagens no endereço atual, use **Esqueci minha senha**. Em produção, configure primeiro o [envio de e-mails por SMTP](email.md) e teste a entrega.

Se o cliente perdeu acesso à caixa de entrada, confirme a identidade dele antes de executar este bloco no **Shell** do Render. Ele busca a conta pelo endereço atual e pela função de administrador. Um e-mail já vinculado a outra conta é recusado pela validação da loja. Use o novo endereço para recuperar a senha pelo fluxo de e-mail, se necessário.

```sh
bin/rails runner - <<'RUBY'
require "io/console"

terminal = IO.console || abort("Abra o Shell interativo do Render.")
terminal.print "E-mail atual do administrador: "
email_atual = terminal.gets&.strip&.downcase
terminal.print "E-mail novo do administrador: "
email_novo = terminal.gets&.strip
admin = Usuario.find_by(email: email_atual, role: :admin)
abort("Administrador não encontrado.") unless admin

admin.update!(email: email_novo, reset_password_token: nil, reset_password_sent_at: nil)
puts "E-mail do administrador atualizado."
RUBY
```
