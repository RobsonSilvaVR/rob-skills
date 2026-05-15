# 🤝 Guia de Contribuição

Obrigado por querer contribuir com o **Rob Skills**! Este guia vai te ajudar a entender como participar do projeto.

## 📋 Sumário

- [Código de Conduta](#código-de-conduta)
- [Como Contribuir](#como-contribuir)
- [Reportando Bugs](#reportando-bugs)
- [Sugerindo Melhorias](#sugerindo-melhorias)
- [Propondo Novas Skills](#propondo-novas-skills)
- [Enviando Pull Requests](#enviando-pull-requests)
- [Padrões do Projeto](#padrões-do-projeto)

## 📜 Código de Conduta

Este projeto segue um código de conduta simples: seja respeitoso, construtivo e colaborativo. Tratamos todos os colaboradores com respeito, independentemente de experiência ou background.

## 🚀 Como Contribuir

### Reportando Bugs

Se você encontrou um bug em uma skill existente:

1. Verifique se já não existe uma [issue aberta](../../issues) para o mesmo problema
2. Abra uma nova issue usando o template **Bug Report**
3. Inclua:
   - Qual skill está com problema
   - Passos para reproduzir
   - Comportamento esperado vs. comportamento atual
   - Versão da skill

### Sugerindo Melhorias

Para sugerir melhorias em skills existentes:

1. Abra uma issue usando o template **Feature Request**
2. Descreva claramente a melhoria proposta
3. Explique o caso de uso e o benefício esperado

### Propondo Novas Skills

Para propor uma nova skill:

1. Abra uma issue usando o template **New Skill Proposal**
2. Descreva o objetivo da skill
3. Liste os casos de uso principais
4. Descreva as dependências necessárias (MCPs, CLIs, etc.)

## 🔧 Enviando Pull Requests

### Passo a passo

1. **Fork** o repositório
2. **Clone** seu fork:
   ```bash
   git clone https://github.com/SEU_USUARIO/rob-skills.git
   ```
3. Crie uma **branch** descritiva:
   ```bash
   git checkout -b feat/nova-skill-nome
   # ou
   git checkout -b fix/correcao-bug-analyzer
   ```
4. Faça suas alterações seguindo os [padrões do projeto](#padrões-do-projeto)
5. **Commit** com mensagens claras:
   ```bash
   git commit -m "feat: adiciona skill de análise de código"
   # ou
   git commit -m "fix: corrige classificação de complexidade no bug-analyzer"
   ```
6. **Push** para seu fork:
   ```bash
   git push origin feat/nova-skill-nome
   ```
7. Abra um **Pull Request** para a branch `main` deste repositório
8. Preencha o template do PR completamente

### Convenção de commits

Utilize [Conventional Commits](https://www.conventionalcommits.org/):

| Prefixo | Uso |
|---------|-----|
| `feat:` | Nova skill ou funcionalidade |
| `fix:` | Correção de bug em skill existente |
| `docs:` | Alterações em documentação |
| `refactor:` | Reestruturação sem mudança de comportamento |
| `chore:` | Tarefas de manutenção |

### Convenção de branches

| Prefixo | Uso |
|---------|-----|
| `feat/` | Nova skill ou funcionalidade |
| `fix/` | Correção de bug |
| `docs/` | Alterações em documentação |

## 📐 Padrões do Projeto

### Estrutura de uma Skill

Cada skill deve estar em seu próprio diretório dentro de `skills/`:

```
skills/
└── nome-da-skill/
    └── SKILL.md
```

### Formato do SKILL.md

O arquivo `SKILL.md` deve conter:

1. **Front matter YAML** com os campos obrigatórios:
   ```yaml
   ---
   name: nome-da-skill
   description: Descrição concisa do que a skill faz.
   version: 1.0.0
   ---
   ```

2. **Título** — nome legível da skill
3. **Descrição** — explicação do propósito
4. **Quando usar** — cenários de uso
5. **Pré-condições** — requisitos obrigatórios
6. **Objetivo principal** — o que a skill faz
7. **Formato de entrada** — como invocar
8. **Workflow** — passos detalhados de execução
9. **Formato de saída** — estrutura da resposta
10. **Regras de decisão** — condições de parada e qualidade
11. **Exemplos** — cenários de uso com comportamento esperado

### Versionamento

Utilize [Semantic Versioning](https://semver.org/):

- **MAJOR** — mudanças incompatíveis no comportamento
- **MINOR** — novas funcionalidades retrocompatíveis
- **PATCH** — correções de bugs retrocompatíveis

### Linguagem

- Skills podem ser escritas em **português** ou **inglês**
- Mantenha consistência dentro de uma mesma skill
- Documentação do repositório (README, CONTRIBUTING) está em português

## ❓ Dúvidas?

Abra uma [issue](../../issues) com sua dúvida e teremos prazer em ajudar!
