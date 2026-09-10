// Variáveis globais
let cookies = {};
let selectedService = 'Netflix';
let selectedDevice = 'pc';

const services = [
    'Netflix', 'HBO Max', 'Disney+', 'Prime Video',
    'YouTube', 'Twitter', 'Instagram', 'Facebook',
    'TikTok', 'Twitch', 'Spotify', 'Amazon',
    'Apple TV', 'Crunchyroll', 'Hulu'
];

// Inicializar
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
});

function initializeApp() {
    loadCookies();
    renderServices();
    checkInjectMode();

    // Upload de arquivo
    const uploadArea = document.getElementById('uploadArea');
    const fileInput = document.getElementById('fileInput');

    uploadArea.addEventListener('click', () => fileInput.click());
    uploadArea.addEventListener('dragover', (e) => {
        e.preventDefault();
        uploadArea.style.background = 'rgba(0, 212, 255, 0.2)';
    });
    uploadArea.addEventListener('dragleave', () => {
        uploadArea.style.background = 'rgba(0, 212, 255, 0.05)';
    });
    uploadArea.addEventListener('drop', (e) => {
        e.preventDefault();
        uploadArea.style.background = 'rgba(0, 212, 255, 0.05)';
        handleFile(e.dataTransfer.files[0]);
    });

    fileInput.addEventListener('change', (e) => {
        handleFile(e.target.files[0]);
    });
}

// Renderizar serviços
function renderServices() {
    const grid = document.getElementById('servicesGrid');
    grid.innerHTML = services.map(service => `
        <button class="service-btn ${service === selectedService ? 'active' : ''}" 
                onclick="selectService('${service}')"> ${service}</button>
    `).join('');
}

// Selecionar serviço
function selectService(service) {
    selectedService = service;
    renderServices();
    showMessage(`${service} selecionado`, 'success');
}

// Selecionar dispositivo
function selectDevice(device) {
    selectedDevice = device;
    document.querySelectorAll('.device-opt').forEach(el => el.classList.remove('selected'));
    event.target.closest('.device-opt').classList.add('selected');
}

// Lidar com arquivo
function handleFile(file) {
    if (!file) return;
    
    if (file.type !== 'text/plain' && !file.name.endsWith('.txt')) {
        showMessage('Por favor, envie um arquivo .txt', 'error');
        return;
    }

    const reader = new FileReader();
    reader.onload = (e) => {
        document.getElementById('cookieInput').value = e.target.result;
        showMessage('Arquivo carregado! Agora clique em Salvar Cookies', 'success');
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

    if (!cookies[selectedService]) {
        cookies[selectedService] = [];
    }

    cookies[selectedService].push({
        id: Date.now(),
        content: cookieText,
        date: new Date().toLocaleString('pt-BR'),
    });

    localStorage.setItem('free-drop-cookies', JSON.stringify(cookies));
    document.getElementById('cookieInput').value = '';
    showMessage(`✅ ${selectedService} salvo com sucesso!`, 'success');
    loadCookies();
    updateCookiesList();
}

// Carregar cookies
function loadCookies() {
    const stored = localStorage.getItem('free-drop-cookies');
    cookies = stored ? JSON.parse(stored) : {};
    updateCookiesList();
}

// Atualizar lista de cookies
function updateCookiesList() {
    const list = document.getElementById('cookiesList');
    
    if (Object.keys(cookies).length === 0) {
        list.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">🗑️</div>
                <p>Nenhum cookie salvo ainda</p>
            </div>
        `;
        return;
    }

    let html = '';
    for (const [service, cookieArray] of Object.entries(cookies)) {
        for (const cookie of cookieArray) {
            const preview = cookie.content.substring(0, 60) + (cookie.content.length > 60 ? '...' : '');
            html += `
                <div class="cookie-item">
                    <div class="cookie-info">
                        <div class="cookie-service">${service}</div>
                        <div class="cookie-date">📅 ${cookie.date}</div>
                        <div class="cookie-preview">${preview}</div>
                    </div>
                    <button class="btn btn-danger" style="width: 80px; padding: 8px; margin: 0;" onclick="deleteCookie('${service}', ${cookie.id})">❌</button>
                </div>
            `;
        }
    }
    
    list.innerHTML = html;
}

// Deletar cookie
function deleteCookie(service, id) {
    if (confirm('Tem certeza que quer deletar?')) {
        cookies[service] = cookies[service].filter(c => c.id !== id);
        if (cookies[service].length === 0) delete cookies[service];
        localStorage.setItem('free-drop-cookies', JSON.stringify(cookies));
        loadCookies();
        showMessage('❌ Cookie deletado', 'success');
    }
}

// Gerar link
function generateLink() {
    if (Object.keys(cookies).length === 0) {
        showMessage('Salve cookies antes de gerar link', 'error');
        return;
    }

    const duration = document.getElementById('linkDuration').value;
    const data = {
        cookies: cookies,
        device: selectedDevice,
        duration: duration,
        created: new Date().toISOString()
    };

    const encoded = btoa(JSON.stringify(data));
    const baseUrl = window.location.origin + window.location.pathname;
    const link = `${baseUrl}?inject=${encoded}`;

    document.getElementById('generatedLink').value = link;
    document.getElementById('linkResult').classList.add('active');
    showMessage('✅ Link gerado com sucesso!', 'success');
}

// Copiar link
function copyLink() {
    const link = document.getElementById('generatedLink');
    link.select();
    document.execCommand('copy');
    showMessage('📋 Link copiado!', 'success');
}

// Mostrar mensagem
function showMessage(text, type) {
    const msg = document.getElementById('message');
    msg.textContent = text;
    msg.className = `message ${type}`;
    setTimeout(() => msg.className = 'message', 4000);
}

// Alternar abas
function switchTab(tab) {
    document.querySelectorAll('.tab-content').forEach(el => el.style.display = 'none');
    document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
    
    const tabId = tab === 'upload' ? 'uploadTab' : tab === 'saved' ? 'savedTab' : 'generateTab';
    document.getElementById(tabId).style.display = 'block';
    event.target.classList.add('active');
}

// Mostrar manager
function showManager() {
    document.getElementById('managerPage').classList.add('active');
    document.getElementById('injectPage').classList.remove('active');
    window.history.pushState({}, '', window.location.pathname);
}

// Verificar modo injeção
function checkInjectMode() {
    const params = new URLSearchParams(window.location.search);
    const inject = params.get('inject');

    if (inject) {
        document.getElementById('managerPage').classList.remove('active');
        document.getElementById('injectPage').classList.add('active');
        
        try {
            const data = JSON.parse(atob(inject));
            setTimeout(() => injectCookies(data), 2000);
        } catch (e) {
            showInjectError('Link inválido ou expirado');
        }
    }
}

// Injetar cookies
function injectCookies(data) {
    let count = 0;

    for (const [service, cookieArray] of Object.entries(data.cookies)) {
        for (const cookie of cookieArray) {
            const lines = cookie.content.split('\n');
            for (const line of lines) {
                if (line.trim()) {
                    try {
                        const parts = line.split('=');
                        if (parts.length >= 2) {
                            const name = parts[0].trim();
                            const value = parts.slice(1).join('=').trim();
                            const cleanValue = value.replace(/^["']|["']$/g, '');
                            
                            document.cookie = `${name}=${cleanValue}; path=/; samesite=lax; max-age=${86400 * 30}`;
                            count++;
                        }
                    } catch (e) {
                        console.error('Erro:', e);
                    }
                }
            }
        }
    }

    showInjectSuccess(count);
}

// Mostrar sucesso
function showInjectSuccess(count) {
    document.getElementById('injectStatus').innerHTML = `
        <div class="success-checkmark">✅</div>
        <p style="margin-top: 15px;">Injeção Concluída!</p>
        <p style="font-size: 14px; color: #888;">Foram injetados ${count} cookies</p>
    `;
    document.getElementById('injectInfo').style.display = 'block';
    
    setTimeout(() => {
        window.location.href = 'about:blank';
    }, 4000);
}

// Mostrar erro
function showInjectError(error) {
    document.getElementById('injectStatus').innerHTML = `
        <p style="color: #ff6666;">❌ Erro: ${error}</p>
    `;
}