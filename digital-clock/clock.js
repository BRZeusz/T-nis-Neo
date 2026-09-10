// Armazenar relógios adicionados
let clocks = [];
let updateInterval;

// Mapa de cidades com nomes amigáveis
const cityNames = {
    'America/New_York': 'New York',
    'Europe/London': 'Londres',
    'Europe/Paris': 'Paris',
    'Europe/Berlin': 'Berlim',
    'Europe/Madrid': 'Madri',
    'Europe/Rome': 'Roma',
    'Europe/Amsterdam': 'Amsterdã',
    'Europe/Istanbul': 'Istambul',
    'Asia/Dubai': 'Dubai',
    'Asia/Kolkata': 'Índia',
    'Asia/Bangkok': 'Bangkok',
    'Asia/Singapore': 'Singapura',
    'Asia/Hong_Kong': 'Hong Kong',
    'Asia/Tokyo': 'Tóquio',
    'Asia/Seoul': 'Seul',
    'Australia/Sydney': 'Sydney',
    'Australia/Melbourne': 'Melbourne',
    'Pacific/Auckland': 'Auckland',
    'America/Los_Angeles': 'Los Angeles',
    'America/Chicago': 'Chicago',
    'America/Denver': 'Denver',
    'America/Anchorage': 'Anchorage',
    'Pacific/Honolulu': 'Honolulu',
    'America/Mexico_City': 'Cidade do México',
    'America/Toronto': 'Toronto',
    'America/Argentina/Buenos_Aires': 'Buenos Aires',
    'America/Sao_Paulo': 'São Paulo',
    'Africa/Cairo': 'Cairo',
    'Africa/Johannesburg': 'Johannesburgo',
    'Africa/Lagos': 'Lagos'
};

// Inicializar
document.addEventListener('DOMContentLoaded', function() {
    // Adicionar alguns relógios padrão ao carregar
    addDefaultClocks();
    updateAllClocks();
    updateInterval = setInterval(updateAllClocks, 1000);

    // Atualizar quando mudar o formato de 24h
    document.getElementById('format24h').addEventListener('change', updateAllClocks);
});

// Adicionar relógios padrão
function addDefaultClocks() {
    const defaultCities = [
        'America/New_York',
        'Europe/London',
        'Asia/Tokyo',
        'Australia/Sydney'
    ];
    
    defaultCities.forEach(timezone => {
        clocks.push({
            timezone: timezone,
            id: Date.now() + Math.random()
        });
    });
}

// Adicionar novo relógio
function addClock() {
    const citySelect = document.getElementById('citySelect');
    const customCity = document.getElementById('customCity').value.trim();
    
    let timezone = citySelect.value;
    let displayName = cityNames[timezone];
    
    if (customCity) {
        timezone = customCity;
        displayName = customCity;
    }
    
    if (!timezone) {
        alert('Por favor, selecione uma cidade ou digite um fuso horário');
        return;
    }
    
    // Verificar se já existe
    if (clocks.some(c => c.timezone === timezone)) {
        alert('Este fuso horário já foi adicionado!');
        return;
    }
    
    clocks.push({
        timezone: timezone,
        displayName: displayName,
        id: Date.now() + Math.random()
    });
    
    document.getElementById('customCity').value = '';
    updateAllClocks();
}

// Remover relógio
function removeClock(id) {
    clocks = clocks.filter(c => c.id !== id);
    updateAllClocks();
}

// Atualizar todos os relógios
function updateAllClocks() {
    const container = document.getElementById('clocksContainer');
    const emptyMessage = document.getElementById('emptyMessage');
    const format24h = document.getElementById('format24h').checked;
    
    if (clocks.length === 0) {
        container.innerHTML = '';
        emptyMessage.style.display = 'block';
        return;
    }
    
    emptyMessage.style.display = 'none';
    container.innerHTML = clocks.map(clock => createClockHTML(clock, format24h)).join('');
    
    // Adicionar event listeners para botões de remover
    document.querySelectorAll('.remove-btn').forEach(btn => {
        btn.addEventListener('click', function() {
            const clockId = parseFloat(this.dataset.clockId);
            removeClock(clockId);
        });
    });
}

// Criar HTML do relógio
function createClockHTML(clock, format24h) {
    const time = getTimeInTimezone(clock.timezone, format24h);
    const displayName = clock.displayName || clock.timezone;
    
    if (!time) {
        return `
            <div class="clock-card">
                <button class="remove-btn" data-clock-id="${clock.id}">✕</button>
                <div class="clock-city">${displayName}</div>
                <div class="clock-timezone" style="color: #ff6666;">⚠️ Fuso Horário Inválido</div>
            </div>
        `;
    }
    
    return `
        <div class="clock-card">
            <button class="remove-btn" data-clock-id="${clock.id}">✕</button>
            <div class="clock-city">${displayName}</div>
            <div class="clock-timezone">${time.timezone}</div>
            <div class="clock-time">${time.time}</div>
            <div class="clock-date">${time.date}</div>
            <div class="time-info">${time.dayOfWeek}</div>
        </div>
    `;
}

// Obter hora no fuso horário
function getTimeInTimezone(timezone, format24h) {
    try {
        // Criar formatter para o fuso horário
        const formatter = new Intl.DateTimeFormat('pt-BR', {
            timeZone: timezone,
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: !format24h,
            weekday: 'long'
        });
        
        const now = new Date();
        const parts = formatter.formatToParts(now);
        
        // Extrair partes da data/hora
        let time = '';
        let date = '';
        let dayOfWeek = '';
        
        for (const part of parts) {
            if (part.type === 'hour') time += part.value;
            if (part.type === 'hour') time += ':';
            if (part.type === 'minute') time += part.value;
            if (part.type === 'minute') time += ':';
            if (part.type === 'second') time += part.value;
            if (part.type === 'dayPeriod') time += ' ' + part.value;
            
            if (part.type === 'day') date = part.value + '/';
            if (part.type === 'month') date += part.value + '/';
            if (part.type === 'year') date += part.value;
            
            if (part.type === 'weekday') dayOfWeek = part.value.charAt(0).toUpperCase() + part.value.slice(1);
        }
        
        // Remover espaço extra no final da hora se houver
        time = time.replace(/\/$/, '').trim();
        
        // Obter offset do fuso horário
        const utcDate = now.toLocaleString('pt-BR', { timeZone: 'UTC' });
        const localDate = now.toLocaleString('pt-BR', { timeZone: timezone });
        
        const utcTime = new Date(utcDate);
        const localTime = new Date(localDate);
        
        const offsetMs = localTime - utcTime;
        const offsetHours = Math.round(offsetMs / (1000 * 60 * 60));
        const offsetMins = Math.round((Math.abs(offsetMs) % (1000 * 60 * 60)) / (1000 * 60));
        
        let tzString = 'UTC';
        if (offsetHours > 0) {
            tzString += '+' + offsetHours;
        } else if (offsetHours < 0) {
            tzString += offsetHours;
        }
        if (offsetMins !== 0) {
            tzString += ':' + (offsetMins < 10 ? '0' : '') + offsetMins;
        }
        
        return {
            time: time,
            date: date,
            dayOfWeek: dayOfWeek,
            timezone: tzString
        };
    } catch (e) {
        console.error('Erro ao obter hora:', e);
        return null;
    }
}

// Permitir adicionar com Enter
document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('customCity').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            addClock();
        }
    });
    
    document.getElementById('citySelect').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            addClock();
        }
    });
});