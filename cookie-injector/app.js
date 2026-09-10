// Variáveis globais
let currentService = 'Netflix';
let cookies = {};

// Carregar cookies do localStorage ao iniciar
document.addEventListener('DOMContentLoaded', function() {
    loadCookies();
    setupEventListeners();
    checkIfInjectMode();
});

// Setup dos event listeners
function setupEventListeners() {
    // Seleção de serviço
    document.querySelectorAll('.service-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            document.querySelectorAll('.service-btn').forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            currentService = this.dataset.service;
        });
    });

    // Upload de arquivo
    const uploadArea = document.getElementById('uploadArea');
    const fileInput = document.getElementById('fileInput');

    uploadArea.addEventListener('click', () => fileInput.click());

    uploadArea.addEventListener('dragover', (e) => {
        e.preventDefault();
        uploadArea.classList.add('drag-over');
    });

    uploadArea.addEventListener('dragleave', () => {
        uploadArea.classList.remove('drag-over');
    });

    uploadArea.addEventListener('drop', (e) => {
        e.preventDefault();
        uploadArea.classList.remove('drag-over');
        handleFile(e.dataTransfer.files[0]);
    });

    fileInput.addEventListener('change', (e) => {
        handleFile(e.target.files[0]);
    });
}

// Lidar com arquivo
function handleFile(file) {
    if (!file || file.type !== 'text/plain') {
        showMessage('Por favor, selecione um arquivo .txt', 'error');
        return;
    }

    const reader = new FileReader();
    reader.onload = (e) => {
        document.getElementById('cookieInput').value = e.target.result;
    };
    reader.readAsText(file);
}

// Salvar cookies
function saveCookies() {
    const cookieText = document.getElementById('cookieInput').value.trim();
    
    if (!cookieText) {
        showMessage('Cole ou envie um arquivo com cookies', 'error');
        return;
    }

    if (!cookies[currentService]) {
        cookies[currentService] = [];
    }

    cookies[currentService].push({
        id: Date.now(),
        content: cookieText,
        date: new Date().toLocaleString('pt-BR'),
        selected: false
    });

    localStorage.setItem('cookies', JSON.stringify(cookies));
    document.getElementById('cookieInput').value = '';
    showMessage(`✅ Cookies do ${currentService} salvos com sucesso!`, 'success');
    loadCookies();
}

// Carregar cookies
function loadCookies() {
    const stored = localStorage.getItem('cookies');
    cookies = stored ? JSON.parse(stored) : {};
    displayCookies();
}

// Exibir cookies
function displayCookies() {
    const list = document.getElementById('cookiesList');
    const container = document.getElementById('linkContainer');
    
    if (Object.keys(cookies).length === 0) {
        list.innerHTML = '<p style="color: #999; text-align: center;">Nenhum cookie salvo ainda</p>';
        container.style.display = 'none';
        return;
    }

    let html = '';
    for (const [service, cookieArray] of Object.entries(cookies)) {
        for (const cookie of cookieArray) {
            const preview = cookie.content.substring(0, 50) + (cookie.content.length > 50 ? '...' : '');
            html += `
                <div class="cookie-item">
                    <div style="flex: 1;">
                        <div style="display: flex; align-items: center; gap: 10px;">
                            <input type="checkbox" class="cookie-checkbox" data-service="${service}" data-id="${cookie.id}" ${cookie.selected ? 'checked' : ''}>
                            <div>
                                <div class="cookie-name">${service}</div>
                                <div class="cookie-date">${cookie.date}</div>
                                <div style="font-size: 0.85em; color: #666; margin-top: 5px; word-break: break-all;">${preview}</div>
                            </div>
                        </div>
                    </div>
                    <button class="delete-btn" onclick="deleteCookie('${service}', ${cookie.id})">🗑️ Deletar</button>
                </div>
            `;
        }
    }
    
    list.innerHTML = html;
    container.style.display = 'block';

    // Atualizar seleção
    document.querySelectorAll('.cookie-checkbox').forEach(checkbox => {
        checkbox.addEventListener('change', function() {
            const service = this.dataset.service;
            const id = parseInt(this.dataset.id);
            const cookie = cookies[service].find(c => c.id === id);
            if (cookie) cookie.selected = this.checked;
            localStorage.setItem('cookies', JSON.stringify(cookies));
        });
    });
}

// Deletar cookie
function deleteCookie(service, id) {
    if (confirm('Tem certeza que quer deletar este cookie?')) {
        cookies[service] = cookies[service].filter(c => c.id !== id);
        if (cookies[service].length === 0) delete cookies[service];
        localStorage.setItem('cookies', JSON.stringify(cookies));
        loadCookies();
        showMessage('✅ Cookie deletado!', 'success');
    }
}

// Gerar link
function generateLink(mode) {
    const duration = document.getElementById('linkDuration').value;
    let selectedCookies = {};

    if (mode === 'all') {
        selectedCookies = JSON.parse(JSON.stringify(cookies));
    } else {
        for (const [service, cookieArray] of Object.entries(cookies)) {
            const selected = cookieArray.filter(c => c.selected);
            if (selected.length > 0) {
                selectedCookies[service] = selected;
            }
        }
    }

    if (Object.keys(selectedCookies).length === 0) {
        showMessage('Selecione pelo menos um cookie', 'error');
        return;
    }

    const data = {
        cookies: selectedCookies,
        duration: duration,
        created: new Date().toISOString()
    };

    const encoded = btoa(JSON.stringify(data));
    const baseUrl = window.location.origin + window.location.pathname;
    const link = `${baseUrl}?inject=${encoded}`;

    document.getElementById('generatedLink').value = link;
    document.getElementById('linkBox').style.display = 'flex';
    showMessage('✅ Link gerado! Compartilhe com cuidado!', 'success');
}

// Copiar link
function copyLink() {
    const link = document.getElementById('generatedLink');
    link.select();
    document.execCommand('copy');
    showMessage('📋 Link copiado para a área de transferência!', 'success');
}

// Mostrar mensagem
function showMessage(text, type) {
    const msg = document.getElementById('message');
    msg.textContent = text;
    msg.className = `message ${type}`;
    setTimeout(() => msg.className = 'message', 4000);
}

// Modo de injeção
function checkIfInjectMode() {
    const params = new URLSearchParams(window.location.search);
    const inject = params.get('inject');

    if (inject) {
        try {
            const data = JSON.parse(atob(inject));
            injectCookies(data.cookies);
        } catch (e) {
            showMessage('❌ Link inválido ou expirado!', 'error');
        }
    }
}

// Injetar cookies
function injectCookies(cookieData) {
    let injectedCount = 0;

    for (const [service, cookieArray] of Object.entries(cookieData)) {
        for (const cookie of cookieArray) {
            const lines = cookie.content.split('\n');
            for (const line of lines) {
                if (line.trim()) {
                    try {
                        const parts = line.split('=');
                        if (parts.length >= 2) {
                            const name = parts[0].trim();
                            const value = parts.slice(1).join('=').trim();
                            
                            // Remove aspas se houver
                            const cleanValue = value.replace(/^["']|["']$/g, '');
                            
                            document.cookie = `${name}=${cleanValue}; path=/; samesite=lax`;
                            injectedCount++;
                        }
                    } catch (e) {
                        console.error('Erro ao injetar cookie:', e);
                    }
                }
            }
        }
    }

    // Redirecionar para a página limpa
    const cleanUrl = window.location.pathname;
    window.history.replaceState({}, document.title, cleanUrl);

    if (injectedCount > 0) {
        alert(`✅ ${injectedCount} cookies injetados com sucesso!\n\nRecarregue a página para aplicar as mudanças.`);
    } else {
        alert('❌ Nenhum cookie foi injetado. Verifique o formato dos cookies.');
    }
}