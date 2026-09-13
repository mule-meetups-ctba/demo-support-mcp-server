# MCP Inspector - TechWave Demo

Este diretório tem atalhos para testar o **TechWave Support MCP Server** com o MCP Inspector.

## Como abrir

No PowerShell, a partir da raiz do repositório:

```powershell
.\mcp-inspector\launch-mcp-inspector.ps1
```

Para escolher um endpoint específico:

```powershell
.\mcp-inspector\launch-mcp-inspector.ps1 -Endpoint direct
.\mcp-inspector\launch-mcp-inspector.ps1 -Endpoint ingress
.\mcp-inspector\launch-mcp-inspector.ps1 -Endpoint egress
.\mcp-inspector\launch-mcp-inspector.ps1 -Endpoint agentNetworkEgress
```

O script abre o Inspector com:

```powershell
npx @modelcontextprotocol/inspector
```

Depois, no UI do Inspector:

1. Selecione o transporte **Streamable HTTP**.
2. Cole a URL indicada pelo script.
3. Clique em **Connect**.
4. Use **List Tools** e depois teste `get-order-status`, `create-support-case`, `refund-payment` ou `notify-team`.

## Endpoints

| Nome | URL | Quando usar |
|---|---|---|
| `direct` | `https://<app-demo-support-mcp-server-host>.cloudhub.io/mcp` | Teste direto do app MCP, sem gateway. Melhor primeiro smoke test. |
| `ingress` | `https://<meetup-ingress-gw-host>.cloudhub.io/techwave-support-mcp-server/mcp` | Teste do MCP via public ingress Omni Gateway. |
| `egress` | `https://<meetup-egress-gw-host>.cloudhub.io/techwave-support-mcp-server/mcp` | Só deve funcionar de dentro da rede/Private Space. |
| `agentNetworkEgress` | `https://<meetup-egress-gw-host>.cloudhub.io/a75e4983-9a43-49c7-bfaa-b2e8d2b70a95/mcpServer/mcpServerConnection` | Rota gerada pela Agent Network connection. Normalmente só o broker chama. |

## Headers opcionais

Se o endpoint via ingress estiver protegido por Client ID Enforcement, configure no Inspector:

```text
client_id: <client id>
client_secret: <client secret>
```

Não salve esses valores no repositório.

## Chamadas úteis

### get-order-status

```json
{
  "orderId": "TW-1001"
}
```

### create-support-case

```json
{
  "orderId": "TW-1001",
  "subject": "Teste via MCP Inspector",
  "description": "Validando a tool create-support-case durante a demo.",
  "priority": "Medium"
}
```

### refund-payment

Use com cuidado: mesmo em Stripe test mode, a operação pode alterar o estado do PaymentIntent de teste.

```json
{
  "paymentIntentId": "pi_REPLACE_WITH_TEST_PAYMENT_INTENT",
  "reason": "requested_by_customer"
}
```

### notify-team

```json
{
  "message": "Teste via MCP Inspector para validar a tool notify-team."
}
```

## Observações

- Para o MCP server direto, use a URL terminando em `/mcp`.
- Para a Agent Network, a variável `mcpServer.url` pode ficar sem `/mcp` se o gateway/connection já estiver compondo esse path. No Inspector direto, porém, o endpoint Streamable HTTP do app é `/mcp`.
- Se o Inspector mostrar falha de conexão no endpoint `egress`, teste primeiro `direct`: o hostname `internal-*` não costuma resolver fora do Private Space.
