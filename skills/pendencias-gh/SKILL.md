---
name: pendencias-gh
description: Lista as pendências de PRs do usuário no GitHub — conversas de review não resolvidas, conflitos de merge e checks de CI falhando —, a mesma pesquisa da aba Pendências do DevInbox, consultada ao vivo via gh api graphql. Use quando o usuário pedir "minhas pendências", "o que falta nos meus PRs", "tem conflito em algum PR meu", "quais checks estão falhando", "o que preciso resolver hoje" ou "/pendencias-gh".
---

# Pendências GH

Mostra tudo que exige ação do usuário nos PRs de sua autoria no GitHub, agrupado em três categorias. É a réplica stateless da aba **Pendências** do DevInbox: mesmas regras, mas consultando o GitHub ao vivo, sem depender do app estar rodando.

## Quando usar

- "/pendencias-gh" — relatório completo
- "quais são minhas pendências?", "o que falta nos meus PRs?"
- "tem conflito em algum PR meu?", "quais checks estão falhando?"
- "tem comentário de review que eu não resolvi?"

## Argumentos

Tudo opcional; combinam entre si.

| Argumento | Efeito |
|---|---|
| *(nenhum)* | Todas as pendências |
| `VRPdv`, `Concentrador` | Filtra por repositório — substring, case-insensitive, comparada com `repo` |
| `conversas` / `conflitos` / `checks` | Filtra por tipo |

Exemplos: `/pendencias-gh`, `/pendencias-gh VRPdv`, `/pendencias-gh conflitos`, `/pendencias-gh VRAutorizador conflitos`.

## Como executar

Rode o script e renderize a saída. **Nunca reconstrua a query na mão** — a fidelidade às regras do DevInbox depende dela.

```bash
bash <caminho-da-skill>/scripts/pendencias.sh
```

O script exige `gh` autenticado e não precisa de `jq` instalado (usa o `--jq` embutido do `gh`). Custo típico: ~23 pontos de rate limit GraphQL, de 5000/hora.

Ele imprime JSON em stdout:

```json
{
  "login": "...", "total": 62, "varridos": 62, "temMais": false,
  "custo": 23, "restante": 4564,
  "itens": [{ "tipo": "Conversa", "repo": "org/repo", "pr": 639,
              "titulo": "...", "detalhe": "...", "url": "...", "autor": "...",
              "isDraft": false, "baseRefName": "main",
              "updatedAt": "2026-08-13T19:49:20Z" }]
}
```

Os itens já vêm agrupados na ordem Conversa → Conflito → Checks e, dentro de cada grupo, ordenados por repositório (A→Z) e número de PR (desc). **Preserve essa ordem** — é a mesma da aba.

### Campos do PR nos itens

`isDraft`, `baseRefName` e `updatedAt` são propriedades do **pull request**, não da pendência: quando um PR aparece em vários itens (uma conversa e um conflito, por exemplo), os três se repetem iguais em cada item. Eles existem para quem consome o JSON de forma programática não precisar de uma segunda consulta por PR.

**A varredura inclui PRs em rascunho** — a query é `is:pr is:open author:@me archived:false`, sem filtro de draft, para espelhar a aba do DevInbox. Quem consome decide o que fazer: no relatório para o usuário, os rascunhos aparecem normalmente; um consumidor que só queira PRs prontos deve descartar `isDraft: true` por conta própria.

### Tratamento de erros

- **Exit code ≠ 0:** reporte a mensagem de erro ao usuário. Nunca interprete falha como "nenhuma pendência".
- **`temMais: true`:** o usuário passou de 100 PRs abertos e a varredura foi truncada. Avise explicitamente no rodapé; não omita em silêncio.

## Formato de saída

Cabeçalho com a contagem total (igual ao rótulo da aba), seções por tipo, uma linha por item:

```markdown
## Pendências (19)

### Conversa (8)
- **vrsoftbr/VRConcentrador#639** — PPV-386 - Isolamento transacional da importação
  [🟢 Baixo — B1] Log referencia a classe errada. O catch agora vive em… — @github-actions
  https://github.com/vrsoftbr/VRConcentrador/pull/639#discussion_r3777851321

### Conflito (9)
- **vrsoftbr/VRAutorizador#400** — PPV-512 - Ajuste no fluxo de autorização
  Conflito com a base
  https://github.com/vrsoftbr/VRAutorizador/pull/400

### Checks (2)
- **vrsoftbr/VRConcentrador#639** — PPV-386 - Isolamento transacional da importação
  CI/checks falhando: checkcode, Claude Review / Claude CI Review
  https://github.com/vrsoftbr/VRConcentrador/pull/639/checks

_62 PRs varridos · rate limit: 4564 restantes_
```

Regras:
- Omita seções vazias, mas mantenha a contagem do cabeçalho refletindo o que foi exibido (após filtros).
- `detalhe` nulo → escreva `(sem detalhe)`.
- Sempre inclua a URL: é o que torna o item acionável.
- Ao aplicar filtro, diga qual foi aplicado: `## Pendências em VRPdv (4)`.
- **Nenhum item:** responda explicitamente "Nenhuma pendência" (com o filtro, se houver). Não invente itens nem omita a resposta.

## As três regras

Espelham `PrStateRepository.GetPendingItems()` do DevInbox. Todas restritas a **PRs abertos de autoria do usuário** (`is:pr is:open author:@me archived:false`).

| Tipo | Regra | Detalhe / URL |
|---|---|---|
| **Conversa** | Review thread com `isResolved = false` | Preview do primeiro comentário (140 chars) · autor · URL do comentário |
| **Conflito** | `mergeable == "CONFLICTING"` | `"Conflito com a base"` · URL do PR |
| **Checks** | `statusCheckRollup.state` ∈ `{FAILURE, ERROR}` | Nomes dos checks que falharam · URL do PR + `/checks` |

`mergeable == "UNKNOWN"` (GitHub recalculando) **não** conta como conflito — igual ao SQL da aba, que exige `CONFLICTING` estrito.

## Diferenças em relação à aba do DevInbox

Se a contagem divergir da aba, é por um destes três motivos — todos deliberados:

1. **Cobertura maior.** O app consulta `first: 25`; esta skill usa `first: 100`. Com 62 PRs abertos, a aba enxerga só os 25 mais recentes e chega a esconder metade dos conflitos.
2. **Preview mais preciso.** O app lê `comments(last: 5)` do thread e mostra o primeiro desses; a skill lê `comments(first: 50)` e mostra o primeiro comentário real do thread.
3. **Sem estado.** A skill sempre reflete o GitHub agora; a aba reflete o último poll do app. Itens resolvidos há segundos já somem daqui e ainda aparecem lá (e vice-versa).

## Fora de escopo

Réplica fiel das três categorias da aba — deliberadamente **não** inclui reviews solicitadas ao usuário, PRs aprovados prontos para merge, nem menções. Se o usuário pedir algum desses, atenda com uma consulta `gh` à parte e deixe claro que está fora do relatório padrão.
