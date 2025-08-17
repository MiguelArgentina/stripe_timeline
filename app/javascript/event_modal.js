// ---------- helpers ----------
function centsToMoney(cents, currency) {
    if (cents == null) return "";
    const v = Number(cents) / 100;
    return new Intl.NumberFormat(undefined, {
        style: "currency",
        currency: (currency || "USD").toUpperCase()
    }).format(v);
}

function csvEscape(s) {
    if (s == null) return "";
    const t = String(s);
    return /[",\n]/.test(t) ? `"${t.replace(/"/g, '""')}"` : t;
}

function eventToCsvRow(meta, obj) {
    return [
        meta.transaction_key || "",
        meta.type || "",
        new Date(Number(meta.time) * 1000).toISOString(),
        meta.livemode,
        meta.account || "",
        obj.object || "",
        obj.id || "",
        (obj.amount ?? obj.amount_paid ?? ""),
        obj.currency || "",
        obj.status || "",
        (obj.reason || obj?.evidence?.reason || obj.failure_reason || ""),
        (obj.charge || obj?.charges?.data?.[0]?.id || ""),
        (obj.payment_intent || (obj.object === "payment_intent" ? obj.id : "")),
        (obj.object === "refund" ? obj.id : ""),
        (obj.object === "dispute" ? obj.id : ""),
        (obj.balance_transaction || obj.balance_transaction_id || ""),
        meta.source || ""
    ].map(csvEscape).join(",");
}

// Parse payload from data-event-b64 (preferred) or data-event (legacy)
function parsePayloadFromTrigger(btn) {
    try {
        if (btn?.dataset.eventB64) return JSON.parse(atob(btn.dataset.eventB64));
        if (btn?.dataset.event)   return JSON.parse(btn.dataset.event);
    } catch (err) {
        console.warn("Failed to parse event payload:", err);
    }
    return {};
}

// Robust copy that works on non-secure contexts too
async function robustCopy(text) {
    // 1) Native API on secure origins (https, localhost)
    if (navigator.clipboard && window.isSecureContext) {
        try { await navigator.clipboard.writeText(text); return true; } catch (_) {}
    }

    // 2) execCommand on hidden textarea
    const ta = document.createElement("textarea");
    ta.value = text;
    ta.setAttribute("readonly", "");
    ta.style.position = "fixed";
    ta.style.top = "0";
    ta.style.left = "0";
    ta.style.opacity = "0";
    document.body.appendChild(ta);
    ta.focus();
    ta.select();
    ta.setSelectionRange(0, ta.value.length);

    let ok = false;
    try { ok = document.execCommand("copy"); } catch (_) {}
    document.body.removeChild(ta);
    if (ok) return true;

    // 3) Range select on the JSON <pre>, then execCommand
    try {
        const pre = document.querySelector("#eventModal #evJson");
        if (pre) {
            const range = document.createRange();
            range.selectNodeContents(pre);
            const sel = window.getSelection();
            sel.removeAllRanges();
            sel.addRange(range);
            ok = document.execCommand("copy");
            sel.removeAllRanges();
            if (ok) return true;
        }
    } catch (_) {}

    // 4) Last resort: prompt
    window.prompt("Copy to clipboard:", text);
    return false;
}

// ---------- modal fill ----------
function fillModal(modal, triggerBtn) {
    const $ = (sel) => modal.querySelector(sel);

    const titleEl  = $("#eventModalTitle");
    const evType   = $("#evType");
    const evTime   = $("#evTime");
    const evLive   = $("#evLive");
    const evAcct   = $("#evAcct");
    const evSource = $("#evSource");
    const evObj    = $("#evObj");
    const evObjId  = $("#evObjId");
    const evAmount = $("#evAmount");
    const evStatus = $("#evStatus");
    const evReason = $("#evReason");
    const evJson   = $("#evJson");

    const type = triggerBtn?.dataset.type || "";
    const time = triggerBtn?.dataset.time || "";
    const live = triggerBtn?.dataset.livemode === "true" ? "live" : "test";
    const acct = triggerBtn?.dataset.account || "";
    const src  = triggerBtn?.dataset.source  || "";

    const payload = parsePayloadFromTrigger(triggerBtn);
    const o = payload?.data?.object || {};

    if (titleEl) titleEl.textContent = type;
    if (evType)  evType.textContent  = type;
    if (evTime)  evTime.textContent  = time ? new Date(Number(time) * 1000).toLocaleString() : "";
    if (evLive)  evLive.textContent  = live;
    if (evAcct)  evAcct.textContent  = acct;
    if (evSource)evSource.textContent= src;

    if (evObj)    evObj.textContent    = o.object || "";
    if (evObjId)  evObjId.textContent  = o.id || "";
    if (evAmount) evAmount.textContent = centsToMoney(o.amount ?? o.amount_paid, o.currency);
    if (evStatus) evStatus.textContent = o.status || "";
    if (evReason) evReason.textContent = o.reason || o?.evidence?.reason || o.failure_reason || "";
    if (evJson)   evJson.textContent   = JSON.stringify(payload || {}, null, 2);

    modal.dataset.csvRow = eventToCsvRow(
        { type, time, livemode: live === "live", account: acct, source: src },
        o
    );
}

// ---------- wire up once ----------
function wireEventModal() {
    // Fill when our Bootstrap modal is about to show
    document.addEventListener("show.bs.modal", (ev) => {
        const modal = ev.target;
        if (!modal || modal.id !== "eventModal") return;
        fillModal(modal, ev.relatedTarget);
    });

    // Copy JSON / Export CSV (delegated)
    document.addEventListener("click", async (ev) => {
        const copyBtn = ev.target.closest('[data-role="copy-json"]');
        if (copyBtn) {
            const modal = copyBtn.closest("#eventModal");
            const json  = modal?.querySelector("#evJson")?.textContent || "{}";
            const ok    = await robustCopy(json);
            copyBtn.textContent = ok ? "Copied!" : "Copied (manual)";
            setTimeout(() => (copyBtn.textContent = "Copy JSON"), 1200);
            return;
        }

        const csvBtn = ev.target.closest('[data-role="export-csv"]');
        if (csvBtn) {
            const modal  = csvBtn.closest("#eventModal");
            const row    = modal?.dataset.csvRow || "";
            const header = [
                "transaction_key","event_type","created_at","livemode","account",
                "object","object_id","amount","currency","status","reason",
                "charge_id","payment_intent_id","refund_id","dispute_id","balance_tx_id","source"
            ].join(",");
            const csv = header + "\n" + row;

            const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
            const url  = URL.createObjectURL(blob);
            const a    = document.createElement("a");
            a.href = url; a.download = "event.csv";
            document.body.appendChild(a); a.click(); a.remove();
            URL.revokeObjectURL(url);
        }
    });
}

document.addEventListener("turbo:load", wireEventModal);
document.addEventListener("DOMContentLoaded", wireEventModal);
