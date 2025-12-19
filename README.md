# IC-Design
Project for OCDC pro Challenge

## Misc
OpenCores.org => Sammlung HardwareProjekte, qualität naja
AES + Hardware gibt es viele "Inspirationen" im Netz
web.archive.org

AES 128Bit
MD5 Pipelined auf OpenCored
Alternative zu AES PRESENT (Gerningere Chipfläche, aber geringere Security zu AES)
fpga4fun.com für SPI, EPP, PCI etc.


## How to start flow
1. In flow/Makefile den Pfad zum config.mk eintragen => DESIGN_CONFIG=./designs/ihp-sg13g2/../config.mk (kann auch so aufgerufen werden mit make DESIGN_CONFIG=./designs/ihp-sg13g2/../config.mk muss zwingend im /flow verzeichnis sein)
2. Create config.mk => Set Name, Nickname, DIE_AREA, berechne Werte von CORE_AREA aus DIE_AREA, Rest 1zu1 übernehmen
3. Create constraint.sdc => Beschreibt Stärke und GEschwindigkeit der Beinchen
4. Create pad.tlc => Beschreibt die Position und Größe der Pads -> Infos finden sich im LAYR Repo
5. GDS File gegenchecken gegen IHP Regeln => Gibt Python Files, die das machen

## Zum Spionieren / Hilfe
- https://github.com/IHP-GmbH/IHP-Open-DesignLib
- https://github.com/IHP-GmbH/IHP-Open-DesignLib/blob/main/ElemRV (gezeigter RISC-V)
    - https://github.com/IHP-GmbH/IHP-Open-DesignLib/blob/main/ElemRV/design_data/src/pad.tcl
- https://github.com/IHP-GmbH/TO_Nov2024/tree/main/i2c-gpio-expander
- https://github.com/KrzysztofHerman/Open-Padrings (Wir nutzen ein QFN24 Gehäuse)
- Krzysztof kann Reith auch immer nerven um uns zu helfen

## Missing
- DRC/SEALring etc. Skripte
- Pad Positions & Größe => GitHUb LAYR Issue open
- Python Scripte for gds IHP rule checking
