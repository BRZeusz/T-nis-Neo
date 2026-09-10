# 🔗 FREE DROP - Professional Cookie Injection Platform

## 📖 Visão Geral

Free Drop é uma plataforma profissional e totalmente funcional para gerenciamento e compartilhamento de cookies com segurança. Interface escura e elegante, projetada para máxima usabilidade.

## ✨ Características Principais

### 🎯 Funcionalidades
- **📥 Upload de Cookies**: Envie arquivos .txt ou cole direto
- **💾 Armazenamento Local**: localStorage seguro (seus dados ficam no seu PC)
- **🔗 Geração de Links**: Crie links únicos e compartilháveis
- **📱 Multi-Dispositivo**: Escolha entre PC, Mobile ou TV
- **⏰ Duração Personalizável**: 1h, 6h, 24h, 7 dias ou infinito
- **🔒 Seguro**: Codificação em Base64, sem servidor externo
- **💻 Interface Profissional**: Dark mode com design moderno
- **🌍 15+ Serviços**: Netflix, HBO, Disney+, Prime Video, YouTube, etc

## 🚀 Como Testar Localmente

### Opção 1: Duplo Clique
```bash
Duplo clique em free-drop/index.html
```

### Opção 2: Python
```bash
python -m http.server 8000
# Acesse: http://localhost:8000/free-drop/
```

### Opção 3: Node.js
```bash
npm install -g http-server
http-server
# Acesse: http://localhost:8080/free-drop/
```

### Opção 4: VSCode Live Server
```
Clique direito em index.html > Open with Live Server
```

## 📝 Como Usar

### 1. Adicionar Cookies

**Via Arquivo:**
1. Clique em "Upload Cookies"
2. Selecione um serviço (Netflix, HBO Max, etc)
3. Clique na área de upload ou arraste um .txt
4. Clique em "Salvar Cookies"

**Via Cola Manual:**
1. Selecione o serviço
2. Cole os cookies no textarea
3. Formato esperado:
```
name=value
name2=value2
```
4. Clique em "Salvar Cookies"

### 2. Gerar Link

1. Vá para "Gerar Link"
2. Selecione o dispositivo (PC, Mobile, TV)
3. Escolha a duração
4. Clique em "Gerar Link"
5. Copie o link

### 3. Compartilhar

- Envie o link
- Quem clica recebe os cookies injetados
- Funciona automaticamente!

## 🔒 Segurança

✅ Cookies armazenados LOCALMENTE
✅ Nenhum dado enviado para servidores
✅ Codificação Base64
✅ Expira automática
✅ Sem rastreamento

⚠️ **Avisos:**
- Nunca compartilhe com estranhos
- Cookies = acesso completo à conta
- Use com contas suas ou autorizadas

## 📂 Estrutura

```
free-drop/
├── index.html      # Interface principal
├── app.js         # Lógica
└── README.md      # Documentação
```

## 🎨 Design

- Tema preto (#0a0e27)
- Azul neon (#00d4ff)
- Interface responsiva
- Animações suaves

## 💻 Compatibilidade

✅ Chrome 90+
✅ Firefox 88+
✅ Safari 14+
✅ Edge 90+
✅ Mobile browsers

---

**FREE DROP © 2024**