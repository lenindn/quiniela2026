"""
Quiniela Mundial 2026 — Script de actualización automática de resultados
Fuente: ESPN (API pública, sin autenticación requerida)
Ejecutar: python actualizar_resultados.py
Programar: cron-job.org → POST a GitHub Actions workflow_dispatch cada 5 min
"""

import os
import sys
import re
import requests
from datetime import datetime, timezone, timedelta
from supabase import create_client, Client

# ============================================================
# CONFIGURACIÓN
# ============================================================
SUPABASE_URL         = os.environ.get('SUPABASE_URL', '')
SUPABASE_SERVICE_KEY = os.environ.get('SUPABASE_SERVICE_KEY', '')

ESPN_BASE = 'https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/scoreboard'

# Fechas con partidos de R16 (para auto-generación de cruces)
FECHAS_R16 = ['20260704', '20260705', '20260706', '20260707']

# Numeración del bracket eliminatorio
R32_BASE = 73   # numero del primer partido de R32
R16_BASE = 89   # numero del primer partido de R16

# Sistema de puntos (debe coincidir con v2.html)
PUNTOS = {
    'grupos':       {'resultado': 2,  'exacto': 5 },
    'r32':          {'resultado': 3,  'exacto': 8 },
    'r16':          {'resultado': 5,  'exacto': 12},
    'cuartos':      {'resultado': 7,  'exacto': 17},
    'semis':        {'resultado': 10, 'exacto': 25},
    'tercer_lugar': {'resultado': 10, 'exacto': 25},
    'final':        {'resultado': 15, 'exacto': 35},
}
BONUS_CAMPEON = 20

# Traducción ESPN (inglés) → nombres usados en la BD (español).
# ESPN usa los mismos nombres en inglés que football-data.org en su mayoría.
EQUIPO_MAP = {
    'Mexico':                 'México',
    'South Africa':           'Sudáfrica',
    'South Korea':            'Corea del Sur',
    'Czech Republic':         'Chequia',
    'Canada':                 'Canadá',
    'Bosnia and Herzegovina': 'Bosnia y Herzegovina',
    'Qatar':                  'Qatar',
    'Switzerland':            'Suiza',
    'Brazil':                 'Brasil',
    'Morocco':                'Marruecos',
    'Haiti':                  'Haití',
    'Scotland':               'Escocia',
    'United States':          'Estados Unidos',
    'USA':                    'Estados Unidos',
    'Paraguay':               'Paraguay',
    'Australia':              'Australia',
    'Turkey':                 'Turquía',
    'Germany':                'Alemania',
    'Curacao':                'Curazao',
    'Ivory Coast':            'Costa de Marfil',
    "Côte d'Ivoire":          'Costa de Marfil',
    'Ecuador':                'Ecuador',
    'Netherlands':            'Países Bajos',
    'Japan':                  'Japón',
    'Sweden':                 'Suecia',
    'Tunisia':                'Túnez',
    'Belgium':                'Bélgica',
    'Egypt':                  'Egipto',
    'Iran':                   'Irán',
    'New Zealand':            'Nueva Zelanda',
    'Spain':                  'España',
    'Cape Verde':             'Cabo Verde',
    'Saudi Arabia':           'Arabia Saudita',
    'Uruguay':                'Uruguay',
    'France':                 'Francia',
    'Senegal':                'Senegal',
    'Iraq':                   'Irak',
    'Norway':                 'Noruega',
    'Argentina':              'Argentina',
    'Algeria':                'Argelia',
    'Austria':                'Austria',
    'Jordan':                 'Jordania',
    'Portugal':               'Portugal',
    'DR Congo':               'RD Congo',
    'Congo DR':               'RD Congo',
    'Uzbekistan':             'Uzbekistán',
    'Colombia':               'Colombia',
    'England':                'Inglaterra',
    'Croatia':                'Croacia',
    'Ghana':                  'Ghana',
    'Panama':                 'Panamá',
}

def traducir_equipo(nombre: str) -> str:
    return EQUIPO_MAP.get(nombre, nombre)

# ============================================================
# CLIENTE SUPABASE
# ============================================================
def get_supabase() -> Client:
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        print('ERROR: Variables SUPABASE_URL y SUPABASE_SERVICE_KEY requeridas.')
        sys.exit(1)
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# ============================================================
# ESPN API
# ============================================================
ESPN_STATUS_MAP = {
    'Full Time':                     'finalizado',
    'Final Score - After Penalties': 'finalizado',
    'Final Score - After Extra Time':'finalizado',
    'In Progress':                   'en_curso',
    '1st Half':                      'en_curso',
    '2nd Half':                      'en_curso',
    'First Half':                    'en_curso',
    'Second Half':                   'en_curso',
    'Halftime':                      'en_curso',
    'Half Time':                     'en_curso',
    'Extra Time':                    'en_curso',
    'Overtime':                      'en_curso',
    'Penalty Shootout':              'en_curso',
    'Scheduled':                     'pendiente',
    'Timed':                         'pendiente',
    'Postponed':                     'pendiente',
    'Cancelled':                     'pendiente',
    'Suspended':                     'pendiente',
}

ESPN_SUMMARY = 'https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world/summary'
GOAL_TYPES   = {'goal', 'goal - header', 'penalty - scored'}

def fetch_90min_score(event_id: str, home_raw: str, away_raw: str):
    """
    Consulta el summary de ESPN y devuelve (goles_local, goles_visita) al 90'
    contando solo los keyEvents de período 1 y 2 (ignora prórroga P3/P4).
    Usado cuando status = 'Final Score - After Extra Time'.
    Retorna (None, None) si falla.
    """
    try:
        resp = requests.get(ESPN_SUMMARY, params={'event': event_id}, timeout=15)
        resp.raise_for_status()
        events = resp.json().get('keyEvents', [])
    except Exception as e:
        print(f'  WARN summary ESPN ({event_id}): {e}')
        return None, None

    gl, gv = 0, 0
    for ev in events:
        period = ev.get('period', {}).get('number', 99)
        if period > 2:
            continue  # ignorar prórroga
        etype = ev.get('type', {}).get('text', '').lower()
        if etype not in GOAL_TYPES:
            continue
        team_name = (ev.get('team') or {}).get('displayName', '')
        own_goal  = 'own goal' in etype
        scores_for_home = (team_name.lower() == home_raw.lower()) != own_goal
        if scores_for_home:
            gl += 1
        else:
            gv += 1

    print(f'  90min score via summary: {home_raw} {gl}-{gv} {away_raw}')
    return gl, gv


def fetch_espn(date_str: str = None) -> list:
    """Obtiene partidos de ESPN. date_str en formato YYYYMMDD o None para hoy."""
    params = {'dates': date_str} if date_str else {}
    try:
        resp = requests.get(ESPN_BASE, params=params, timeout=15)
        resp.raise_for_status()
        return resp.json().get('events', [])
    except Exception as e:
        print(f'  WARN ESPN ({date_str or "hoy"}): {e}')
        return []

def parse_penalty_notes(notes: list, home_raw: str, away_raw: str):
    """
    Extrae (pen_local, pen_visita) de ESPN notes.
    Formato ESPN: "Team advance X-Y on penalties"
    Retorna (None, None) si no hubo penales.
    """
    for note in notes:
        text = note.get('text', '')
        if 'on penalties' not in text.lower():
            continue
        m = re.search(r'(\d+)-(\d+)\s+on penalties', text, re.IGNORECASE)
        if not m:
            continue
        w_score, l_score = int(m.group(1)), int(m.group(2))
        team_adv = text.split(' advance')[0].strip() if ' advance' in text else ''
        # Determinar si el ganador de penales es home o away
        home_wins = team_adv and (
            team_adv.lower() in home_raw.lower() or
            home_raw.lower() in team_adv.lower()
        )
        if home_wins:
            return w_score, l_score   # home ganó penales
        else:
            return l_score, w_score   # away ganó penales
    return None, None

def parse_espn_event(event: dict) -> dict | None:
    """Convierte un evento de ESPN al formato interno. Retorna None si debe ignorarse."""
    comp        = event.get('competitions', [{}])[0]
    competitors = {c['homeAway']: c for c in comp.get('competitors', [])}
    home        = competitors.get('home', {})
    away        = competitors.get('away', {})

    home_raw = home.get('team', {}).get('displayName', '')
    away_raw = away.get('team', {}).get('displayName', '')

    # Ignorar partidos donde los equipos aún no están definidos
    if not home_raw or not away_raw:
        return None
    if 'winner' in home_raw.lower() or 'winner' in away_raw.lower():
        return None

    equipo_local  = traducir_equipo(home_raw)
    equipo_visita = traducir_equipo(away_raw)

    status_desc = event.get('status', {}).get('type', {}).get('description', 'Scheduled')
    estado      = ESPN_STATUS_MAP.get(status_desc, 'pendiente')

    # Marcador reglamentario (90'). ESPN muestra el marcador de 90' como score
    # principal; los goles de prórroga y penales NO están incluidos aquí.
    # Excepción: "After Extra Time" incluye goles de prórroga → consultar summary.
    home_score = home.get('score')
    away_score = away.get('score')
    gl = int(home_score) if home_score not in (None, '') else None
    gv = int(away_score) if away_score not in (None, '') else None

    # tipo_fin: null (90'), 'penales', 'tiempo_extra'
    tipo_fin  = None
    pen_local, pen_visita = None, None

    if status_desc == 'Final Score - After Extra Time':
        # ESPN incluye goles de ET en el score → buscar marcador real al 90'
        et_total_local  = int(home_score) if home_score not in (None, '') else None
        et_total_visita = int(away_score) if away_score not in (None, '') else None
        event_id = event.get('id', '')
        gl90, gv90 = fetch_90min_score(event_id, home_raw, away_raw)
        if gl90 is not None:
            gl, gv    = gl90, gv90
            tipo_fin  = 'tiempo_extra'
            pen_local, pen_visita = et_total_local, et_total_visita
        else:
            gl, gv = et_total_local, et_total_visita
    elif 'penalties' in status_desc.lower():
        pen_local, pen_visita = parse_penalty_notes(comp.get('notes', []), home_raw, away_raw)
        tipo_fin = 'penales'
        gl = int(home_score) if home_score not in (None, '') else None
        gv = int(away_score) if away_score not in (None, '') else None
    else:
        gl = int(home_score) if home_score not in (None, '') else None
        gv = int(away_score) if away_score not in (None, '') else None

    # Guardia: no cerrar si el marcador de 90' aún no está disponible
    if estado == 'finalizado' and (gl is None or gv is None):
        estado = 'en_curso'

    # Ganador
    avanza_local = None
    if estado == 'finalizado':
        if home.get('winner') is True:
            avanza_local = True
        elif away.get('winner') is True:
            avanza_local = False

    # Minuto en vivo (ej. "35'", "45'+2'")
    clock  = event.get('status', {}).get('displayClock', '')
    minuto = clock if estado == 'en_curso' and clock else None

    venue = comp.get('venue', {})
    sede  = venue.get('fullName', '')

    return {
        'equipo_local':   equipo_local,
        'equipo_visita':  equipo_visita,
        'estado':         estado,
        'goles_local':    gl,
        'goles_visita':   gv,
        'penales_local':  pen_local,
        'penales_visita': pen_visita,
        'tipo_fin':       tipo_fin,
        'avanza_local':   avanza_local,
        'minuto':         minuto,
        'sede':           sede,
        'fecha_partido':  event.get('date', ''),
        'fuente':         'automatico' if estado == 'finalizado' else 'pendiente',
    }

# ============================================================
# AUTO-GENERACIÓN DE CRUCES R16
# ============================================================
def generar_cruces_r16(sb: Client, espn_matches: list):
    """
    Crea partidos de R16 en la BD cuando ESPN ya tiene los equipos definidos.
    El numero de bracket se calcula a partir de los numeros de los R32 que ganaron.
    Solo crea cruces nuevos — nunca modifica los existentes.
    """
    # Cruces ya existentes en BD (no duplicar)
    r16_res = sb.table('partidos').select('equipo_local,equipo_visita').eq('fase', 'r16').execute()
    ya_creados = {frozenset([p['equipo_local'], p['equipo_visita']]) for p in (r16_res.data or [])}

    # Ganadores de R32 → numero del partido que ganaron
    r32_res = sb.table('partidos') \
        .select('numero,equipo_local,equipo_visita,avanza_local,estado') \
        .eq('fase', 'r32').execute()
    ganadores = {}  # equipo -> numero r32
    for p in (r32_res.data or []):
        if p.get('estado') != 'finalizado' or p.get('numero') is None:
            continue
        if p.get('avanza_local') is True:
            ganadores[p['equipo_local']] = p['numero']
        elif p.get('avanza_local') is False:
            ganadores[p['equipo_visita']] = p['numero']

    nuevos = 0
    for m in espn_matches:
        if not m:
            continue
        par = frozenset([m['equipo_local'], m['equipo_visita']])
        if par in ya_creados:
            continue

        # Calcular numero de bracket: pares adyacentes de R32 alimentan un slot de R16
        r32_a = ganadores.get(m['equipo_local'])
        r32_b = ganadores.get(m['equipo_visita'])
        if r32_a and r32_b:
            numero = R16_BASE + (min(r32_a, r32_b) - R32_BASE) // 2
        else:
            numero = None
            print(f'  WARN: no se pudo calcular numero para {m["equipo_local"]} vs {m["equipo_visita"]} (ganadores R32 no encontrados)')

        res = sb.table('partidos').insert({
            'fase':          'r16',
            'equipo_local':  m['equipo_local'],
            'equipo_visita': m['equipo_visita'],
            'fecha_partido': m['fecha_partido'],
            'sede':          m['sede'],
            'estado':        'pendiente',
            'numero':        numero,
            'fuente':        'pendiente',
        }).execute()

        if res.data:
            ya_creados.add(par)
            nuevos += 1
            print(f'  CRUCE R16: {m["equipo_local"]} vs {m["equipo_visita"]} | numero={numero} | {m["sede"]}')

    if nuevos == 0:
        print('  Sin cruces nuevos.')

# ============================================================
# SINCRONIZACIÓN DE RESULTADOS
# ============================================================
def sync_from_espn(sb: Client, espn_matches: list) -> list:
    """Actualiza resultados en BD desde ESPN. Retorna lista de partidos recién finalizados."""
    res    = sb.table('partidos').select('*').execute()
    db_map = {}
    for p in (res.data or []):
        key = (p['equipo_local'], p['equipo_visita'])
        prev = db_map.get(key)
        # Si hay duplicado, preferir el que NO es r16 (evita que falsos R16 oculten el R32 real)
        if prev is None or prev.get('fase') == 'r16':
            db_map[key] = p

    recien_finalizados = []

    for m in espn_matches:
        if not m:
            continue
        key      = (m['equipo_local'], m['equipo_visita'])
        existing = db_map.get(key)
        if not existing:
            continue

        # Nunca modificar partidos ya finalizados en la BD
        if existing.get('estado') == 'finalizado':
            continue

        # ESPN devuelve score=0 para partidos pendientes — ignorar
        if m['estado'] == 'pendiente':
            continue

        necesita_update = (
            existing.get('estado') != m['estado'] or
            (m['goles_local'] is not None and existing.get('goles_local') != m['goles_local']) or
            m['estado'] == 'en_curso'
        )
        if not necesita_update:
            continue

        was_not_final = existing.get('estado') != 'finalizado'
        is_now_final  = m['estado'] == 'finalizado'

        updates = {
            'goles_local':    m['goles_local']  if m['goles_local']  is not None else existing.get('goles_local'),
            'goles_visita':   m['goles_visita'] if m['goles_visita'] is not None else existing.get('goles_visita'),
            'minuto':         m['minuto'],
            'avanza_local':   m['avanza_local'],
            'penales_local':  m['penales_local'],
            'penales_visita': m['penales_visita'],
            'tipo_fin':       m['tipo_fin'],
            'estado':         m['estado'],
            'fuente':         m['fuente'],
            'sede':           m['sede'] or existing.get('sede', ''),
        }

        try:
            sb.table('partidos').update(updates).eq('id', existing['id']).execute()
            print(f'  UPD: {key[0]} vs {key[1]} — {m["estado"]}')
        except Exception as ex:
            print(f'  WARN update falló ({ex}), reintentando sin minuto...')
            updates.pop('minuto', None)
            sb.table('partidos').update(updates).eq('id', existing['id']).execute()
            print(f'  UPD (sin minuto): {key[0]} vs {key[1]} — {m["estado"]}')

        if was_not_final and is_now_final:
            recien_finalizados.append({**existing, **updates})

    return recien_finalizados

# ============================================================
# CÁLCULO DE PUNTOS
# ============================================================
def calcular_puntos(partido: dict, pronostico: dict) -> int:
    """
    Puntos según marcador al 90'. Prórroga y penales NO cuentan para el score.
    Empate en 90' (incluyendo los que van a penales) = resultado 'E'.
    Sincronizado con calcularPuntos() en v2.html.
    """
    fase = partido.get('fase', 'grupos')
    pts  = PUNTOS.get(fase, PUNTOS['grupos'])
    gl_r = partido.get('goles_local')
    gv_r = partido.get('goles_visita')
    gl_p = pronostico.get('goles_local')
    gv_p = pronostico.get('goles_visita')

    if gl_r is None or gv_r is None:
        return 0

    def res(gl, gv):
        if gl > gv: return 'L'
        if gl < gv: return 'V'
        return 'E'
    if gl_p == gl_r and gv_p == gv_r:
        return pts['exacto']
    if res(gl_p, gv_p) == res(gl_r, gv_r):
        return pts['resultado']
    return 0

def actualizar_puntos_partido(sb: Client, partido: dict):
    """Recalcula puntos de todos los pronósticos de un partido finalizado."""
    pid = partido.get('id')
    if not pid:
        return
    res   = sb.table('pronosticos').select('*').eq('partido_id', pid).execute()
    prons = res.data or []
    print(f'  Calculando {len(prons)} pronósticos para partido {pid}...')
    for pr in prons:
        puntos = calcular_puntos(partido, pr)
        sb.table('pronosticos').update({
            'puntos':    puntos,
            'calculado': True,
        }).eq('id', pr['id']).execute()

def actualizar_bonus_campeon(sb: Client):
    """Aplica bonus de 20 pts si el campeón ya se conoce."""
    cfg = sb.table('config').select('valor').eq('clave', 'campeon_real').execute()
    if not cfg.data or not cfg.data[0].get('valor'):
        return
    campeon_real = cfg.data[0]['valor'].strip()
    print(f'  Campeón real: {campeon_real}')
    res = sb.table('pronostico_campeon').select('*').execute()
    for c in (res.data or []):
        puntos = BONUS_CAMPEON if c.get('equipo') == campeon_real else 0
        sb.table('pronostico_campeon').update({'puntos': puntos}).eq('participante_id', c['participante_id']).execute()

# ============================================================
# FLUJO PRINCIPAL
# ============================================================
def cleanup_r16_falsos(sb: Client):
    """Elimina partidos de R16 creados por error, solo si no tienen picks."""
    falsos = ['Costa de Marfil', 'Francia', 'México']
    res = sb.table('partidos').select('id,equipo_local,equipo_visita').eq('fase', 'r16').execute()
    for p in (res.data or []):
        if p['equipo_local'] not in falsos and p['equipo_visita'] not in falsos:
            continue
        picks = sb.table('pronosticos').select('id').eq('partido_id', p['id']).execute()
        if picks.data:
            print(f'  SKIP cleanup id={p["id"]} ({p["equipo_local"]} vs {p["equipo_visita"]}): tiene {len(picks.data)} picks')
            continue
        sb.table('partidos').delete().eq('id', p['id']).execute()
        print(f'  CLEANUP: eliminado R16 falso id={p["id"]} ({p["equipo_local"]} vs {p["equipo_visita"]})')


def main():
    print(f'=== Quiniela Mundial 2026 — {datetime.now(timezone.utc).isoformat()} ===')

    sb = get_supabase()
    print('Conectado a Supabase ✓')

    # ── FIX TEMPORAL: corregir Bélgica 3-2 Senegal → 2-2 (90') y recalcular ──
    res = sb.table('partidos').select('*').eq('equipo_local', 'Bélgica').eq('equipo_visita', 'Senegal').execute()
    if res.data:
        p = res.data[0]
        if p.get('goles_local') == 3 and p.get('goles_visita') == 2:
            print('FIX: corrigiendo Bélgica 3-2 → 2-2 Senegal y recalculando puntos...')
            sb.table('partidos').update({
                'goles_local': 2, 'goles_visita': 2,
                'penales_local': 3, 'penales_visita': 2,
                'tipo_fin': 'tiempo_extra', 'fuente': 'manual'
            }).eq('id', p['id']).execute()
            p['goles_local'], p['goles_visita'] = 2, 2
            actualizar_puntos_partido(sb, p)
            print('FIX: completado.')
    # ── FIN FIX TEMPORAL ──

    now_utc   = datetime.now(timezone.utc)
    today     = now_utc.strftime('%Y%m%d')
    yesterday = (now_utc - timedelta(days=1)).strftime('%Y%m%d')

    # 1. Fetch ESPN hoy + ayer (partidos nocturnos que cruzan medianoche UTC)
    print('\n[1/5] Consultando ESPN (hoy + ayer)...')
    eventos_ayer  = fetch_espn(yesterday) if yesterday != today else []
    eventos_hoy   = fetch_espn()
    # Combinar evitando duplicados por id
    seen_ids = set()
    eventos_combinados = []
    for e in eventos_ayer + eventos_hoy:
        eid = e.get('id')
        if eid not in seen_ids:
            seen_ids.add(eid)
            eventos_combinados.append(e)
    partidos_hoy  = [parse_espn_event(e) for e in eventos_combinados]
    print(f'  {len([p for p in partidos_hoy if p])} partidos válidos (ayer+hoy).')

    # 2. Fetch ESPN fechas R16 futuras (para auto-generación de cruces)
    print('\n[2/5] Consultando ESPN (fechas R16 pendientes)...')
    partidos_r16 = []
    for fecha in FECHAS_R16:
        if fecha <= today:
            continue
        eventos = fetch_espn(fecha)
        parsed  = [parse_espn_event(e) for e in eventos]
        validos = [p for p in parsed if p]
        partidos_r16.extend(validos)
        if validos:
            print(f'  {fecha}: {len(validos)} partidos con equipos definidos.')

    # 3. Auto-generar cruces R16 cuando ESPN ya tiene los equipos confirmados.
    # SOLO usar partidos de fechas R16 — nunca partidos de R32 de hoy.
    print('\n[3/5] Verificando cruces R16...')
    generar_cruces_r16(sb, [p for p in partidos_r16 if p])

    # 4. Sincronizar resultados de hoy
    print('\n[4/5] Sincronizando resultados...')
    recien_finalizados = sync_from_espn(sb, partidos_hoy)
    print(f'  {len(recien_finalizados)} partidos recién finalizados.')

    # 5. Calcular puntos y bonus campeón
    print('\n[5/5] Calculando puntos...')
    for partido in recien_finalizados:
        actualizar_puntos_partido(sb, partido)
    actualizar_bonus_campeon(sb)

    print('\n=== Completado ✓ ===')

if __name__ == '__main__':
    main()
