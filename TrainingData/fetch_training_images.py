#!/usr/bin/env python3
"""
fetch_training_images.py — download candidate training images for the Petalogue
Create ML classifier from Wikimedia Commons.

For each flower in ../Petalogue/Catalog/flowers.json it searches Commons for the
latin name and downloads up to N openly-licensed images into TrainingData/<id>/.

Standard library only — no pip install needed.

    python3 fetch_training_images.py                 # 30 images per species
    python3 fetch_training_images.py --per-species 40
    python3 fetch_training_images.py --only prunus-mume,nelumbo-nucifera

⚠️  IMPORTANT — these are CANDIDATES, not verified training data.
    Commons search is keyword-based and WILL return wrong species, diagrams,
    herbarium sheets, maps, and close-ups of leaves/seeds. Before training:
      1. Open each folder and delete anything that is not a clear photo of the
         flower in bloom.
      2. Aim for 20–30+ good, varied images per class (angles, lighting).
      3. For higher quality, prefer iNaturalist 'Research Grade' observations
         (https://www.inaturalist.org) and your own Nanjing campus photos.
"""

import argparse
import json
import os
import sys
import time
import urllib.parse
import urllib.request

API = "https://commons.wikimedia.org/w/api.php"
# Wikimedia requires a descriptive User-Agent.
UA = "PetalogueTrainingFetcher/1.0 (educational; flower classifier dataset)"
HERE = os.path.dirname(os.path.abspath(__file__))
CATALOG = os.path.join(HERE, "..", "Petalogue", "Catalog", "flowers.json")
ALLOWED_EXT = (".jpg", ".jpeg", ".png")


def load_catalog():
    with open(CATALOG, "r", encoding="utf-8") as f:
        return json.load(f)


def api_get(params):
    url = API + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def search_image_urls(query, limit):
    """Return up to `limit` direct image URLs for a Commons search term."""
    params = {
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": query,
        "gsrnamespace": "6",          # File: namespace
        "gsrlimit": str(limit),
        "prop": "imageinfo",
        "iiprop": "url|mime",
        "iiurlwidth": "1024",          # request a scaled-down thumbnail
    }
    data = api_get(params)
    pages = data.get("query", {}).get("pages", {})
    urls = []
    for page in pages.values():
        info = (page.get("imageinfo") or [{}])[0]
        mime = info.get("mime", "")
        if not mime.startswith("image/"):
            continue
        # Prefer the scaled thumburl; fall back to the original.
        url = info.get("thumburl") or info.get("url")
        if url and url.lower().split("?")[0].endswith(ALLOWED_EXT):
            urls.append(url)
    return urls


def download(url, dest):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = resp.read()
    with open(dest, "wb") as f:
        f.write(data)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--per-species", type=int, default=30,
                        help="images to download per species (default 30)")
    parser.add_argument("--only", default="",
                        help="comma-separated catalog ids to limit to")
    args = parser.parse_args()

    only = {s.strip() for s in args.only.split(",") if s.strip()}
    catalog = load_catalog()

    total = 0
    for flower in catalog:
        fid, latin = flower["id"], flower["latinName"]
        if only and fid not in only:
            continue

        folder = os.path.join(HERE, fid)
        os.makedirs(folder, exist_ok=True)
        # Strip cultivar quotes for a cleaner search, e.g. Prunus serrulata 'Kanzan'.
        query = latin.replace("'", "").strip() + " flower"
        print(f"\n→ {fid}  (search: {query!r})")

        try:
            urls = search_image_urls(query, args.per_species)
        except Exception as e:  # noqa: BLE001
            print(f"   search failed: {e}", file=sys.stderr)
            continue

        if not urls:
            print("   no results — try a manual search on Commons/iNaturalist.")
            continue

        saved = 0
        for i, url in enumerate(urls, start=1):
            ext = os.path.splitext(url.split("?")[0])[1].lower()
            if ext == ".jpeg":
                ext = ".jpg"
            dest = os.path.join(folder, f"{fid}-{i:03d}{ext}")
            try:
                download(url, dest)
                saved += 1
            except Exception as e:  # noqa: BLE001
                print(f"   skip {url[:60]}…: {e}", file=sys.stderr)
            time.sleep(0.2)  # be polite to the API
        print(f"   saved {saved} image(s) → TrainingData/{fid}/")
        total += saved

    print(f"\nDone. {total} candidate image(s) downloaded.")
    print("Now REVIEW every folder by hand and delete anything that isn't a clear "
          "photo of the flower in bloom before training in Create ML.")


if __name__ == "__main__":
    main()
