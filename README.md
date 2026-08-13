<div align="center">

# 🤖 Rob Skills

**Coleção de skills customizadas para GitHub Copilot CLI**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Skills](https://img.shields.io/badge/skills-3-orange.svg)](#skills-disponíveis)

</div>

---

## 📖 Sobre

Este repositório contém uma coleção open-source de **skills customizadas** para o [GitHub Copilot CLI](https://docs.github.com/en/copilot). Skills são instruções estruturadas que estendem as capacidades do Copilot para fluxos de trabalho específicos.

## 🚀 Skills Disponíveis

| Skill | Versão | Descrição |
|-------|--------|-----------|
| [vr-analisa-bug](skills/vr-analisa-bug/SKILL.md) | 2.2.0 | Analisa tarefas do Jira, classifica a complexidade do bug, inspeciona o código do repositório e produz uma análise de correção estruturada. |
| [vr-criar-pr](skills/vr-criar-pr/SKILL.md) | 1.2.0 | Cria um pull request a partir do contexto atual, tarefa Jira e fix implementado, usando GitHub MCP ou GitHub CLI. |
| [pendencias-gh](skills/pendencias-gh/SKILL.md) | 1.0.0 | Lista as pendências dos seus PRs no GitHub — conversas de review não resolvidas, conflitos de merge e checks de CI falhando — consultando a API ao vivo via `gh api graphql`. |

## 📦 Instalação

1. Clone o repositório:

```bash
git clone https://github.com/RobsonSilvaVR/rob-skills.git
```

2. Copie as skills desejadas para o diretório de skills do Copilot:

```bash
# Copiar uma skill específica
cp -r rob-skills/skills/vr-analisa-bug ~/.copilot/skills/

# Ou copiar todas
cp -r rob-skills/skills/* ~/.copilot/skills/
```

> As skills seguem o formato `SKILL.md` com front matter, também reconhecido pelo
> Claude Code — nesse caso, copie para `~/.claude/skills/` em vez de `~/.copilot/skills/`.

## 📂 Estrutura do Repositório

```
rob-skills/
├── skills/
│   ├── pendencias-gh/
│   │   ├── SKILL.md
│   │   ├── pending.graphql
│   │   └── scripts/
│   │       └── pendencias.sh
│   ├── vr-analisa-bug/
│   │   └── SKILL.md
│   └── vr-criar-pr/
│       └── SKILL.md
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── new_skill_proposal.md
│   └── PULL_REQUEST_TEMPLATE.md
├── .gitattributes
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## 🤝 Contribuindo

Contribuições são muito bem-vindas! Este é um projeto open-source e aberto para colaboração.

### Como contribuir

1. **Fork** este repositório
2. Crie uma **branch** para sua feature (`git checkout -b minha-skill`)
3. **Commit** suas alterações (`git commit -m 'feat: adiciona skill X'`)
4. **Push** para a branch (`git push origin minha-skill`)
5. Abra um **Pull Request** estruturado

Para mais detalhes, leia o [guia de contribuição](CONTRIBUTING.md).

### Formas de contribuir

- 🐛 **Reportar bugs** — Abra uma [issue de bug](../../issues/new?template=bug_report.md)
- 💡 **Sugerir melhorias** — Abra uma [feature request](../../issues/new?template=feature_request.md)
- 🆕 **Propor nova skill** — Abra uma [proposta de skill](../../issues/new?template=new_skill_proposal.md)
- 🔧 **Enviar correções ou novas skills** — Abra um Pull Request

## 📝 Criando uma Nova Skill

Cada skill deve seguir a estrutura:

```
skills/
└── nome-da-skill/
    └── SKILL.md
```

O arquivo `SKILL.md` deve conter:

1. **Front matter** com `name`, `description` e `version`
2. **Documentação completa** do comportamento esperado
3. **Exemplos de uso** claros
4. **Regras de decisão** bem definidas

Consulte as skills existentes como referência.

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

---

<div align="center">
  <sub>Feito com ❤️ para a comunidade Copilot</sub>
</div>
