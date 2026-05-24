# Quiniela Mundial 2026 — Guía de Despliegue

## Estructura del proyecto (resumen rápido)

```
quiniela-mundial-2026/
├── index.html                  ← La app completa (frontend)
├── schema.sql                  ← Tablas base (ejecutar primero)
├── schema_grupos.sql           ← Tabla de grupos WhatsApp (ejecutar segundo)
├── actualizar_resultados.py    ← Script automático de resultados
├── requirements.txt            ← Dependencias Python
├── README_DEPLOY.md            ← Esta guía
└── .github/
    └── workflows/
        └── actualizar.yml      ← Cron job de GitHub Actions
```

---

## Paso 1: Crear proyecto en Supabase (gratis)

1. Ve a https://supabase.com y crea una cuenta gratuita.
2. Crea un nuevo proyecto (elige cualquier nombre, ej: "quiniela2026").
3. Ve a **SQL Editor** y pega el contenido de `schema.sql`. Ejecuta.
4. Luego pega el contenido de `schema_grupos.sql`. Ejecuta.
4. Guarda estos datos que necesitarás más adelante:
   - **Project URL**: Settings > API > Project URL
   - **anon key**: Settings > API > Project API keys > anon (public)
   - **service_role key**: Settings > API > Project API keys > service_role (**no compartas esto**)

## Paso 2: Configurar el index.html

Abre `index.html` y busca estas líneas al inicio del script:

```javascript
const SUPABASE_URL      = 'TU_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'TU_SUPABASE_ANON_KEY';
```

Reemplaza con tus datos reales. El **anon key** es seguro para usar en el HTML (es público por diseño).

## Paso 3: Publicar en Vercel (gratis)

1. Crea una cuenta en https://vercel.com (usa tu cuenta de GitHub).
2. Sube el proyecto a un repositorio GitHub:
   ```
   git init
   git add index.html schema.sql actualizar_resultados.py requirements.txt .github/
   git commit -m "Quiniela Mundial 2026"
   git remote add origin https://github.com/TU_USUARIO/quiniela2026.git
   git push -u origin main
   ```
3. En Vercel: **New Project** → importa el repositorio → Deploy.
4. Vercel te dará una URL pública como `quiniela2026.vercel.app`.

> **Alternativa más simple**: Solo sube el `index.html` a https://netlify.com/drop (arrastra el archivo). URL lista en segundos.

## Paso 4: Obtener API key de football-data.org (gratis)

1. Ve a https://www.football-data.org/client/register
2. Regístrate con tu email.
3. Recibirás tu API key por email.
4. El plan gratuito permite 10 requests/minuto — suficiente para el script.

## Paso 5: Configurar GitHub Actions (actualización automática)

En tu repositorio GitHub:
1. Ve a **Settings > Secrets and variables > Actions > New repository secret**.
2. Agrega estos 3 secretos:
   - `SUPABASE_URL` → tu Project URL de Supabase
   - `SUPABASE_SERVICE_KEY` → tu service_role key
   - `FOOTBALL_API_KEY` → tu key de football-data.org
3. Ve a **Actions** y habilita los workflows.
4. El script correrá automáticamente cada 2 horas.
5. Para correrlo manualmente: Actions → "Actualizar Resultados" → "Run workflow".

## Paso 6: Cambiar el PIN de admin

En Supabase > **Table Editor** > tabla `config`:
- Cambia el valor de `admin_pin` a tu PIN deseado (el default es `2026`).

## Paso 7: Compartir con el grupo

Copia el link de Vercel o Netlify y compártelo en el grupo de WhatsApp.

---

## Cómo registrar el Campeón real (al terminar el torneo)

En Supabase > Table Editor > tabla `config`:
- Encuentra la fila con `clave = 'campeon_real'`
- Cambia el valor a exactamente el nombre del equipo ganador (ej: `Argentina`)
- Corre el script manualmente → asignará automáticamente los 20 pts bonus.

---

## Operación durante el torneo

| Tarea | Dónde |
|---|---|
| Ver/editar resultados manualmente | Admin panel en la app (PIN) |
| Actualización automática de resultados | GitHub Actions (cada 2h) |
| Abrir/cerrar fases eliminatorias | Admin panel en la app |
| Ver quién se registró | Admin panel → Participantes |
| Insertar partidos KO (si el script falla) | Supabase Table Editor |

---

## Estructura del proyecto

```
quiniela-mundial-2026/
├── index.html                  ← La app completa (frontend)
├── actualizar_resultados.py    ← Script automático de resultados
├── requirements.txt            ← Dependencias Python
├── schema.sql                  ← Estructura de la base de datos
├── README_DEPLOY.md            ← Esta guía
└── .github/
    └── workflows/
        └── actualizar.yml      ← Cron job de GitHub Actions
```
