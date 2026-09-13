# Uživatelská dokumentace

Tato knihovna slouží k práci s racionálními čísly s vysokou přesností. Čísla přijímá i vrací jako textové řetězce, takže není omezena velikostí vestavěných číselných typů.

Knihovna podporuje základní aritmetické operace:

- sčítání
- násobení
- dělení se zadaným počtem desetinných míst výsledku

## Přehled funkcí knihovny

### `add :: String -> String -> Either String String`

Sečte dvě racionální čísla zadaná jako řetězce.

### `multiply :: String -> String -> Either String String`

Vynásobí dvě racionální čísla zadaná jako řetězce.

### `divide :: Int -> String -> String -> Either String String`

Vydělí první racionální číslo druhým. První argument určuje počet desetinných míst výsledku.

### `divide0 :: String -> String -> Either String String`

Provede dělení s výsledkem zaokrouhleným na 0 desetinných míst.

### `divide10 :: String -> String -> Either String String`

Provede dělení s výsledkem zaokrouhleným na 10 desetinných míst.

### `divide30 :: String -> String -> Either String String`

Provede dělení s výsledkem zaokrouhleným na 30 desetinných míst.

### `divide100 :: String -> String -> Either String String`

Provede dělení s výsledkem zaokrouhleným na 100 desetinných míst.


## Formát vstupních čísel

Vstupní čísla se zadávají jako `String` v desítkové soustavě. Podporována jsou celá i racionální čísla, kladná i záporná.

Platný vstup má jeden z následujících tvarů:

```
123
-123
123.456
-123.456
```

Záporné číslo může začínat znakem `-`. Kladná čísla se zapisují bez znaménka.

Celá i desetinná část musí obsahovat alespoň jednu číslici. Proto například následující zápisy nejsou platné:

```
.5
5.
-.5
```

Desetinný oddělovač je tečka `.`. Čárka není podporována.

Vstup může obsahovat počáteční nebo koncové nuly:

```
000123
00123.4500
-0005.000
0.000
```

Tyto nuly jsou v případě přebytečnosti při zpracování automaticky odstraněny.

Vstup nesmí obsahovat mezery ani jiné znaky. Neplatné jsou tak například:

```
 123
123 
1 000
+123
12,34
1e10
1.2e-3
12a3
```

## Formát výstupu funkcí

Všechny funkce knihovny používají návratový typ

```
Either String String
```

Typ `Either` umožňuje vrátit buď úspěšný výsledek, či popis chyby:

- `Right result` znamená, že operace proběhla úspěšně a `result` obsahuje výsledné číslo jako řetězec
-  `Left message` znamená, že operaci nebylo možné provést a `message` obsahuje popis chyby

Například:

```
add "12.5" "3.2"
-- Right "15.7"
```

Při neplatném vstupu:

```
add "12a" "3.2"
-- Left "Input contains a non-digit character."
```

U dělení může být chybou také dělení nulou:

```
divide 10 "5" "0"
-- Left "Division by zero!"
```

## Přesnost dělení

Pro zadanou přesnost $n$ lze výslednou hodnotu `divide` chápat tak, že se vezme přesný matematický výsledek a sleduje se prvních $n + 1$ cifer za desetinnou tečkou.
Prvních $n$ cifer se ponechá a podle následující cifry se rozhodne o zaokrouhlení:

- pokud je $(n + 1)$-ní cifra menší než $5$, ponechané cifry se nezmění,
- pokud je $5$ nebo větší, poslední ponechaná cifra se zvýší o $1$, případně s přenosem do předchozích cifer.

## Použití knihovny

Stačí vzít v `/src` složku `/BigNum` a soubor `BigNum.hs` a vložit je svém projektu do stejného adresáře.

Následně lze do svého programu knihovnu importovat pomocí:


```
import BigNum
```

## Omezení délky čísel

### Sčítání

U sčítání nemá knihovna stanovený žádný pevný limit. Praktickým omezením je pouze dostupná paměť a možnosti běhového prostředí.

### Násobení

U násobení je z důvodu použitého algoritmu délka čísel omezena.

Za délku čísla se zde považuje počet cifer od první po poslední nenulovou cifru včetně. Počáteční a koncové nuly ani poloha desetinné tečky tedy velikost čísla pro tento limit nezvětšují.

Pro dvě násobená čísla musí součet těchto délek být nejvýše

$$2^{26}$$

### Dělení

Dělení interně opakovaně používá operaci násobení uvedenou výše, a proto je omezeno velikostí největšího součinu, který během výpočtu vznikne.

Jako bezpečnou praktickou hranici lze použít $2^{22}$ cifer. Součet

- počtu relevantních cifer čitatele,
- počtu relevantních cifer jmenovatele,
- počtu cifer výsledku před desetinnou tečkou,
- a požadovaného počtu desetinných míst

by tedy neměl překročit

$$2^{22}$$

Tuto hranici lze nicméně teoreticky i překročit, nicméně nelze garantovat, že výpočet proběhne. Pevnou hranicí je limit jako u násobení, tedy $2^{26}$.



