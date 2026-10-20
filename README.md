# TextAI

TextAI ist ein leichtgewichtiges Bash-Skript für Linux-Desktops, das Textverarbeitung über die Groq-API direkt in den Arbeitsfluss integriert. 

Es ermöglicht, markierten Text in beliebigen Anwendungen per Tastendruck an ein Sprachmodell zu senden (z. B. für Korrekturen, Übersetzungen oder Umformulierungen) und das Ergebnis automatisch an der Ursprungsstelle einzufügen. Das Skript ist primär für X11-Umgebungen ausgelegt, greift aber unter Wayland auf `wl-clipboard` zurück.

## Funktionen
- **Universelle Nutzbarkeit:** Arbeitet unabhängig vom verwendeten Programm (z. B. Browser, Office-Anwendungen, E-Mail-Clients).
- **Robuste Zwischenablage:** Greift nach Möglichkeit direkt auf den Linux `PRIMARY`-Speicher zu, um Konflikte mit manuellen Kopierbefehlen zu vermeiden.
- **Fokus-Management:** Speichert die ID des aktiven Fensters, um nach der Menüauswahl den Text zuverlässig am korrekten Ort einzufügen.
- **Niedrige Latenz:** Nutzt die Groq-API für eine zügige Textverarbeitung im Hintergrund.

## Voraussetzungen
Das Skript setzt auf etablierte Linux-Kommandozeilenwerkzeuge. Unter Debian/Ubuntu-basierten Systemen lassen sich diese wie folgt installieren:

```bash
sudo apt install xdotool xclip zenity jq sox curl
