#!/bin/bash
set -u

# Berechtigungen für Hintergrund-Start via Tastenkürzel
export DISPLAY=:0
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
export XAUTHORITY=$HOME/.Xauthority

# ==========================================
# KONFIGURATION
# ==========================================
API_KEY="DEIN_GROQ_API_KEY_HIER"
MODEL="openai/gpt-oss-120b" # Alternativ: llama-3.1-70b-versatile oder llama-3.1-8b-instant

if [ -z "$API_KEY" ] || [ "$API_KEY" = "DEIN_GROQ_API_KEY_HIER" ]; then
    play -q -n synth 0.3 sine 200 vol 0.3 >/dev/null 2>&1
    exit 1
fi

# 1. Aktives Fenster merken, BEVOR Zenity den Fokus übernimmt
ACTIVE_WIN=""
if command -v xdotool >/dev/null; then
    ACTIVE_WIN=$(xdotool getactivewindow 2>/dev/null || true)
fi

# 2. Markierten Text systemweit aus dem PRIMARY-Speicher holen
TEXT=""
if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] && command -v wl-paste >/dev/null; then
    TEXT=$(wl-paste --primary 2>/dev/null || wl-paste 2>/dev/null || true)
elif command -v xclip >/dev/null; then
    TEXT=$(xclip -o -selection primary 2>/dev/null || true)
    
    # Fallback, falls PRIMARY leer ist
    if [ -z "$TEXT" ] && command -v xdotool >/dev/null; then
        sleep 0.2
        xdotool key --clearmodifiers ctrl+c
        sleep 0.15
        TEXT=$(xclip -o -selection clipboard 2>/dev/null || true)
    fi
fi

if [ -z "$TEXT" ]; then
    play -q -n synth 0.3 sine 200 vol 0.3 >/dev/null 2>&1
    exit 1
fi

# 3. Visuelles Auswahlmenü (Zenity)
AKTION=$(zenity --list \
  --title="✨ KI Text-Assistent" \
  --text="Was soll mit dem Text passieren?" \
  --column="Aktion" \
  "Korrektur lesen (Rechtschreibung & Grammatik)" \
  "Besser formulieren (Flüssiger & klarer)" \
  "Formell umschreiben (Business / Sie-Form)" \
  "Informell umschreiben (Locker / Du-Form)" \
  "Ins Englische übersetzen" \
  "Zusammenfassen (Kurz & knapp)" \
  --width=420 --height=310 2>/dev/null || true)

if [ -z "$AKTION" ]; then
    exit 0
fi

# Arbeits-Ton
play -q -n synth 0.1 sine 800 vol 0.3 >/dev/null 2>&1

# 4. Prompt passend zur Auswahl setzen
PROMPT=""
case "$AKTION" in
    "Korrektur lesen (Rechtschreibung & Grammatik)") 
        PROMPT="Du bist ein präziser Lektor. Korrigiere nur Rechtschreibung, Grammatik und Zeichensetzung des folgenden Textes. Verändere Stil und Wortwahl so wenig wie möglich. Antworte AUSSCHLIESSLICH mit dem korrigierten Text, ohne Einleitung, ohne Erklärungen und ohne umschließende Anführungszeichen." 
        ;;
    "Besser formulieren (Flüssiger & klarer)") 
        PROMPT="Formuliere den folgenden Text stilistisch besser, flüssiger und klarer, ohne die Bedeutung zu verändern. Antworte AUSSCHLIESSLICH mit dem neuen Text, ohne Einleitung und ohne Anführungszeichen." 
        ;;
    "Formell umschreiben (Business / Sie-Form)") 
        PROMPT="Schreibe den folgenden Text in einem professionellen, höflichen und seriösen Business-Stil um (Sie-Form). Antworte AUSSCHLIESSLICH mit dem neuen Text, ohne Einleitung und ohne Anführungszeichen." 
        ;;
    "Informell umschreiben (Locker / Du-Form)") 
        PROMPT="Schreibe den folgenden Text in einem lockeren, freundlichen und natürlichen Tonfall um (Du-Form). Antworte AUSSCHLIESSLICH mit dem neuen Text, ohne Einleitung und ohne Anführungszeichen." 
        ;;
    "Ins Englische übersetzen") 
        PROMPT="Übersetze den folgenden Text natürlich und präzise ins Englische. Antworte AUSSCHLIESSLICH mit der Übersetzung, ohne Einleitung und ohne Anführungszeichen." 
        ;;
    "Zusammenfassen (Kurz & knapp)") 
        PROMPT="Fasse die Kernaussage des folgenden Textes in 2 bis 3 prägnanten Sätzen zusammen. Antworte AUSSCHLIESSLICH mit der Zusammenfassung, ohne Einleitung." 
        ;;
esac

# 5. JSON sicher erzeugen und an Groq-API senden
JSON_DATA=$(jq -n \
  --arg model "$MODEL" \
  --arg system "$PROMPT" \
  --arg user "$TEXT" \
  '{
    model: $model,
    temperature: 0.3,
    messages: [
      {"role": "system", "content": $system},
      {"role": "user", "content": $user}
    ]
  }')

RESPONSE=$(curl -s --max-time 30 -X POST "https://api.groq.com/openai/v1/chat/completions" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON_DATA")

RESULT=$(printf '%s' "$RESPONSE" | jq -r '.choices[0].message.content // empty')

if [ -z "$RESULT" ]; then
    play -q -n synth 0.3 sine 200 vol 0.3 >/dev/null 2>&1
    exit 1
fi

# 6. Ergebnis in die Zwischenablage kopieren
if [ "${XDG_SESSION_TYPE:-}" = "wayland" ] && command -v wl-copy >/dev/null; then
    printf '%s' "$RESULT" | wl-copy
elif command -v xclip >/dev/null; then
    printf '%s' "$RESULT" | xclip -selection clipboard
else
    play -q -n synth 0.3 sine 200 vol 0.3 >/dev/null 2>&1
    exit 1
fi

# 7. Ursprüngliches Fenster fokussieren und Text per xdotool einfügen
if command -v xdotool >/dev/null; then
    if [ -n "$ACTIVE_WIN" ]; then
        xdotool windowactivate "$ACTIVE_WIN" 2>/dev/null || true
    fi
    
    # Pause: Gibt X11 Zeit für den Fokuswechsel und dir Zeit, das Shortcut loszulassen
    sleep 0.5
    xdotool keyup ctrl alt super shift
    xdotool key --clearmodifiers ctrl+v
fi

# Erfolgs-Ton
play -q -n synth 0.1 sine 1000 synth 0.1 sine 1200 vol 0.3 >/dev/null 2>&1
