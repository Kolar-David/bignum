# Úvodní informace

Tato knihovna implemetuje asymptoticky rychlé násobení, dělení a sčítání dlouhých racionálních čísel v Haskellu. Tato čísla jsou zadána jako `String` reprezentující jejich desetinný rozvoj
a knihovna jako výsledek vrací `Either String String`.

Během vývoje jsem knihovnu pojal spíš jako vyzkoušení jednotlivých algoritmických technik, které se typicky používají, než jako knihovnu k použití v praxi.
To dokládá i rychlost, která není tak vysoká, jak jsem si od toho původně sliboval.

Základním pilířem je rychlé násobení mnohočlenů s celočíselnými koeficienty založené na FFT nad konečným tělesem. To je následně použito k násobení dlouhých čísel.

Sčítání a odčítání zase využívají běžné školní algoritmy na sčítání a odčítání pod sebou. Využívají též operaci porovnávání.

Dělení stojí na newtonově metodě a knihovna k ní používá všechny tři výše zmíněné operace, plus několik pomocných operací navíc. Jsou to například negace, absolutní hodnota,
zaokrouhlení čísla na danou přenost a porovnávání čísel.

## Interní reprezentace čísel

Vstupní a výstupní čísla jsou reprezentována pomocí `String`. To ovšem není během práce s čísly uvnitř knihovny příliš praktické. Proto interně k jednotlivým operacím používá knihovna typ `BigNumber`.

V něm jsou čísla uložena ve tvaru $znamenko \cdot koeficient \cdot 10^{exponent}$.

Koeficient je uložený jako `String`, znaménko a exponent jako `Int`.

```
data BigNumber = BigNumber
    { sign :: Int
    , exponent :: Int
    , coefficient :: String
    } deriving (Eq, Show)
```


### Normalizovaný tvar `BigNumber`

Uvnitř knihovny se typicky předpokládá, že je číslo v této reprezentaci navíc normalizované.

To znamená, že je číslo buď 0 a potom má tvar `BigNumber 1 0 "0"`,
nebo je koeficient nenulový a jeho první a poslední číslice nejsou 0. Koeficient je tedy nejkratší možný.

### Další použité reprezentace čísel

Dále knihovna používá interně další typy, jako je například `Int`. Používá ale i `NumberType`, což je alias `Integer`.
Použití neomezeného typu se může jevit paradoxně, nicméně jsem jej použil jen tam, kde jsem chtěl zabránit přetečení, a stačilo by použít nějaký typ,
který podporuje čísla délky slova násobeného nějakou konstantou. 

## Použité algoritmy

V této sekci stručně vysvětlím použité algoritmy a volby jednotlivých konstant.

### Násobení mnohočlenů s celočíselnými koeficienty

K násobení mnohočlenů je použito FFT nad konečným tělesem, jak je popsáno například [v této kapitole](https://pruvodce.ucw.cz/static/pruvodce.pdf#s17.5).

Použil jsem  lepší parametry, než jsou uvedeny v kapitole, na níž se odkazuji:

- Prvočíslo určující konečné těleso $p = 18446744069414584321$
- Maximální délka mnohočlenu k vyhodnocení $n = 2^{32}$
- Primitivní $n$-tá odmocnina z jedničky $\omega = 1753635133440165772$

### Násobení čísel

Násobení racionálních čísel se převede na násobení celých nezáporných čísel.

Nejprve dojde k převodu násobených čísel do dříve uvedeného normalizovaného formátu $znamenko \cdot koeficient \cdot 10^{exponent}$.
Následně se vynásobí koeficienty a z tohoto součinu, plus součtu exponentů a součinu znamének lze sestavit výsledek.

### Násobení celých nezáporných čísel

Nejprve se převede násobení čísel na násobení mnohočlenů.
Každé číslo se rozdělí na souvislé bloky o délce $b = 6$ a ty se prohlásí za koeficienty nově vzniklých mnohočlenů.

Tyto mnohočleny se vynásobí pomocí FFT. Výsledný mnohočlen se následně vyhodnotí v bodě $10^b = 10^6$.

Z povahy zafixování konečného tělesa během FFT je omezený maximální počet cifer výsledku. Zároveň nesmí v žádném koeficientu dojít k přetečení, tedy žádný koeficient nesmí mít výsledek větší než $p$.

Toto splňuje například počet cifer $2^{26} = 67 108 864$. Zřejmě splňuje, že je menší, než celkový počet koeficientů v FFT.

Též nedojde k přetečení, maximální hodnotu koeficientu lze odhadnout zhora jako:

$(10^6 - 1)^2 \cdot 2^{26} / 6 < 18446744069414584321$

### Dělení čísel

Nechť má algoritmus má spočítat $a/b$.

Nejprve obě čísla převede na nezáporná a znaménka použije na konci k určení znaménka výsledku.

Dále pomocí Newtonovo metody algoritmus spočítá $1/b$ a následně jej vynásobí $a$. Protože chceme dělení na dostatečnou přesnost, počítá algoritmus rovnou míru chyby pro $a/b$, a Newtonova metoda iteruje tak dlouho, dokud se nedostane na dostatečnou přenost.

Pokud je $x_k$ aproximace $1/b$ v iteraci $k$, tak se aproximované hodnota v následující iteraci spočte jako:

$x_{k+1} = x_k \cdot (2 - bx_k)$

Po spočtení výsledku se výsledek zaokrouhlí podle požadované přesnosti.

Kvůli použitému násobení je i u dělení omezena délka čísel. Konkrétně nesmí žádný interní součin překročit limit násobení.

#### Kontrola chyby

Program má kontrolovat, zda je rozdíl mezi $a/b$ a aktuální aproximací menší než daná přenost $\varepsilon$.
Pokud chceme přesnost na $j$ míst, tak algoritmus nastaví $\varepsilon = 10^{-j-5}$.

Má platit:

$|ax_k - a/b| \le \varepsilon$

To lze upravit na:

$a \cdot |b \cdot x_k - 1| \le \varepsilon \cdot b$

Takovou kontrolu lze provést pomocí porovnání, násobení a sčítaní.

#### Počáteční aproximace 

Je nutné zvolit dobrou počáteční aproximaci $x_1$, aby aproximace konvergovala ke správné hodnotě.

Pokud si vyjádřím chybu v k-tém kroku během hledání chyby jako:

$e_k = 1 - b \cdot x_k$,

tak lze dosazením Newtonova vzorce pro $x_{k+1}$ do $e_{k+1}$ s vhodnými úpravami dokázat, že:

$e_{k+1} =  e_{k}^2$

Pokud se tedy $x_1$ zvolí tak, že je chyba na začátku ostře mezi -1 a 1, výsledek konverguje ke správné hodnotě a správný počet cifer se přibližně po každé iteraci zdvojnásobí.

Algoritmus toto dělá tak, že vezme několik prvních cifer koeficientu čísla v normalizované reprezentaci, a získá pomocí běžného dělení malých čísel první odhad.

Číslo $b$ se dá zapsat jako $b = (p10^{L-t} + r) \cdot 10^e$, kde $e$ je exponent po normalizaci,
$L$ délka koeficientu po normalizaci a $t$ počet cifer z koeficientu, co si vezmeme pro počáteční odhad.

Na základě toho s pomocí $p$ lze vytvořit následující počáteční aproximaci.

Nejprve se zavede $s = t + konstantaZvetsujiciPresnost$

V modulu je jako $konstantaZvetsujiciPresnost$ použitá hodnota `initialReciprocalPrecision`,
ale není to provázané se zbylým použitím této konstanty a šlo by tady použít i jinou hodnotu.

Výsledný odhad je 

$$\lfloor 10^s / p \rfloor 10^{-(e + L - t + s)}$$.

Pro tento odhad platí, že leží nezávisle na volbě $b$ chyba v prvním kroku mezi $-c$ a $c$, kde $c$ je kladná konstanta menší než 1, což jsme potřebovali.

#### Postupné zpřesňování

Kód obsahuje částečnou optimalizaci - využívá toho, že se přesnost po každém kroku zdvojnásobí, takže některé cifry aproximace nejsou potřeba.
Omezuje proto na začátku délku koeficientu v normalizovaném tvaru na 12 cifer a po každé iteraci tuto délku zdvojnásobí.
Je nicméně nutné zmínit, že pracovní přesnost $a$ a $b$ zůstává v průběhu celého algoritmu stejná,
takže je optimalizace jen částečná a hodí se především v momentu, kdy je celkový počet požadovaných cifer výsledku výrazně větší, než součty délek koeficientů těchto čísel. 

### Časové složitosti jednotlivých algoritmů

Předpokládejme, že během násobení čísel dělíme čísla na bloky délky $O(\log n)$ a ne 6.
Potom mají použité algoritmy vůči součtu délek vstupu a výstupu $n$ následující časové složitosti:

| Operace | Časová složitost |
|---|---|
| Sčítání | $O(n)$ |
| Násobení | $O(n)$ |
| Dělení | $O(n \log n)$ |

# Struktura kódu

Veškerý zdrojový kód se nachází ve složce `/src/BigNum`.
V této sekci rozeberu obsah a roli jednotlivých souborů.

```
BigNum
├── Addition.hs
├── Comparison.hs
├── Constants.hs
├── Division.hs
├── NumberMultiplication.hs
├── Parser.hs
├── PolynomialMultiplication.hs
├── Rounding.hs
└── Types.hs
```

## `Constants.hs`

Tento soubor obsahuje klíčové konstanty, které se týkají FFT, násobení a dělení a které používají další části programu.



## `Types.hs`
 
Zde je zaveden alias `NumberType` a typ `BigNumber`.



## `PolynomialMultiplication.hs`

Tento soubor má na starost násobení mnohočlenů s celočíselnými koeficienty.

### `multiply :: [NumberType] -> [NumberType] -> [NumberType]`

Toto je hlavní metoda, která přijme dva mnohočleny s celočíselnými koeficienty a vynásobí je.
Pokud dojde k nepředpokládané události, vyhodí výjimku.

### `fft :: [NumberType] -> NumberType -> NumberType -> [NumberType]`

Tato metoda implementuje FFT a je využita v `multiply`.

### `moduloPower :: NumberType -> NumberType -> NumberType -> NumberType`

Spočítá mocninu modulo pomocí rychlého binárního umocňování.

### `nextPowerOfTwo :: NumberType -> NumberType`

Vrátí nejmenší mocninu dvojky větší nebo rovnou zadanému číslu. Hledáme s tím vhodnou délku polynomu, který se předá FFT.

### `extendWithZeroes :: [NumberType] -> NumberType -> [NumberType]`

Doplní seznam nulami na požadovanou délku. Hodí se v FFT, kde chceme pracovat s polynomy o délce odpovídající mocnině dvojky.

### `splitEvenOdd :: [NumberType] -> ([NumberType], [NumberType])`

Pomocná metoda v FFT - rozdělí seznam na prvky na sudých a lichých pozicích.

### `getCorrectW :: NumberType -> NumberType -> NumberType -> NumberType`

Odvodí správnou mocninu primitivní odmocniny z jedničky pro požadovanou délku mnohočlenu v FFT.




## `NumberMultiplication.hs`

Tento modul už implementuje násobení dvou čísel a obsahuje veřejnou metodu `multiply`.
Mimo to ale poskytuje i další důležitou metodu `multiplyBigNumbers` pracující přímo s `BigNumber` typy,
kterou používají další části knihovny (dělení), aby nemuselo docházet ke zbytečným převodům na `String` a zpátky.

### `multiply :: String -> String -> Either String String`

Veřejná funkce pro násobení dvou racionálních čísel zadaných jako `String`.

### `multiplyBigNumbers :: BigNumber -> BigNumber -> BigNumber`

Vynásobí dvě čísla typu `BigNumber`, vynásobí jejich koeficienty a sečte exponenty.

### `unsignedIntegerMultiplication :: String -> String -> String`

Vynásobí dvě nezáporná celá čísla uložená jako `String` pomocí násobení mnohočlenů.

### `splitNumberToBlocks :: String -> NumberType -> [NumberType]`

Rozdělí `String` reprezentující celé nezáporné číslo na bloky zadané velikosti, počínaje od nejméně významných cifer.

### `polynomialToNumber :: [NumberType] -> NumberType -> String`

Převede koeficienty výsledného mnohočlenu zpět na desetinný `String`.

### `polynomialToNumberHelper :: [NumberType] -> NumberType -> NumberType -> NumberType -> String`

Pomocná funkce pro převod mnohočlenu na číslo, která zpracovává přenosy mezi bloky.

### `padLeft :: Int -> Char -> String -> String`

Doplní `String` zleva zadaným znakem na požadovanou délku.




## `Parser.hs`

Tento modul má za úkol řešit převod čísel do formátu `BigNumber` a zase zpět a je využíván všemi implementacemi aritmetických operací,
které na něj delegují ošetření vstupu a následné vytvoření výstupu ve správném formátu.

### `parseBigNumber :: String -> Either String BigNumber`

Převede číslo ve tvaru `String` na interní reprezentaci `BigNumber`.
Zároveň detekuje případné chyby v zápisech čísel. Ty vrací jako zprávu v `Left`.

Tento modul má též na starost normalizaci `BigNumber` čísel do formátu popsaného dříve.

### `bigNumberToString :: BigNumber -> String`

Převede `BigNumber` zpět na běžný `String`.

### `normalizeBigNumber :: BigNumber -> BigNumber`

Převede číslo do normalizovaného tvaru.

### `parseWithoutSign :: Int -> String -> Either String BigNumber`

Zpracuje číslo bez znaménka a vytvoří odpovídající `BigNumber`.

### `normalizedBigNumberToString :: BigNumber -> String`

Převede již normalizovaný `BigNumber` na `String`.

### `removeLeadingZeroes :: String -> String`

Odstraní počáteční nuly, přičemž zachová `0` pro nulovou hodnotu.

### `removeTrailingZeroes :: String -> (String, Int)`

Odstraní koncové nuly a vrátí také jejich počet.





## `Addition.hs`

Tento modul implentuje veřejnou metodu `add` sloužící k součtu racionálních čísel.
Využívá toho, že lze každý součet racionálních čísel převést na součet dvou nezáporných čísel, nebo na rozdíl dvou nezáporných čísel, z nichž menšenec je větší.
Tento součet a rozdíl je realizován pomocí běžných školních algoritmů na sčítání a odčítání pod sebou.

Kromě toho tento modul obsahuje operace pracující přímo s `BigNumber`, které používají další části knihovny, přesněji dělení.
Jedná se o metody součtu a rozdílu (tentorkát libovolných) dvou čísel, negaci a absolutní hodnotu.

### `add :: String -> String -> Either String String`

Veřejná funkce pro sečtení dvou racionálních čísel zadaných jako `String`.
Parsuje čísla pomocí `Parse.hs` a zavolá `addBigNumbers`.

### `addBigNumbers :: BigNumber -> BigNumber -> BigNumber`

Sečte dvě hodnoty `BigNumber` po zarovnání exponentů a zohlednění znamének.
Převede problém na odčítání nebo sčítání.
Ke svému fungování potřebuje funkci na porovnávání čísel, která se nachází v modulu `Comparison.hs`.

### `subtractBigNumbers :: BigNumber -> BigNumber -> BigNumber`

Odečte druhé číslo od prvního pomocí negace a sčítání.

### `absoluteBigNumber :: BigNumber -> BigNumber`

Vrátí absolutní hodnotu čísla.

### `negateBigNumber :: BigNumber -> BigNumber`

Změní znaménko čísla, přičemž nulu ponechá v normalizovaném tvaru.

### `integerAddition :: String -> String -> String`

Sečte dvě nezáporná celá čísla uložená  `String` pomocí sčítání pod sebou.

### `integerSubtraction :: String -> String -> String`

Odečte druhé nezáporné celé číslo od prvního pomocí odčítání pod sebou. Předpokládá, že první je větší nebo rovno druhému.



## `Comparison.hs`

Tento modul implementuje porovnávání čísel a je využíván během dělení a sčítání.

### `compareBigNumbers :: BigNumber -> BigNumber -> Ordering`

Porovná dvě čísla včetně znamének. Nejprve řeší znaménka a pak porovná jejich absolutní hodnoty.

### `compareAbsoluteBigNumbers :: BigNumber -> BigNumber -> Ordering`

Porovná absolutní hodnoty dvou `BigNumber`. Nejprve porovná jejich řád a při shodě doplní koeficienty nulami a porovná je lexikograficky.

### `compareUnsignedIntegers :: String -> String -> Ordering`

Porovná dvě nezáporná celá čísla uložená jako řetězce. Nejprve podle délky a při shodné délce lexikograficky.




## `Rounding.hs`

Tento modul slouží k ořezávání a zaokrouhlování čísel. Je používán modulem `Division.hs`, kde ořezávání slouží k postupnému zpřesňování čísel a zaokrouhlování k finální úpravě výsledku.

### `roundToDecimalPlaces :: Int -> BigNumber -> Either String BigNumber`

Zaokrouhlí číslo na zadaný počet desetinných míst. Podle první odstraněné cifry případně zvýší ponechaný koeficient o jedna. K zaokrouhlení dojde tehdy, když je daná cifra $\ge 5$.

### `truncateToSignificantDigits :: Int -> BigNumber -> BigNumber`

Ořízne číslo na zadaný počet významných cifer. Odstraněné cifry kompenzuje zvýšením exponentu.

### `shouldRoundUp :: String -> Bool`

Určí podle první odstraněné cifry, zda se má číslo zaokrouhlit nahoru. K zaokrouhlení dojde tehdy, když je daná cifra $\ge 5$.




## `Division.hs`

Tento modul pomocí algoritmu založeného na Newtonově metodě provádí dělení dvou čísel.

### `divide :: Int -> String -> String -> Either String String`

Veřejná funkce pro dělení dvou racionálních čísel.

### `divideWithAbsoluteTolerance :: BigNumber -> BigNumber -> BigNumber -> Either String BigNumber`

Provede dělení s požadovanou chybou $\varepsilon$. Newtonovou metodou aproximuje převrácenou hodnotu jmenovatele a iteruje, dokud odhad chyby podílu nedostane pod zadané $\varepsilon$.

### `initialReciprocalApproximation :: BigNumber -> BigNumber`

Vytvoří počáteční aproximaci převrácené hodnoty z několika prvních cifer jmenovatele a odpovídajícího exponentu.

### `decimalPlacesToTolerance :: Int -> BigNumber`

Převede požadovaný počet desetinných míst výstupu na dostatečně malé $\varepsilon$.

### `divide0`, `divide10`, `divide30`, `divide100`

Veřejné varianty `divide` s pevně nastaveným počtem desetinných míst 0, 10, 30 a 100.


# Jednotkové testy

Součástí tohoto repozitáře jsou jednoduché testy ověřující funkčnost kódu.
Ty testují správnost veřejných numerických operací. Implementace testů se nachází v souboru `src/Tests.hs`.

Program je kvůli rychlosti nutné zkompilovat, což lze například provést spuštěním skriptu `compile_tests.sh`.

## Seed

Seed lze zadat jako argument programu. Pokud zadán není, použije se výchozí hodnota `314159265`.

## Test sčítání

Vygenerují se dvě náhodná krátká racionální čísla se znaménkem. Výsledek funkce `add` se převede na typ `Rational` a porovná se se součtem obou vstupů spočítaným přímo pomocí operace `(+)` nad `Rational`.

## Test krátkého násobení

Vygenerují se dvě náhodná racionální čísla se znaménkem. Výsledek funkce `multiply` se převede na `Rational` a porovná se s přesným součinem vstupních hodnot vypočteným pomocí `(*)` nad `Rational`.

## Test dlouhého celočíselného násobení

Vygenerují se dvě dlouhá nezáporná celá čísla se zadaným počtem cifer. Výsledek `multiply` se převede na vestavěný typ `Integer` a porovná se s přesným součinem stejných vstupů vypočteným pomocí násobení `Integer`.

Test je spouštěn jak pro čísla s tisíci ciframi, tak pro výrazně větší vstupy, aby se otestovala část implementace využívající FFT nad konečným tělesem.

## Test dělení

Vygenerují se dvě náhodná racionální čísla `a` a `b`. Nejprve se pomocí knihovny spočítá jejich součin (tady již předpokládáme, že operace násobení prošla předchozími testy)

$s = a \cdot b$.

Poté se provede

$s / b$

s dostatečným počtem desetinných míst. Výsledek musí být přesně roven původnímu číslu $a$.

## Test dělení se zadanou přesností

Opět se nejprve vytvoří pomocí knihovny součin dvou náhodných čísel

$s = a \cdot b$.

Následně se počítá

$s / b$,

takže výsledkem je $a$. Tentokrát však může být požadovaný počet desetinných míst menší než počet desetinných míst čísla $a$.

Referenční výsledek se proto získá přesným zaokrouhlením $a$ pomocí typu `Rational`. Výsledek funkce `divide` se následně porovná s touto referenční zaokrouhlenou hodnotou.

## Spuštění všech testů

Program postupně spustí:

- 1000 testů sčítání krátkých racionálních čísel,
- 500 testů násobení krátkých racionálních čísel,
- 100 násobení dvojic 1000ciferných celých čísel,
- 10 násobení dvojic 100000ciferných celých čísel,
- 20 testů dělení větších racionálních čísel,
- 100 testů dělení s přesností 5 desetinných míst,
- 10 rozsáhlých testů dělení s přesností 4000 desetinných míst.

Pokud všechny testy proběhnou bez chyby, program vypíše `All tests passed!`.

