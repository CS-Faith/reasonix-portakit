// Fix session meta files: strip BOM, fix JSON escaping, ensure workspace matches
const fs = require('fs');
const path = require('path');

const sessionsDir = process.argv[2];
const ws = process.argv[3];

if (!sessionsDir || !ws) {
    console.error('Usage: node _fix_meta.js <sessionsDir> <workspacePath>');
    process.exit(1);
}

if (!fs.existsSync(sessionsDir)) {
    console.log('Sessions dir not found, skipping');
    process.exit(0);
}

const wsEscaped = ws.replace(/\\/g, '\\\\');
let fixed = 0;
let skipped = 0;

fs.readdirSync(sessionsDir).filter(f => f.endsWith('.meta.json')).forEach(file => {
    const p = path.join(sessionsDir, file);
    let raw = fs.readFileSync(p, 'utf8');
    
    // Strip BOM
    if (raw.charCodeAt(0) === 0xFEFF) {
        raw = raw.slice(1);
    }
    
    // Skip empty files — Reasonix will recreate them
    if (raw.trim().length === 0) {
        fs.unlinkSync(p);
        console.log('DELETED (empty):', file);
        fixed++;
        return;
    }
    
    // Try to parse
    let obj;
    let needsRewrite = false;
    
    try {
        obj = JSON.parse(raw);
    } catch {
        // JSON is broken — fix by rewriting with correct escaping
        needsRewrite = true;
    }
    
    if (needsRewrite || !obj) {
        // Reconstruct: keep whatever properties we can extract via regex
        const summaryMatch = raw.match(/"summary"\s*:\s*"((?:[^"\\]|\\.)*)"/);
        const costMatch = raw.match(/"totalCostUsd"\s*:\s*([0-9.eE+-]+)/);
        const cacheHitMatch = raw.match(/"cacheHitTokens"\s*:\s*(\d+)/);
        const cacheMissMatch = raw.match(/"cacheMissTokens"\s*:\s*(\d+)/);
        const completionMatch = raw.match(/"totalCompletionTokens"\s*:\s*(\d+)/);
        const lastPromptMatch = raw.match(/"lastPromptTokens"\s*:\s*(\d+)/);
        
        obj = { workspace: ws };
        if (summaryMatch) obj.summary = summaryMatch[1];
        if (costMatch) obj.totalCostUsd = parseFloat(costMatch[1]);
        if (cacheHitMatch) obj.cacheHitTokens = parseInt(cacheHitMatch[1]);
        if (cacheMissMatch) obj.cacheMissTokens = parseInt(cacheMissMatch[1]);
        if (completionMatch) obj.totalCompletionTokens = parseInt(completionMatch[1]);
        if (lastPromptMatch) obj.lastPromptTokens = parseInt(lastPromptMatch[1]);
        
        fs.writeFileSync(p, JSON.stringify(obj), 'utf8');
        console.log('FIXED (bad JSON):', file);
        fixed++;
        return;
    }
    
    // JSON is valid — just ensure workspace matches
    if (!obj.workspace || obj.workspace !== ws) {
        obj.workspace = ws;
        fs.writeFileSync(p, JSON.stringify(obj), 'utf8');
        console.log('FIXED (workspace):', file);
        fixed++;
    } else {
        skipped++;
    }
});

console.log(`Fixed: ${fixed}, Skipped: ${skipped}`);
