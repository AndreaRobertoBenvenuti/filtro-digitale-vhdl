# Progetto di Reti Logiche - Filtro Differenziale

Progetto finale del corso di Reti Logiche presso il Politecnico di Milano - Anno Accademico 2024/2025  
Voto 28/30
## 👥 Autori

- **Andrea Roberto Benvenuti** (Matricola: 10682511)
- **Francesco Barillari** (Matricola: 10858068)  

 
**Docente di riferimento**: Prof. William Fornaciari

## 📋 Descrizione del Progetto

Implementazione in VHDL di un componente hardware che applica un **filtro differenziale** a una sequenza di dati memorizzati. Il sistema legge byte dalla memoria, applica una convoluzione con coefficienti configurabili e scrive i risultati normalizzati in memoria.

### Funzionalità Principali

- **Lettura sequenziale** di K parole (byte) dalla memoria
- **Filtri differenziali** di ordine 3 e 5 con coefficienti configurabili
- **Normalizzazione** tramite approssimazione con shift aritmetici
- **Saturazione** automatica dei risultati nell'intervallo [-128, +127]
- **Gestione memoria** sincrona con protocollo completo (enable, write enable, address)

### Formula del Filtro

```
F'(i) = (1/n) × Σ[j=-l to +l] Cj × f[j+i]
```

dove:
- **Filtro ordine 3**: l=2, n=12, coefficienti [0, -1, 8, 0, -8, 1, 0]
- **Filtro ordine 5**: l=3, n=60, coefficienti [1, -9, 45, 0, -45, 9, -1]

## 📁 Struttura del Progetto

Il progetto è organizzato per essere importato direttamente in Xilinx Vivado:

```
CompleteProject/
└── PROGETTOFINALE.srcs/
    ├── sources_1/          # File sorgente VHDL
    │   └── new/
    │       └── project_reti_logiche.vhd
    ├── constrs_1/          # File di constraint (.xdc)
    ├── sim_1/              # Testbench e simulazioni
    │   └── new/
    │       ├── test2425.vhd           # TB esempio specifica
    │       ├── tb2425N.vhd            # TB saturazione negativa
    │       ├── tb2425P.vhd            # TB saturazione positiva
    │       ├── tb24250.vhd            # TB caso zero
    │       └── tb2425MK2.vhd          # Suite multi-scenario
    └── ...
```

### File Rilevanti

- **sources_1/new/project_reti_logiche.vhd**: Implementazione completa del filtro
- **sim_1/new/*.vhd**: 5 testbench per validazione completa
- I file sono accessibili in `CompleteProject/PROGETTOFINALE.srcs/`

## 🛠️ Requisiti

- **Xilinx Vivado WebPACK** (testato con versione 2019.1+)
- **FPGA Target**: Artix-7 xc7a200tfbg484-1 (configurabile)
- **Periodo di clock**: minimo 20 ns (50 MHz)
- Sistema operativo: Windows/Linux/macOS con supporto Vivado

## 📥 Come Importare il Progetto

1. Clona o scarica questo repository
2. Apri Xilinx Vivado
3. Seleziona **File → Open Project**
4. Naviga alla cartella `CompleteProject/` e seleziona il file `.xpr`
5. Il progetto verrà caricato con tutte le configurazioni

## 🔧 Utilizzo

### Simulazione Comportamentale

1. Nel Project Manager, espandi **Simulation Sources**
2. Seleziona uno dei testbench disponibili:
    - `test2425`: Esempio dalla specifica (24 elementi)
    - `tb2425N`: Test saturazione limite inferiore
    - `tb2425P`: Test saturazione limite superiore
    - `tb24250`: Test caso tutti zeri
    - `tb2425MK2`: Suite completa (6 scenari, K fino a 12000)
3. Clicca con il destro → **Set as Top**
4. **Run Behavioral Simulation**

### Synthesis e Implementation

1. **Run Synthesis** nel Flow Navigator
2. Attendi completamento (verifica Report Utilization)
3. **Run Implementation**
4. **Generate Bitstream** (opzionale)
5. Verifica **Design Timing Summary** (WNS > 0)

## 📊 Caratteristiche Implementative

### Architettura

- **FSM con 16 stati** per gestione completa del flusso
- **Finestra mobile di 56 bit** (7 byte) per convoluzione efficiente
- **Registro a scorrimento** per aggiornamento dati senza ricalcolo indirizzi
- **Pipeline ottimizzata** per lettura, calcolo e scrittura
- **Gestione automatica padding** (zeri ai bordi della sequenza)

### Risorse FPGA Utilizzate

| Risorsa | Utilizzati | Disponibili | Utilizzo |
|---------|-----------|-------------|----------|
| Slice LUTs | 496 | 134,600 | 0.37% |
| Slice Registers | 191 | 269,200 | 0.07% |
| F7 Muxes | 0 | 67,300 | 0.00% |
| Latch | 0 | - | 0 |

### Timing

- **WNS (Worst Negative Slack)**: 9.999 ns
- **Frequenza massima**: ~100 MHz (periodo ~10 ns)
- **Specifica richiesta**: 50 MHz (periodo 20 ns) ✅

## 🧪 Validazione e Test

Il progetto include 5 testbench che coprono:

1. ✅ Funzionamento nominale con dati ufficiali
2. ✅ Saturazione al limite inferiore (-128)
3. ✅ Saturazione al limite superiore (+127)
4. ✅ Gestione sequenze di zeri
5. ✅ Suite automatizzata multi-scenario (6 test, K variabile 7-12000)

**Risultato**: Tutti i test superati in pre-sintesi e post-sintesi

### Scenari Testati

- Sequenze da lunghezza minima (K=7) a molto lunghe (K=12000)
- Entrambi i filtri (ordine 3 e 5)
- Coefficienti standard e personalizzati
- Valori estremi: [-128, +127]
- Protocollo START/DONE
- Normalizzazione con correzione shift per negativi

## 📝 Interfaccia del Componente

```vhdl
entity project_reti_logiche is
    port (
        i_clk      : in  std_logic;                       -- Clock
        i_rst      : in  std_logic;                       -- Reset asincrono
        i_start    : in  std_logic;                       -- Start elaborazione
        i_add      : in  std_logic_vector(15 downto 0);  -- Indirizzo base
        o_done     : out std_logic;                       -- Fine elaborazione
        
        -- Interfaccia memoria
        o_mem_addr : out std_logic_vector(15 downto 0);  -- Indirizzo memoria
        i_mem_data : in  std_logic_vector(7 downto 0);   -- Dato letto
        o_mem_data : out std_logic_vector(7 downto 0);   -- Dato da scrivere
        o_mem_we   : out std_logic;                       -- Write enable
        o_mem_en   : out std_logic                        -- Memory enable
    );
end project_reti_logiche;
```

## 📖 Documentazione Completa

Per dettagli implementativi, scelte progettuali e analisi completa:
- **Relazione tecnica**: `RTLRelazione.pdf` (22 pagine)
- **Specifica del progetto**: `PFRL_Specifica_24_25_20250212_v3_5_1.pdf`
- **Regole di consegna**: `PFRL_Regole_24_25.pdf`

### Contenuti Relazione

1. **Introduzione**: Scopo e specifiche generali
2. **Architettura**: FSM, datapath, scelte progettuali
3. **Risultati Sperimentali**: Sintesi, timing, test coverage
4. **Conclusioni**: Validazione e considerazioni finali

## 🎓 Contesto Accademico

**Corso**: Progetto di Reti Logiche  
**Università**: Politecnico di Milano  
**Anno Accademico**: 2024/2025  
**Prova Finale**: Consegnato 18 agosto 2025

### Valutazione

- Componente sintetizzabile e simulabile in post-sintesi
- Codice VHDL di qualità professionale
- Relazione tecnica completa con analisi approfondita
- Copertura test esaustiva

## 📄 Licenza

Progetto accademico - Politecnico di Milano  
© 2025 Andrea Roberto Benvenuti, Francesco Barillari

---

## 🚀 Quick Start

```bash
# 1. Clona il repository
git clone <repository-url>

# 2. Apri Vivado e importa il progetto
# File → Open Project → CompleteProject/PROGETTOFINALE.xpr

# 3. Lancia una simulazione
# Set tb2425MK2 as top → Run Behavioral Simulation

# 4. Controlla i risultati
# Console: "TEST PASSATO (EXAMPLE)"
```

## 📞 Contatti

Per domande sul progetto:
- Andrea Roberto Benvenuti: andrea.benvenuti@mail.polimi.it
- Francesco Barillari: francesco.barillari@mail.polimi.it

---

**Note**: Il progetto completo è stato sviluppato seguendo rigorosamente le specifiche fornite. L'implementazione è ottimizzata per risorse, timing e correttezza funzionale. Tutti i file di configurazione, constraints e testbench sono inclusi per facilitare la riproduzione dei risultati.