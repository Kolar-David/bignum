# Úvod

Tato knihovna implemetuje asymptoticky rychlé násobení, dělení, sčítání a odčítání dlouhých racionálních čísel v Haskellu.

Během vývoje jsem knihovnu pojal spíš jako vyzkoušení jednotlivých algoritmických technik, které se typicky používají, než jako knihovnu k použití v praxi.

Základním pilířem je rychlé násobení mnohočlenů založené na FFT nad konečným tělesem. To je následně použito k násobení dlouhých čísel.

Sčítání a odčítání zase využívají běžné školní algoritmy na sčítání a odčítání pod sebou.

Dělení stojí na newtonově metodě a knihovna k ní používá všechny tři výše zmíněné operace.

## Interní reprezentace čísel

Vstupní a výstupní čísla jsou reprezentována pomocí `String`. To ovšem není během práce s čísly uvnitř knihovny příliš praktické. Proto interně k jednotlivým operacím používá knihovna typ `BigNumber`.

V něm jsou čísla uložena ve tvaru $znamenko \cdot koeficient \cdot 10^exponent$.

Koeficient je uložený jako `String`, znaménko a exponent jako `Int`.

```
data BigNumber = BigNumber
    { sign :: Int
    , exponent :: Int
    , coefficient :: String
    } deriving (Eq, Show)
```

### Normalizovaný tvar

Uvnitř knihovny se typicky předpokládá, že je číslo v této reprezentaci navíc normalizované.

To znamená, že je číslo buď 0 a potom má tvar `BigNumber 1 0 "0"`, nebo je koeficient nenulový a jeho první a poslední číslice nejsou 0. Koeficient je tedy nejkratší možný.







