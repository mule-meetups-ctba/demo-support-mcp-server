# demo-support-mcp-server

**MCP server** com as quatro tools de suporte da TechWave Electronics (demo do MuleSoft Meetup).
Expõe capacidades de negócio para um LLM descobrir e invocar — não é um wrapper de endpoints.

- **Protocolo:** MCP via Streamable HTTP em `/mcp` (MCP Connector 1.5)
- **Consumido por:** [`demo-support-agent`](../demo-support-agent) e pelo broker da rede
- **Runtime:** Mule 4.12 · Java 17 · CloudHub 2.0

> Parte de uma demo com 4 repositórios. Arquitetura, walkthrough completo, políticas de gateway
> e roteiro de apresentação: **`meetup-omni-material`**.

## As quatro tools

| Tool | Tipo | Reversível | Sistema | Controle principal |
|---|---|---|---|---|
| `get-order-status` | leitura | n/a | Order Support API | `pattern` no JSON Schema |
| `create-support-case` | escrita | sim | Salesforce | `enum` + limites de tamanho |
| `refund-payment` | escrita | **não** | Stripe (test mode) | exige `paymentIntentId`, não `orderId` |
| `notify-team` | efeito colateral | não | Slack | canal fica em config, fora do alcance do LLM |

Três decisões de desenho que o código mostra melhor que qualquer texto:

- **`refund-payment` não aceita `orderId`.** Exige o `paymentIntentId`, o que **força** o agente a
  consultar o pedido antes. É um encadeamento de dependência codificado no formato dos parâmetros —
  vale mais que instrução em prompt, porque prompt é sugestão e schema é obrigação.
- **O canal do Slack não é parâmetro da tool.** Vem de `config.slack.channel`. Se fosse parâmetro,
  um prompt injection poderia redirecionar notificações. Regra geral: o que o LLM não precisa
  escolher, ele não deve poder escolher.
- **`<mcp:on-error-responses>` devolve frase, não stack trace.** O LLM consegue reagir a
  "Erro ao consultar pedido: timeout"; não consegue reagir a um `HTTP:CONNECTIVITY` cru.

## Configuração

`src/main/resources/config-dev.yaml`:

| Propriedade | O que é |
|---|---|
| `config.orders.host` / `.basePath` | Order Support API **via ingress gateway** (só o host, sem `https://`) |
| `config.orders.clientId` | `client_id` do contrato `mcp-server-to-orders-api` |
| `config.stripe.host` / `.basePath` | API do Stripe |
| `config.salesforce.username` | usuário da Developer Edition |
| `config.slack.host` / `.channel` | workspace e canal de destino |

Segredos (cifrados em `secure-config-dev.yaml`): `orders.clientSecret`, `stripe.api.key`,
`salesforce.password`, `salesforce.token`, `slack.bot.token`. Ver [SECRETS.md](SECRETS.md).

> O MCP server é, ele próprio, um **consumidor governado** da Order Support API: entra pelo
> ingress apresentando credenciais, como qualquer consumidor externo. Não há atalho interno.

## Build e deploy

```bash
mvn clean test                      # testes
mvn clean deploy -DskipTests        # 1) publica no Exchange
mvn mule:deploy -DmuleDeploy -DskipTests \
  -Dconnected.app.client.id=<CLIENT_ID> \
  -Dconnected.app.client.secret=<CLIENT_SECRET> \
  -Danypoint.org.id=<ORG_ID> \
  -Ddeploy.target=<space ou região> \
  -Denvironment=Sandbox \
  -Dencryption.key=<CHAVE_16_CHARS>
```

## Testando

`tools/mcp-inspector/` traz um launcher do **MCP Inspector** com os endpoints da demo
já mapeados (direto, ingress, egress e a rota gerada pela Agent Network):

```powershell
.\tools\mcp-inspector\launch-mcp-inspector.ps1 -Endpoint ingress
```

Ou direto por HTTP:

```bash
curl -X POST https://<ingress-gw>/techwave-support-mcp-server/mcp \
  -H "Content-Type: application/json" -H "Accept: application/json, text/event-stream" \
  -H "client_id: ..." -H "client_secret: ..." \
  -d '{"jsonrpc":"2.0","id":"1","method":"tools/list"}' | jq
```

> Governança: a política **MCP Global Access** no gateway faz allow-list das 4 tools. Uma quinta
> tool adicionada aqui **não fica exposta** até alguém atualizar a política — controle de mudança
> aplicado à superfície de ação de um agente.
