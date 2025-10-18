local url = "https://raw.githubusercontent.com/BRZeusz/T-nis-Neo/main/TenisNeo.lua"
local ok, body = pcall(function() return game:HttpGet(url, true) end)
if not ok then warn("[TenisNeo] HttpGet falhou:", body); return end
-- remove BOM se existir
if #body >= 3 then local b1,b2,b3 = body:byte(1,3) if b1==0xEF and b2==0xBB and b3==0xBF then body = body:sub(4); print("[TenisNeo] BOM removido") end end
-- detecta HTML/erro
local prefix = body:sub(1,200):lower()
if prefix:find("<!doctype") or prefix:find("<html") or prefix:find("not found") or prefix:find("repository access denied") then
	warn("[TenisNeo] Conteúdo remoto parece HTML/erro. Verifique a URL raw. Conteúdo início:\n"..body:sub(1,400))
	return
end
local fn, err = loadstring(body)
if not fn then warn("[TenisNeo] loadstring falhou:", err); warn("[TenisNeo] Conteúdo início:\n"..body:sub(1,400)); return end
local ok2, err2 = pcall(fn)
if not ok2 then warn("[TenisNeo] Erro ao executar script:", err2); return end
print("[TenisNeo] Script carregado com sucesso via URL.")