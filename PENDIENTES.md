# Pendientes — Quiniela Mundial 2026

## ✅ AUDITORIA GLOBAL — COMPLETADA (ver REPORTE_AUDITORIA.md)

74 verificaciones OK, 0 fallos reales. Correccion aplicada: BOM eliminado.
Pendiente cosmetico (no afecta app): comentarios decorativos corruptos.

<details><summary>Detalle de las 9 areas auditadas</summary>

Antes de seguir con nuevas features, auditar TODO el sistema:

1. **Sintaxis y estructura:** node --check del JS, balance de divs,
   sin funciones huerfanas (revisar referencias rotas tipo premiarCampeon).
2. **Calculo de puntos:** bateria de tests (grupos, KO con/sin penales,
   bug empate-visitante) en JS, Python y SQL = mismos resultados.
3. **Consistencia entre vistas:** podio del tab vs resumen General
   (mismo filtro y desempate); penales informativos en Resultados, Picks,
   Bracket y modal detalle.
4. **Reglas de negocio:** fases_activas (activar/desactivar por fase),
   elegibilidad General, ganadores solo con pts>0.
5. **Generador de fases:** R32 desde grupos, siguientes fases desde
   ganadores, anti-duplicados (confirmacion al crear).
6. **Bracket:** centrado, lineas conectoras, flechas, campeon, penales.
7. **Movil:** tabla General con scroll, tabs sin truncar, inputs de goles.
8. **Flujos:** login por grupo, cambio de grupo, bloqueo por fase,
   no duplicar participante (nombre+whatsapp por grupo).
9. **Admin:** crear/editar partido, cargar resultado (limpia form),
   ver picks de participantes, actividad.

Objetivo: garantizar funcionamiento optimo end-to-end antes de mejoras
visuales y lanzamiento.
</details>

---


## 🚀 Antes de lanzar al grupo (fin de fase de prueba)

### 1. Borrar TODA la data de prueba
Ejecutar `limpiar_datos_prueba.sql` en Supabase (ver el archivo en el repo).
Limpia: pronosticos, partidos de prueba, resultados, actividad, participantes
de prueba. NO toca la estructura (tablas, RPCs, columnas) ni la config.

### 2. Mejora visual (identidad Mundial 2026)
- **Nivel 1 (facil, CSS):** paleta vibrante, header con degradado, tipografia
  deportiva, emojis grandes, tarjetas mas vistosas.
- **Nivel 2 (medio):** banderas reales via CDN (flag-icons), iconos de mejor
  calidad. Da mucho color sin inflar el archivo.
- **Nivel 3 (opcional):** imagen hero, confeti al ganar fase, micro-interacciones.
- Recomendado: Nivel 1 + 2.
- OJO copyright FIFA: NO usar logo oficial, mascota ni marca "FIFA World Cup".
  Si usar colores/estetica generica, balon/trofeo, banderas (dominio publico),
  y branding propio.

### 3. Foto/selfie de cada participante (dificultad media)
Avatar junto al nombre en ranking, podio y detalle.
- Base ya existe: subida a Supabase Storage (ver funcion uploadLogo de grupos).
- Falta: columna participantes.foto_url; input selfie en movil
  (<input type="file" accept="image/*" capture="user"> abre camara frontal);
  redimensionar a ~200x200 en cliente antes de subir; mostrar avatar redondo;
  placeholder con inicial si no hay foto.
- Opcional (no obligar). ~30KB por foto, free tier sobra.
- Hacerlo junto con la mejora visual (ambos tocan presentacion).

> Demo de referencia: demo_visual.html en el repo (header, banderas, podio).

---


## 🔴 Para activar la API automática (cuando empiece el torneo)

La actualización automática de resultados está LISTA en código pero requiere
configurar 3 secrets en GitHub para funcionar:

1. Ir a: repo `quiniela2026` → **Settings → Secrets and variables → Actions**
2. Crear estos 3 secrets:
   - `SUPABASE_URL` → la URL del proyecto Supabase
   - `SUPABASE_SERVICE_KEY` → la service_role key de Supabase (NO la anon)
   - `FOOTBALL_API_KEY` → la key de football-data.org

3. **Verificar el código de competición** del Mundial 2026 en football-data.org.
   En `actualizar_resultados.py` está como `COMPETITION_CODE = 'WC'`. Confirmar
   que ese código y `SEASON = 2026` son correctos cuando la API publique el torneo.

4. **Ajustar el cron si hace falta.** En `.github/workflows/actualizar.yml` corre
   cada 2h en la franja 16:00–06:00 UTC (jun-jul). Si el fixture oficial usa otras
   horas, ajustar las horas del cron.

> Mientras tanto, los resultados se cargan MANUALMENTE desde el panel admin.
> El botón `workflow_dispatch` permite ejecutar la API a mano desde GitHub Actions.

---

## ✅ Ya configurado en Supabase (no repetir)

- RPC `verify_admin_pin` (PIN admin server-side)
- RPC `set_config_valor` (guardar potes/textos de premio)
- RPC `get_actividad` (log de actividad solo para admin)
- Tabla `actividad` (registro de acciones de usuarios)
- Columna `participantes.fases_activas` (activar/desactivar por fase)
- Columnas `partidos.penales_local` y `penales_visita` (penales informativos)
- Config: textos de potes por fase (`pote_grupos`, `pote_r32`, etc.)

---

## 📋 Reglas de negocio confirmadas (reglamento Liceo San José)

- **Puntos:** todas las fases por marcador de **90 minutos**.
- **Penales/prórroga:** NO cuentan para puntos. Si va a penales = EMPATE oficial.
  Los penales solo se muestran de forma **informativa**.
- **`avanza_local`:** solo sirve para el bracket / generar siguiente fase, NO para puntos.
- **Tercer Puesto:** 10 pts resultado / 25 exacto (igual que Semis).
- **Premio General:** suma de todas las fases; elegible solo quien jugó todas.
- **Dinero:** la app NO maneja dinero; es opcional e interno de cada grupo.
- **recalcular_puntos.sql:** ya ejecutado con la lógica corregida (sin el bug
  del empate-visitante). Re-ejecutar si se recalcula manualmente.

---

## 💡 Ideas / mejoras futuras (no urgente)

- Bracket visual de eliminatorias (actualmente columnas simples).
- Migración a Supabase Auth + RLS real (cuando el sistema esté 100% estable).
