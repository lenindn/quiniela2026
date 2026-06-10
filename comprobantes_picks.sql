-- ============================================================
-- Tracking de comprobantes de picks enviados por WhatsApp
-- Ejecutar en: Supabase > SQL Editor
-- ============================================================

ALTER TABLE participantes
    ADD COLUMN IF NOT EXISTS comprobantes_enviados JSONB DEFAULT '{}'::jsonb;

-- Estructura: { "grupos": true, "r32": false, ... }
-- Marca, por fase, si ya se le envio el comprobante de picks al participante.
