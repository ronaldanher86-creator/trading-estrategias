# Cómo conectar TradingView Desktop (MCP / CDP) en este equipo

TradingView Desktop en este equipo está instalado como paquete **MSIX** (`TradingView.Desktop_n534cwy3pjxzj`, `SignatureKind: Developer` — se bajó directo de tradingview.com, no de Microsoft Store, pero Windows lo empaqueta igual como MSIX; **no existe versión `.exe` tradicional**, tradingview.com solo ofrece el `.msix` para Windows).

## El problema
Las apps MSIX corren en un contenedor (AppContainer) que bloquea la exposición del puerto de depuración remota de Chrome (CDP, usado por el MCP de TradingView para leer/controlar el chart). Cualquier intento de lanzar el `.exe` directamente — ya sea desde su carpeta real (`C:\Program Files\WindowsApps\...`, bloqueada para ejecución directa) o desde una copia local fuera de su contenedor (lo que intenta el MCP automáticamente) — falla: o no abre el puerto, o la app se cierra sola casi de inmediato (código de salida 9) porque pierde su identidad de paquete al ejecutarse fuera de su contenedor.

## La solución que funcionó
1. Activar el **Modo de desarrollador** de Windows: `Configuración → Privacidad y seguridad → Para desarrolladores` (o abrir directo con `Start-Process "ms-settings:developers"`). Requiere que el usuario lo haga desde su sesión (no se puede activar desde una sesión de automatización sin interacción).
2. Cerrar cualquier instancia de TradingView que esté corriendo.
3. Ejecutar, desde una **PowerShell normal** (no hace falta administrador) **del usuario, en su sesión interactiva** (el cmdlet pide una confirmación que una sesión no interactiva no puede aceptar — por eso esto no se puede automatizar desde una sesión de agente/CI):
   ```powershell
   Invoke-CommandInDesktopPackage -PackageFamilyName "TradingView.Desktop_n534cwy3pjxzj" -AppId "TradingView.Desktop" -Command "C:\Program Files\WindowsApps\TradingView.Desktop_3.4.1.8194_x64__n534cwy3pjxzj\TradingView.exe" -Args "--remote-debugging-port=9222" -PreventBreakaway
   ```
   Notas sobre los parámetros:
   - `-Command` necesita la **ruta completa** al `TradingView.exe` real (dentro de `WindowsApps`) — pasar solo el nombre relativo (`"TradingView.exe"`) falla con "Windows no puede encontrar el archivo".
   - Este cmdlet ejecuta el proceso **dentro del contenedor/identidad real del paquete instalado**, a diferencia de una copia local — por eso sí funciona, mientras que copiar el `.exe` fuera de su carpeta no.
   - Ajustar la versión (`3.4.1.8194_x64__n534cwy3pjxzj`) si la app se actualiza; verificar con `Get-AppxPackage -Name "*TradingView*"`.
4. Verificar la conexión desde el MCP con la herramienta `tv_health_check` — debería devolver `"cdp_connected": true`.

## Qué NO funcionó (para no reintentarlo si esto se rompe de nuevo)
- `tv_launch` del MCP (copia el exe a `AppData\Local\tradingview-mcp\...` y lo ejecuta directo): se queda corriendo sin exponer el puerto, o se cierra con código 9, dependiendo del estado del sistema. No es confiable con esta versión de la app.
- Exención de aislamiento de red (`CheckNetIsolation.exe LoopbackExempt`): no resolvió el problema por sí sola (y en un momento pareció coincidir con que la copia local empezara a fallar más, aunque no se confirmó causalidad).
- Registrar la copia local como paquete propio (`Add-AppxPackage -Register`): no se llegó a probar, `Invoke-CommandInDesktopPackage` sobre el paquete YA instalado resultó más directo y sí funcionó.
- Antivirus / Windows Defender: descartado, sin detecciones relacionadas.

## Si hace falta relanzar en una sesión futura
Repetir el paso 3 (con TradingView cerrado primero). El Modo de Desarrollador, una vez activado, queda activado permanentemente — no hace falta repetir el paso 1 salvo que se desactive manualmente.
