# 📦 Projetos do Repositório Tenis

Este repositório contém dois projetos web principais:

## 1. 🍪 Cookie Injector

Um gerenciador de cookies que permite salvar, armazenar e compartilhar cookies via links.

### Características:
- 📤 Upload de arquivos .txt com cookies
- 🎯 Suporte para 8 serviços (Netflix, HBO Max, Disney+, etc)
- 🔗 Geração de links compartilháveis
- 💾 Armazenamento local (localStorage)
- 🔐 Seguro - sem servidor externo

### Como usar:
1. Abra `cookie-injector/index.html`
2. Selecione um serviço
3. Cole ou envie um arquivo com seus cookies
4. Gere um link para compartilhar

**⚠️ AVISO DE SEGURANÇA:** Cookies contêm dados sensíveis. Nunca compartilhe com pessoas não confiáveis!

---

## 2. 🕐 Relógio Digital

Relógio digital em tempo real que exibe a hora em múltiplos fusos horários.

### Características:
- 🌍 Suporte para 30+ cidades e fusos horários
- ⏰ Atualização em tempo real (a cada segundo)
- 🔄 Formato 12h/24h ajustável
- 📅 Exibe data e dia da semana
- 🎨 Design futurista com efeitos neon
- 📱 Responsivo para mobile
- 🔧 Adicione fusos personalizados

### Como usar:
1. Abra `digital-clock/index.html`
2. Selecione uma cidade ou digite um fuso horário
3. Clique em "Adicionar"
4. Os relógios aparecem em tempo real

### Cidades Disponíveis:
- **América:** New York, Los Angeles, Chicago, São Paulo, Buenos Aires
- **Europa:** Londres, Paris, Berlim, Roma, Madri, Amsterdã
- **Ásia:** Tóquio, Seul, Bangkok, Singapura, Dubai, Índia
- **Oceania:** Sydney, Melbourne, Auckland
- **África:** Cairo, Lagos, Johannesburgo

---

## 📁 Estrutura de Diretórios

```
tenis/
├── cookie-injector/
│   ├── index.html       (Interface)
│   └── app.js          (Lógica)
│
├── digital-clock/
│   ├── index.html       (Interface)
│   └── clock.js        (Lógica)
│
└── README.md           (Este arquivo)
```

---

## 🛠️ Tecnologias Utilizadas

### Cookie Injector:
- HTML5
- CSS3 (gradientes, animações)
- JavaScript vanilla (localStorage, FileAPI)

### Relógio Digital:
- HTML5
- CSS3 (gradientes, animações, media queries)
- JavaScript vanilla (Intl API, setInterval)

---

## 📊 Compatibilidade

✅ Chrome/Edge (versão 24+)
✅ Firefox (versão 29+)
✅ Safari (versão 10+)
✅ Opera (versão 15+)
✅ Mobile (iOS Safari, Chrome Android)

---

## 💡 Dicas de Uso

### Cookie Injector:
1. Exporte seus cookies do navegador (F12 > Application > Cookies)
2. Salve em um arquivo .txt
3. Compartilhe o link com cuidado
4. Defina expiração do link

### Relógio Digital:
1. Adicione várias cidades para comparar horários
2. Use em reuniões globais
3. Perfeito para coordenar times distribuídos
4. Digite fusos customizados (UTC+5:30, GMT-8)

---

## ⚖️ Licença

MIT License - Use livremente!

---

## 🎯 Próximas Melhorias

- [ ] Salvar relógios favoritos
- [ ] Alarmes por fuso horário
- [ ] Tema claro/escuro
- [ ] Relógios analógicos
- [ ] Exportar/importar configurações
- [ ] API para integração

---

**Desenvolvido com ❤️ para facilitar o gerenciamento de cookies e acompanhamento de horários globais**