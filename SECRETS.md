# Segredos — como este repositório trata credenciais

## O modelo

Este projeto usa o módulo **Mule Secure Configuration Properties**:

| Onde | O que contém | Versionado? |
|---|---|---|
| `src/main/resources/config-dev.yaml` | hosts, paths, `client_id` (não é segredo) | **sim** |
| `src/main/resources/secure-config-dev.yaml` | **template** com placeholders `CHANGE-ME` | **sim** |
| a chave de criptografia | passada em runtime via `-Dencryption.key` | **nunca** |

A regra que sustenta tudo: **o arquivo cifrado pode ir para o git; a chave não.**
Sem a chave, os valores entre `![ ... ]` são inúteis.

Neste repositorio publico o arquivo vai um passo alem: ele traz apenas
`CHANGE-ME`, sem nenhum ciphertext. Quem reproduz a demo cifra os proprios
segredos e substitui os placeholders — nao ha nada aqui para atacar offline.

## Segredos deste projeto

| Propriedade | O que é |
|---|---|
| `orders.clientSecret` | `client_secret` do contrato `mcp-server-to-orders-api` |
| `stripe.api.key` | Secret key de test mode do Stripe (usada pela tool `refund-payment`) |
| `salesforce.password` | senha do usuário da Developer Edition |
| `salesforce.token` | security token do Salesforce |
| `slack.bot.token` | Bot User OAuth Token (`xoxb-...`) |

Não-segredos que ficam em `config-dev.yaml`: `config.orders.clientId`,
`config.salesforce.username` e `config.slack.channel`.

> ⚠️ `salesforce.password` e `salesforce.token` vão em **campos separados** no connector —
> nunca concatenados. Concatenar gera `INVALID_LOGIN`.

## Como cifrar um valor

```bash
java -jar secure-properties-tool.jar string encrypt AES CBC <CHAVE_16_CHARS> "<valor>"
```

Cole a saída entre os `![ ... ]` no `secure-config-dev.yaml`.

Use `scripts/encrypt-secrets.sh` — ele lê os valores de variáveis de ambiente (nunca por
argumento, que ficaria no histórico do shell), cifra e reescreve o `secure-config-dev.yaml`
deste projeto:

```bash
export ENC_KEY='SuaChaveDe16Char'
export ORDERS_CLIENT_SECRET='...'
export STRIPE_API_KEY='sk_test_...'
export SALESFORCE_PASSWORD='...'
export SALESFORCE_TOKEN='...'
export SLACK_BOT_TOKEN='xoxb-...'
bash scripts/encrypt-secrets.sh --jar /caminho/secure-properties-tool.jar
```

## No deploy

```bash
mvn mule:deploy -DmuleDeploy -DskipTests \
  -Dconnected.app.client.id=<CLIENT_ID> \
  -Dconnected.app.client.secret=<CLIENT_SECRET> \
  -Danypoint.org.id=<ORG_ID> \
  -Ddeploy.target=<space ou região> \
  -Denvironment=Sandbox \
  -Dencryption.key=<CHAVE_16_CHARS>
```

`-Dencryption.key` é o **único** segredo na linha de comando, e o `pom.xml` o registra como
propriedade segura do CloudHub. Em produção, configure-o direto no Runtime Manager em vez de
passar por `-D` em pipeline.

## ⚠️ Rotação — checklist

Os valores cifrados neste repositório foram gerados com uma chave que já circulou fora dele
(arquivos de trabalho locais). Enquanto a rotação não acontecer, trate-os como **conhecidos**.

Quando rotacionar, a ordem importa:

1. **Gere as credenciais novas em cada sistema de origem**: Stripe (roll da secret key),
   Salesforce (reset de senha + *Reset My Security Token*), Slack (rotate do bot token),
   API Manager (reset das credenciais do contrato `mcp-server-to-orders-api`).
2. **Escolha uma chave de criptografia nova** de 16 caracteres — não reutilize a antiga.
3. **Re-cifre todos os valores** com a chave nova (`scripts/encrypt-secrets.sh`) e substitua o
   `secure-config-dev.yaml`.
4. **Redeploye** passando `-Dencryption.key` com a chave nova.
5. **Revogue as credenciais antigas** no sistema de origem — este é o passo que fecha a janela;
   sem ele, os passos anteriores só adicionam credenciais válidas.
6. Confira se a chave antiga não sobrou em algum lugar: `.vscode/launch.json`, notas locais,
   histórico de shell (`~/.bash_history`), variáveis de ambiente de CI.

> Se este repositório for público, faça a rotação **antes** de publicar.
