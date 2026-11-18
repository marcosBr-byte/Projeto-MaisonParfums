# E-mail da loja para recuperação de senha

O sistema usa somente as variáveis `SMTP_*` da loja. As antigas variáveis `GMAIL_USER` e `GMAIL_APP_PASSWORD` não são utilizadas, evitando o uso acidental da conta pessoal do desenvolvedor.

Configure no `.env` local ou nos segredos da hospedagem:

```dotenv
SMTP_ADDRESS=servidor_smtp_do_provedor
SMTP_PORT=587
SMTP_USERNAME=email_da_loja
SMTP_PASSWORD=credencial_smtp_da_loja
SMTP_FROM=email_da_loja
```

O servidor e a porta devem corresponder ao serviço contratado. A configuração atual usa SMTP com STARTTLS na porta 587. Se o provedor exigir outro modo de conexão, ajuste o transporte antes de testar. O endereço remetente precisa ser autorizado pelo provedor; trocar só o remetente sem autenticar a conta da loja pode causar rejeição ou substituição pelo endereço pessoal.

Se o e-mail da loja for Gmail, configure `SMTP_ADDRESS=smtp.gmail.com` e use uma senha de app dessa conta em `SMTP_PASSWORD`, com a verificação em duas etapas ativada: https://support.google.com/accounts/answer/185833?hl=pt-BR.

Não compartilhe senhas no chat e não envie o `.env` ao Git. Reinicie `bin/dev` depois de alterar as variáveis. Sem conta SMTP configurada, o desenvolvimento usa o visualizador local Letter Opener: isso não entrega e-mails pela internet.

Em produção, configure também `APP_HOST` com o domínio público sem protocolo. Teste uma recuperação pelo formulário com uma caixa de e-mail controlada pelo responsável da loja.

O erro `535 Username and Password not accepted` indica que o provedor recusou a autenticação. Falhas SMTP tratadas não causam erro 500; a resposta pública é genérica para não revelar se a conta existe. A entrega real depende de credenciais válidas.
