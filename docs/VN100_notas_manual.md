# VN-100: notas del manual y de las pruebas

Fuente: *VN-100 User Manual* UM001 v2.05 (VectorNav), **firmware 2.0.0.0**. No se incluye el PDF
en el repo porque es público y el manual lleva «© 2014 VectorNav Technologies, LLC – All rights
reserved»; se baja de vectornav.com (Resources → User Manuals) o del wiki
<https://mpt-internal.uni-hohenheim.de/doku.php?id=sensors:vn_100>.

**Aviso de versión:** nuestro sensor es un **VN-100T-CR, firmware 3.1.0.0, hardware rev. 7**. El
manual es de otra generación de firmware, así que lo que sigue vale como guía, no como garantía.
Lo medido en nuestro sensor está marcado como *medido*.

## Tasas internas (p. 19-20)

| Subsistema | Tasa por defecto | Qué da |
|---|---|---|
| IMU | **800 Hz** | acelerómetro y giróscopo calibrados |
| NavState | **400 Hz** | actitud (yaw/pitch/roll, cuaternión, DCM), delta ángulo, delta velocidad |
| NavFilter (VPE, Kalman) | **200 Hz** | filtros de actitud, incertidumbres, HSI |

Consecuencia: la orientación se actualiza como mucho a **400 Hz**. Un mensaje a 800 Hz solo trae
datos nuevos de IMU; la actitud va repetida en la mitad. (Corrige una afirmación anterior que
decía que la orientación se calcula a 800 Hz.)

## Salida binaria (registros 75-77, p. 37)

- `RateDivisor` es divisor de la tasa IMU (800 Hz nominal): 50 Hz → 16, 100 → 8, 200 → 4, 400 → 2,
  800 → 1.
- `AsyncMode`: 0 ninguno, 1 puerto serie 1, 2 puerto serie 2, **3 ambos**.

## Baudios (registro 5, p. 65)

- Admitidos: 9600, 19200, 38400, 57600, 115200, 128000, 230400, 460800, **921600** (máximo).
- El registro lleva un parámetro **opcional** con el puerto serie. Sin él, cambia el baudrate del
  puerto activo. El puerto 2 no se toca.

## Error 12 «Insufficient Baud Rate»

Tabla de errores: *«The baud rate is not high enough to support the requested asynchronous data
output at the requested data rate.»* Es el que dio el sensor con `asyncMode: 3` (*medido*).

Explicación (deducida, no confirmada por el manual): con `asyncMode: 3` el sensor valida el
ancho de banda también contra el puerto 2, que sigue a 115200 aunque subamos el puerto 1. Por
eso con 3 nada pasaba de 20 Hz a ningún baudrate, y con `asyncMode: 1` el límite sí seguía al
baudrate.

## Cuánto ocupa un mensaje

Sumando los campos del grupo común que usa el VN-100 (TimeStartup 8, TimeSyncIn 8, YPR 12,
cuaternión 16, velocidad angular 12, aceleración 12, IMU sin compensar 24, mag/presión/temp 20,
delta theta 28, VpeStatus 2, SyncInCnt 4) y la cabecera y CRC, salen **~150 bytes** (*calculado*
a partir de las tablas del manual, no medido).

Con eso, los resultados medidos (driver `dawonn`, todos los campos comunes, 10 bits por byte):

| Baudios | 20 Hz | 50 Hz | 100 Hz | 200 Hz | 400 Hz |
|---|---|---|---|---|---|
| 115200 | 26 % ok | 66 % **falla** | | | |
| 230400 | | 33 % ok | 66 % **falla** | | |
| 460800 | | | 33 % ok | 66 % **falla** | |
| 921600 | | | | 33 % ok | 66 % **falla** |

(% = ocupación del puerto.) El sensor acepta hasta ~33 % y rechaza ~66 %; el umbral exacto está
entre medias y no lo sé. Para subir de 200 Hz hay que pedir menos campos: p. ej. solo cuaternión,
velocidad angular y aceleración son ~50 bytes, y 400 Hz a 921600 baudios ocuparía ~22 %.

## Diagnóstico en el propio sensor

El manual (p. 79-80) muestra un volcado de diagnóstico con *Serial 1/2 TX Bandwidth Usage* y
*Serial Insufficient Bandwidth*: sirve para ver la ocupación real del puerto en vez de calcularla.
No se ha usado todavía.

## La captura de «frecuencias por subsistema»

Compatible con el manual en lo comprobado: IMU 800 Hz, actitud 400 Hz, filtro 200 Hz. Los anchos
de banda de sensores (giróscopo 265 Hz, acelerómetro 230 Hz, etc.) no se han comprobado. La
página del wiki de Hohenheim es del **VN-100 Rugged** de generación anterior (salida máxima
200 Hz) y no aplica a nuestro VN-100T-CR.
