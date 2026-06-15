# TrainingData — Create ML classifier (v1.5)

Training images for `PetalogueClassifier.mlmodel`, the offline fallback identifier.
One folder per catalog `id` (matching `flowers.json`). **Not part of the app build** —
this lives outside the Xcode target and is gitignored except for structure.

## Folders (10 classes)

```
prunus-mume/  osmanthus-fragrans/  nelumbo-nucifera/  orychophragmus-violaceus/
brassica-napus/  veronica-persica/  prunus-serrulata-kanzan/  magnolia-denudata/
prunus-serrulata/  astragalus-sinicus/
```

## 1. Get candidate images

```bash
cd TrainingData
python3 fetch_training_images.py                 # ~30 per species from Wikimedia Commons
python3 fetch_training_images.py --per-species 40 --only prunus-mume
```

Stdlib only — no install needed. The script reads latin names from
`../Petalogue/Catalog/flowers.json`, so it stays in sync with the catalog.

## 2. ⚠️ Review by hand (required)

Keyword search returns wrong species, herbarium sheets, diagrams, and leaf/seed
close-ups. **Open every folder and delete anything that isn't a clear photo of the
flower in bloom.** A model trained on dirty data quietly misidentifies everything.

Target: **20–30+ good, varied images per class** (different angles, lighting,
backgrounds). Best sources, in order:
1. Your own Nanjing campus photos (most representative of real use).
2. [iNaturalist](https://www.inaturalist.org) — filter to **Research Grade**.
3. [Wikimedia Commons](https://commons.wikimedia.org) (what the script uses).

## 3. Train

1. Open **Create ML** → new **Image Classification** project.
2. Drag this `TrainingData` folder in as the training source (folder names = labels).
3. Train, then export **`PetalogueClassifier.mlmodel`**.
4. Add it to the Xcode project and implement `CreateMLClassifier: FlowerIdentifying`
   as the offline fallback (same protocol as `PlantNetService`).

## Licensing

Commons images are openly licensed but attribution terms vary. For an offline,
on-device model the images aren't redistributed, but keep this in mind if you ever
publish the dataset.
