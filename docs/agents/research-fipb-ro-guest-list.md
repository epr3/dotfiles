# Research: fipb.ro guest list, every day

**Date:** 2026-08-28 · **Question:** who is on the guest list, day by day, for the festival currently promoted on `https://fipb.ro/`, and what is its date scope?
**Scope:** read-only — first-party pages on `fipb.ro` only. No application code touched.

## Sources

- `https://fipb.ro/` — homepage; `<title>` "Festivalul Internațional de Poezie București – Ediția a XVI-a"; `og:image` uploaded `2026/08`; section heading `Program FIPB ediția a XVI-a, 14 - 20 septembrie 2026`; daily anchors `#14-sep` … `#20-sep`. Last-Modified `Fri, 28 Aug 2026 19:09:34 GMT`.
- `https://fipb.ro/invitati/` — full 2026 speaker roster (~200 bio cards). Last-Modified `Fri, 28 Aug 2026 19:01:11 GMT`.
- `https://fipb.ro/despre/` — About; "Istoric" dropdown lists `Ediția XV (2025.fipb.ro) … Ediția I (2016.fipb.ro/2010-2)`.
- `https://fipb.ro/program/` — Program landing page (navigation only on fetch).
- `https://fipb.ro/en/welcome/` — English homepage; `<h2>` "The 16th edition, 15th - 20st of September 2026" (typo "20st"); day-anchored schedule, **interleaves 2025 events into the Sep 19 block**.
- `https://fipb.ro/en/guestlist/` — English full roster (mirrors `/invitati/`); `Last-Modified Fri, 28 Aug 2026 19:16:06 GMT`.
- `https://fipb.ro/en/about-us/` — English About.
- `https://fipb.ro/en/events/` — English Program landing.
- `https://fipb.ro/` HTTP HEAD probes for `/`, `/despre`, `/about`, `/invitati`, `/program`, `/contact`, `/arhiva`, `/en`, `/en/welcome` (all responses captured 2026-08-28, Mozilla UA).

## What's currently promoted

The site is currently promoting the **16th edition (`Ediția a XVI-a`) of the Festivalul Internațional de Poezie București**, scheduled **14–20 septembrie 2026** (Mon → Sun). Evidence — all first-party:

- `<title>` on `https://fipb.ro/`: "Festivalul Internațional de Poezie București – Ediția a XVI-a".
- Hero `og:image` points to `https://fipb.ro/wp-content/uploads/2026/08/fipb23.png` (uploaded in `2026/08`).
- H2: `Program FIPB ediția a XVI-a, 14 - 20 septembrie 2026`.
- Tab anchors `#14-sep` … `#20-sep` (seven panels, day-by-day).
- Footer `© 2010 – 2026 Festivalul Internațional al Poeziei` (both `/` and `/en/guestlist/`).

## Date scope — authoritatively clean + five things to know

The **clean 2026 calendar is the Romanian homepage's tab body** (`https://fipb.ro/#14-sep` … `#20-sep`). Every other date-bearing surface on the site carries template drift that should not be quoted:

1. **Top-nav dropdown on `/`, `/invitati/`, `/en/welcome/`, `/en/guestlist/`** lists `📅 lun, 15 sept` … `📅 dum, 21 sept` — the menu carries last-year's dates and is **one day off** the homepage's program. (Verified by curl + grep on `/` HTML: `<a href="/#15-sep" >📅 lun, 15 sept</a>` … `<a href="/#21-sep">📅 dum, 21 sept</a>` while the tab anchors resolve to `#14-sep` … `#20-sep`.)
2. **English header on `/en/welcome/`** declares "15th - 20st of September 2026" — both the wrong start day *and* the typo "20st" (should be "20th").
3. **English homepage body**, under the **Sat., 19th** tab, embeds **2025 events** verbatim: a "Rosario Castellanos Centenary" segment, a "Public readings" block with the 2025 lineup (Ana Andrei, Stoian G. Bogdan, Romulus Bucur, …, Elena Ștefoi; recital Adrian Naidin), a "Performances" block at ARCUB (Sorin Despot & Tiberiu Neacșu, Mugur Grosu, …, Peter Wessel & Mihai Iordache), "Eros between lyrics and lines" at KOG7, and a "Mircea Florian" book launch + Mircea Rusu Band concert — all clearly 2025. The English schedule also states "The exhibition will open between September 15 – 21, 2025" and the English Sunday panel ends `© 2025 Muzeul Național al Literaturii Române`. These are *not* in the Romanian homepage — the Romanian body is 2026-only.
4. **English guestlist nav "Time schedule" link** is broken: `href="https://fipb.ro/welcome/#program"` returns 404.
5. **Logo on every page** is `https://fipb.ro/wp-content/uploads/2018/05/fipb2025-logo-oficial-ro.png` (2025 leftover). The "Istoric" menu on `/despre/` and `/invitati/` jumps from `Ediția X (2019.fipb.ro)` to `Ediția XII (2022.fipb.ro)` — `Ediția XI` is unlisted, consistent with the 2020/2021 editions having been skipped (likely COVID era).

**Net date scope:** trust the Romanian `/` daily anchors `14 Sept (lun) – 20 Sept (dum) 2026` for the per-day guest list. Treat the menu dropdowns and the English body as noisy.

## Guest list by day (per the Romanian homepage's 2026 program)

All citations point to the daily tab anchor on `https://fipb.ro/`. Roles follow the page's own labels (`Alocuțiuni`, `Recital`, `Lecturi publice`, `Moderator`, `Invitați`, `Concert`).

### Luni, 14 septembrie 2026 — Deschiderea, Aula BCU „Carol I", 18:00

Source: [`https://fipb.ro/#14-sep`](https://fipb.ro/#14-sep)

- **Alocuțiuni (opening remarks):** Ioan Cristescu (director general MNLR); Marius Andruh (președintele Academiei Române); Mireille Rădoi (director general BCU „Carol I"); H.E. **Marija Kapitanović** (ambasadoarea Republicii Croația); H.E. **Chen Feng** (ambasadorul Republicii Populare Chineze); H.E. **Lili-Evangelia Grammatika** (ambasadoarea Republicii Elene); H.E. **Gloria Olivares Portocarrero** (ambasadoarea Republicii Peru); Abel Murcia Soriano (directorul Institutului Cervantes); Varujan Vosganian (președintele Uniunii Scriitorilor din România).
- **Concert:** Ansamblul cameral ARCO — elevi ai Colegiului Național de Arte „Dinu Lipatti" și ai Colegiului Național de Muzică „George Enescu"; coordonator **Ștefan Aprodu**.
- **Recital:** Horațiu Mălăele.
- **Lecturi publice:** Anca Ioana Câdă (RO), Magda Cârneci (RO), Dumitru Crudu (MD), Mihai Firică (RO), Diogo Margues (PT), Călin-Andrei Mihăilescu (RO), Ștefan Mitroi (RO), Ion Mureșan (RO), Dumitru Păcuraru (RO), Simona Popescu (RO), Ion Pop (RO), Ioana Ieronim (US/RO).
- **Lectură-performance:** Aleš Šteger (Slovenia) cu **Jure Tori** (acordeon) — *Deasupra pământului, sub cer* (15 min).
- **Moderator:** Dinu Flămând.

### Marți, 15 septembrie 2026

Source: [`https://fipb.ro/#15-sep`](https://fipb.ro/#15-sep)

- **17:00, Grădina MNLR — Lansare de carte *Mit și realitate: oglinzile în care ne privim* (Mariana Dan, Editura MLR).** Invitați: Răzvan Voncu, Ioana Ieronim. Moderator: Ioan Cristescu.
- **18:00, Cervantes — *Peruvian Poetry and the Western Periphery – Martín Rodríguez-Gaona.*** Alocuțiuni: Abel Murcia Soriano, Luana Stroe (Editura MLR), H.E. Gloria Olivares Portocarrero. Prezentare + lectură: **Martín Rodríguez-Gaona**, traducere în română de Vlad Radulian.
- **18:00, Grădina MNLR — Dialog *Pornind de la literatură.*** Ioan Stanomir și Dinu Flămând.
- **18:30, MNLR Calea Griviței — Vernisaj.** Alina Roșca, Ioan Nemțoi, Mircia Dumitrescu.
- **19:00, /SAC Malmaison — POELANDA** (expoziție-instalație). Curator: Alex Radu. Instalații de Justin Baroncea, tandemul **111invers1** (Lumi Mihai, Mugur Grosu), Maria Ghement, Alexandra Müller, Cristian Matei. Design expozițional și identitate grafică: Alexandra Müller, Ioana Naniș, Larisa State, Bianca Manea, Horia Lungescu.
- **19:00, Aula BCU „Carol I" — Lecturi publice:** Dan Mircia Cipariu (RO), Andrew Davidson Novosivschei (RO/US), Ioana Diaconescu (RO), Ivan Herceg (HR), Mircea Măluț (RO), Andrei Novac (RO), Laura Francisca Pavel (RO), Ioan Pintea (RO), Adrian Popescu (RO), Bogdan O. Popescu (RO), Nicolae Prelipceanu (RO), Antanas Šimkus (LT), Wu Shaodong (CN), Moni Stănilă (MD), Alexandru Vakulovski (MD), Darija Zilic (HR). Moderator: Ioan Cristescu.
- **19:30, Mansarda MNLR — *Cairo, jurnal de teren*** (lansare de carte și expoziție, OMG Publishing Cluj 2026). Poezie: Călin Dănilă, Matei Hutopilă, Cristian Dan Iordache, Simona Nastac, Florin Dan Prodan. Ilustrații: Zuzana Holá (Praga). Video & Sound: Mohsen L Belasy, Ghadah Kamal Ahmed / Sulfur Editions (Cairo).

### Miercuri, 16 septembrie 2026

Source: [`https://fipb.ro/#16-sep`](https://fipb.ro/#16-sep)

- **16:00, MNLR Sala Perpessicius — Conferință *Brâncuși – World-Traveling Bird*:** Prof. Dr. Kıymet Giray.
- **17:00, MNLR Sala Perpessicius — Conferință *Bâkî, Sultanul Poeților*:** Prof. Dr. Kudret Altun (partener: Institutul Yunus Emre).
- **18:00, Grădina MNLR — Lecturi publice:** Hanna Bota (RO), Yu ChengAn (CN), Cristina Drăghici (RO), Rodríguez-Gaona (PE/ES), Fatma Krouma (TN), Olimpiu Nușfelean (RO), Mikalis Papadoupulos (CY), Maria Pilchin (MD), Ivan Pilchin (MD), Silvan Stâncel (RO), Liviu Ioan Stoiciu (RO), Ion Bogdan Ștefănescu (RO), Ya Lijuan (CN), Daniela Vizireanu (RO), Florina Zaharia (RO). Moderator: Călin-Andrei Mihăilescu.
- **18:30, Cervantes — Lectură cu Manuel Rico și Rosana Acquaroni.** Manuel Rico în dialog cu Dinu Flămând. Lectură Rosana Acquaroni (traducere Mina Decu). Invitat: Claudiu Komartin (Editura Max Blecher).
- **19:00, MNLR — Vernisaj *Cella Delavrancea. O viață cât un secol*** (partener: Asociația Culturală Aici a stat).
- **19:30, Teatrul Nottara — *Ce am lăsat între noi*** (performance): Miguel Gane cu Nur Bonet (clape, chitară, flaut) și Brenda Sayuri (DJ).
- **20:00, Aula BCU „Carol I" — *Supraviețuirea literaturii și a creației artistice sub dictatura inteligenței artificiale*:** Dinu Flămând în dialog cu Emil Hurezeanu.

### Joi, 17 septembrie 2026

Source: [`https://fipb.ro/#17-sep`](https://fipb.ro/#17-sep)

- **14:00, Grădina MNLR — Lecturi publice:** Vilia Banța (RO), Tori Branca (RO), Gabriel Burlacu (RO), Florentina Chifu (RO), Nicoleta Milea (RO), Costinel Petrache (RO), Vasile Poenaru (RO), Ana Săcrieru (RO), Carmen Secere (RO), Alex Gabriel Stan (RO), Mihaela Stanciu (RO), Nina Vasile (RO). Moderatori: Evelyne Croitoru, Horia Gârbea.
- **16:30, Grădina MNLR — Lansări de carte** Nikos Vlahakis și *Vremea dimineților nesfârșite* de Jose Manuel de Vasconcelos. Invitat: Valentin Ajder (Editura Eikon). Moderator: Dinu Flămând.
- **17:00, Casa memorială George și Agatha Bacovia — *Bacovia – 145*.** Recital poezie: Simona Măicănescu și Anca Bejan. Pian: Vladimir Nicolae Spirescu (Colegiul „George Enescu"). Vioară: Mihai Marina Felicia și Matei Alexandru Morar (Colegiul „Dinu Lipatti"). Participă: Ioan Cristescu, Lelia Spirescu, Vasile Gribincea.
- **18:00, Aula BCU „Carol I" — Lecturi publice:** Alina Aldea (RO), Vlad Alui Gheorghe (RO), Eugen Barz (RO/ES), Florin Iaru (RO), Dimitris Kanellopoulos (GR), Anush Kocharyan (AM), Cosmin Perța (RO), Pavel Șușară (RO), Radu Sergiu Ruba (RO), Livia Ștefan (RO), Robert Șerban (RO), Tudor Voicu (RO), George Vulturescu (RO). Moderator: Cosmin Perța.
- **19:30, MNLR — Vernisaj *Frecvențe organice* (Alina Aldea).** Curator: Diana Dochia.
- **20:00, Teatrul Național „I. L. Caragiale" Sala Studio — *Evocări poetice*.** Cezar Ivănescu (Andrei Duban), Emil Botta (Andrei Finți), Constanța Buzea (Cecilia Bârbora), Angela Marinescu (Teodora Mareș), Marin Sorescu (Dragoș Stamate), Magda Isanos (Cesonia Postelnicu).

### Vineri, 18 septembrie 2026

Source: [`https://fipb.ro/#18-sep`](https://fipb.ro/#18-sep)

- **11:00, Casa Memorială Tudor Arghezi – Mărțișor — *Grădina poeziei*** (partener: mișcarea *Bosques de la Poesía*, fondată la Villa Carlos Paz, 2020, de Leopoldo „Teuco" Castilla, Pedro Solanas și Aldo Parfeniuk).
- **16:00, Grădina MNLR — Lansare *Traiectorii ale exilului / Trajectoires en exil* (Petre Răileanu).** Moderator: Dinu Flămând.
- **17:00, Grădina MNLR — Lecturi publice:** Silvia Bre (IT), Rita Chirian (RO), Mina Decu (RO), Gellu Dorian (RO), Ioana Greceanu (RO), Filía Kanellopoulou (GR), Ștefan Manasia (RO), Tiberiu Neacșu (RO), Danai Sioziou (GR), Cassian Maria Spiridon (RO), Grete Tartler (RO), Lucian Vasiliu (RO). Moderator: Ioan Cristescu.
- **17:30, Cervantes — Masă rotundă *Poezia astăzi: autori, editori, cititori*.** Participă: editorul Pepo Paz Saz, poeții Rosana Acquaroni și Manuel Rico. Moderator: Carmen Mușat.
- **18:00, deGalben Hub — Seară de performance:** Anne Barbusse (FR), Mugur Grosu (RO), Markus Khole (AT), Ligia Keșișian (RO), Tiberiu Neacșu (RO), Simona Petrișor-Neacșu (RO), Radu Nițescu (RO), Răzvan Omotă (RO), Cosmin Perța (RO), Elena Vlădăreanu (RO), Mathieu Yekta (FR), Andy Willoughby (UK). Moderator: Sorin Despot.
- **19:00, Institutul Cultural Francez — *Seară de poezie franceză*.** Béatrice Bonhomme, Carole Carcillo-Mesrobian, Catherine Pont Humbert. Moderator: Magda Cârneci.
- **19:00, Grădina MNLR — *Remember Cezar Ivănescu (1941 – 2008)***. Invitați: Lucian Vasiliu, Cassian Maria Spiridon, Gellu Dorian, Ioana Diaconescu.

### Sâmbătă, 19 septembrie 2026

Source: [`https://fipb.ro/#19-sep`](https://fipb.ro/#19-sep)

- **11:00–13:00, Ceainăria MNLR — Ateliere de benzi desenate *Cum poate deveni o poezie o poveste în benzi desenate?*** Coord. Mihai I. Grăjdeanu (Centrul European School of Comics, sub egida MNLR). Grupa 8–10 ani.
- **13:00–15:00, Mansarda MNLR — Atelier *Poezie în viață*.** Nina Vasile.
- **13:00–15:00, MNLR — *Apolodor în Țara Poeților*** (atelier pentru copii 8–14 ani). Înscrieri la `oros.oana@gmail.com`.
- **15:00, Grădina MNLR — *Poezia ca busolă***. Sanna Hartner (SE) și Alina Purcaru (RO).
- **16:00, Grădina MNLR — Lectură și dezbatere: Dominik Ela Bárt (CZ).** Traducere: Mircea Dan Duță. Moderator: Gabriela Georgescu (Centrul Ceh).
- **17:00, Grădina MNLR — Prezentarea antologiilor.** *Ploaia în amintirea norului* de Dinu Flămând (trad. gr. Dimitris Kanellopoulos, Oropedio, Atena 2026); *Exilat în utopia* de Dimitris Kanellopoulos (Junimea 2026). Invitați: Dimitris Kanellopoulos, Nikos Vlahakis, Dinu Flămând.
- **18:00, deGalben Hub — Lecturi publice:** Adrian Alui Gheorghe (RO), Romulus Bucur (RO), Leo Butnaru (MD), Nichita Danilov (RO), Eric Desordre (FR), Ilias Fragkakis (GR), Bogdan Ghiu (RO), Ioan Matiuț (RO), Andrei Mocuța (RO), Simona Sigartău (RO), Jose Luis Vasconcelos (PT). Moderator: Toni Chira.
- **19:00, Muzeul Enescu / Palatul Cantacuzino — *Zilele Bucureștiului la Palatul Cantacuzino*.** Lecturi: Cosmin Perța, Miruna Vlada, Dinu Flămând. Concert: Zaraza & Band. (Parteneri: Ovidius Authentic Tours, Muzeul Enescu, MNLR, Youth Vision for Society, UNATC, Țiriac Collection.)

### Duminică, 20 septembrie 2026

Source: [`https://fipb.ro/#20-sep`](https://fipb.ro/#20-sep)

- **11:00–13:00, Ceainăria MNLR — Ateliere de benzi desenate** (Mihai I. Grăjdeanu). Grupa 11–14 ani.
- **13:00–15:00, Grădina MNLR — *Jucăria de vorbe*** (atelier). Coordonator: Oana Oros; asistent: Marine Posocco. Temă: Tristan Tzara 130.
- **16:00, Grădina MNLR — *Remember Angela Marinescu (1941 – 2023)***. Invitați: Svetlana Cârstean, Emanuela Ignățoiu-Sora, Cristina Ispas, Elena Vlădăreanu, Ștefania Mihalache, Alina Purcaru, Miruna Vlada. Moderator: Toni Chira.
- **18:00, Grădina MNLR — Lecturi publice:** Angela Baciu (RO), Luiza Cala (RO), Ioana Crăciunescu (RO), Carmen Firan (RO/US), Vasile Gribincea (RO/MD), Ligia Keșișian (RO), Iuliana Miu (RO), Victoria Milescu (RO), Iustin Moraru (RO), Loreta Popa (RO), Adrian Sângeorzan (RO/US), Andreea Teliban (RO), Eugenia Țarălungă (RO), Răzvan Țupa (RO). Moderator: Loreta Popa.
- **19:30, Galeria Kog 7 — *Poezie dezbrăcată***. Lecturi din Clément Marot, Emil Brumaru, Tudor Arghezi, Paul Verlaine, Stéphane Mallarmé, Arthur Rimbaud, Federico García Lorca, W. H. Auden, Florin Iaru, Louise Glück. Interpretează studentele Teodora Bendriș, Alexandra Codreanu, Ana Maria Stan, Andra Nicola. Moderator: Călin-Andrei Mihăilescu. Vernisaj pop-up *Șoapta Formei* (fotografie) — Ștefan Neagu.

## What `/invitati/` adds on top of the daily schedule

`https://fipb.ro/invitati/` and `https://fipb.ro/en/guestlist/` (mirrors) are the **full 2026 speaker roster**: ~200 bio cards for invited participants, alphabetical, with country. Many of them do **not** appear in the seven daily panels above — they are invitees without an assigned daily slot, moderators' guests, exhibition collaborators, or workshop contributors. Highlights of names *not* appearing in any day panel above (cross-checked against both rosters):

**Romania:** Amelia Stănescu, Diana Iepure, Vlad Gălățianu, Adrian Naidin, Albert Tajti, Cătălina Beța, Mircea Rusu, Nadia Trohin, Mircea Tiberian, FADO meu amor (Jezebel | Luís Maria Costa Hölzl, Emilian Mănica), Mircea Florian, Daniel Cătălin Năstase, Marieta Rădoi Mihăiță, Stoian G. Bogdan, Simona-Grazia Dima, Flavia Adam, Zsuzsa Ozsváth, Vianu Mureșan, Victor Drăghici, Urszula Honek, Toma Pavel, Telemachos Chytiris, Tudor Crețu, Teodora Coman, Sylvestre Clancier, Sorin Despot, Sergej Timofejev, Savu Popa, Sántha Attila, Salvador Burrell, Ruxandra Cesereanu, Pietro Costa, Peter Sragher, Nora Iuga, Péter Závada, Peter Wessel, Paloma Hermina Hidalgo, Olga Ștefan, Octavian Soviany, Nikolaos Vlahakis, Nadya Radulova, Nicolae Coande, Nichita Danilov, Muriel Augry, Marius Aldea, Miruna Drăghici, Mihai Vasilescu, Mátyás Szöllősi, Maria Șleahtițchi, Martina Caluori, Marco Fazzini, Liviu Capșa, Luigi Colagreco, Luciana Crăciun, Kata Győrfi, Jaromír Typlt, Ioana Nicolaie, Ion Cocora, Ileana Popescu Bâldea, Hussein Habasch, Hanen Marouani, Mu Bai (Wang Guoce), Guillaume Métayer, Gelu Vlașin, Gelu Diaconu, Gabriel Chifu, Florentin Popa, Florin Dumitrescu, Evelyne Maria Croitoru, Eva Potiguara, Elisa Donzelli, Elena Ștefoi, Dóra Mărcuțiu-Rácz, Doina Tudorovici, Denisa Comănescu, Daniela Bejinariu, Dan Sociu, Cristina Dicusar, Cristina Bogdan, Constantin Iftime, Cristiana Eso, Christian Sinicco, Colin Herd, Ciprian Măceșaru, Cheng Yong, Cécile Ossant, Cătălina Matei, Călin Vlasie, Carmen Florea, Bogdan O. Popescu (also on Tue 15), Grégory Rateau, Andrei Zbîrnea, Bernadete Saidelles, Bengt Berg, Andra Rotaru, Alexandru-Codruț Ivașcu, Alexandra Nicod, Ioana Gruia, Teodor Dună, Dan Coman, Ana Blandiana, Radu Vancu, Caius Dobrescu, Florin Iaru (also on Thu 17), Ion Pop (also on Mon 14), Ion Mureșan (also on Mon 14), Denisa Comănescu, Simona Popescu (also on Mon 14), Varujan Vosganian (also on Mon 14), Magda Cârneci (also on Mon 14).

**International:** Lamis Saidi (DZ), Laus Strandby Nielsen (DK), Lalo Barrubia (UY), Yang Ke (CN), Krzysztof Katkowski (PL), Christos Koukis (GR), Jyrki Kiiskinen (FI), Jeannette L. Clariond (MX), Izabelle Valladares (BR), Isabel Cristina Pires (PT), Iustin Butnariuc, David Greenslade (UK), Miranda Eristavi (GE), Giorgi Balakhashvili (GE), Víctor Rodríguez Núñez (CU), Denise Vargas (HN), Juan Carlos Mestre (ES), Clyo Mendoza (MX), Adriana Hoyos (CO/ES), Iria Fariñas (ES), Wang Xiaolu (ES/CN), Victor Ivanovici (GR/RO), Tomás Cohen (CL/DE), Riri Sylvia Manor (IL).

**Citation:** [`https://fipb.ro/invitati/`](https://fipb.ro/invitati/) (RO, alphabetical roster with country tags) and [`https://fipb.ro/en/guestlist/`](https://fipb.ro/en/guestlist/) (EN mirror, `Last-Modified Fri, 28 Aug 2026 19:16:06 GMT`).

## Conclusions

1. **Currently promoted edition:** `Ediția a XVI-a`, **14–20 septembrie 2026**, hosted by the National Museum of Romanian Literature (MNLR) and partners (BCU „Carol I", Cervantes, ICFR, MNLR Calea Griviței, Teatrul Nottara, Teatrul Național „I. L. Caragiale", Muzeul Enescu, deGalben Hub, /SAC Malmaison, Casa memorială Bacovia, Casa Memorială Tudor Arghezi). Source: homepage `<title>` + H2 + day anchors.
2. **Authoritative per-day guest list:** the seven day panels on `https://fipb.ro/#14-sep` … `https://fipb.ro/#20-sep` (Romanian). The English version at `https://fipb.ro/en/welcome/` is the same seven days in English, **except** the Sat 19 panel has 2025 events spliced in and the Sun 20 panel shows `© 2025 MNLR` — the Romanian body is the cleaner source.
3. **Full roster** (every invited participant, not only those with a daily slot) lives at `https://fipb.ro/invitati/` and `https://fipb.ro/en/guestlist/` (~200 speakers across ~40 countries).
4. **Date-scope drift to ignore:** the top-nav `📅 lun, 15 sept` … `📅 dum, 21 sept` dropdown on every page (one day off), the English header "15th - 20st of September 2026", the broken English nav link `https://fipb.ro/welcome/#program`, and the 2025 logo `fipb2025-logo-oficial-ro.png`. Past-editions list skips `Ediția XI` (2020/2021 not held).

## Caveats

- `Last-Modified` timestamps (28 Aug 2026) and the homepage `og:image` upload folder `2026/08` both place the page set well before the festival's 14 Sep 2026 opening — program could still be amended.
- Diogo Margues is listed as `Portugal` (PT) on the Romanian homepage; the English mirror spells it `Diogo Marques`. One spelling only.
- The `/invitati/` bio cards reference images uploaded in `2025/08` and `2025/09` (last edition's photo set); the roster itself is the 2026 edition — reuse of headshots, not a 2025 list.
- "Tiberiu Neacșu" appears both in the `/invitati/` alphabetical list and in the Friday 18 17:00 panel on the homepage — counted once in the day panel above.
- Country codes above are my own abbreviations; the site writes them as parentheticals (e.g. "România", "Republica Moldova"). Some are dual-attributed (e.g. Andrew Davidson Novosivschei — RO/US); the site writes both.
- I deliberately did **not** fetch the past-edition archive hosts (`2025.fipb.ro`, `2024.fipb.ro`, …, `2016.fipb.ro`) cited in the nav — out of scope and outside the "currently promoted" question.
