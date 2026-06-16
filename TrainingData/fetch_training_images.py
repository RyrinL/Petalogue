#!/usr/bin/env python3
"""
fetch_training_images.py — download flower images for Petalogue from
iNaturalist (default) or Wikimedia Commons.

Reads species from ../Petalogue/Catalog/flowers.json, so it always stays in
sync with the catalog. Standard library only — no pip install needed.

TWO MODES
---------
1. Catalog images (one good photo per species → the app's asset slots):

       python3 fetch_training_images.py --catalog

   Saves the single most-faved Research-Grade photo per species into
   ../Petalogue/Assets.xcassets/<id>.imageset/<id>.jpg

2. Training images (many photos per species → TrainingData/<id>/):

       python3 fetch_training_images.py                      # 30 each, iNaturalist
       python3 fetch_training_images.py --per-species 50
       python3 fetch_training_images.py --source commons     # use Wikimedia instead
       python3 fetch_training_images.py --only prunus-mume,nelumbo-nucifera

⚠️  REVIEW BEFORE TRAINING — search/observation data still contains the odd
    misidentification, leaf/seed close-up, or off photo. Open each folder and
    delete anything that isn't a clear photo of the flower in bloom. iNaturalist
    'Research Grade' is community-verified and much cleaner than keyword search,
    but not perfect.

NOTE on cultivars: 'Prunus serrulata "Kanzan"' is a cultivar iNaturalist indexes
under the species Prunus serrulata, so prunus-serrulata-kanzan and
prunus-serrulata will pull overlapping images. Hand-pick the double-flowered
(Kanzan) ones for that folder.
"""

import argparse
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

UA = "PetalogueImageFetcher/1.1 (educational; flower classifier dataset)"
HERE = os.path.dirname(os.path.abspath(__file__))
CATALOG = os.path.join(HERE, "..", "Petalogue", "Catalog", "flowers.json")
ASSETS = os.path.join(HERE, "..", "Petalogue", "Assets.xcassets")

COMMONS_API = "https://commons.wikimedia.org/w/api.php"
INAT_API = "https://api.inaturalist.org/v1/observations"
ALLOWED_EXT = (".jpg", ".jpeg", ".png")


def load_catalog():
    with open(CATALOG, "r", encoding="utf-8") as f:
        return json.load(f)


def api_get(url, params):
    full = url + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(full, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def species_query(latin):
    """Strip cultivar quotes, e.g. Prunus serrulata 'Kanzan' -> Prunus serrulata."""
    return re.sub(r"['\"].*?['\"]", "", latin).strip()


# ---- iNaturalist -----------------------------------------------------------

def inat_urls(latin, limit, size="large"):
    params = {
        "taxon_name": species_query(latin),
        "quality_grade": "research",
        "photos": "true",
        "per_page": str(min(max(limit, 1), 200)),
        "order_by": "votes",
        "order": "desc",
    }
    data = api_get(INAT_API, params)
    urls = []
    for obs in data.get("results", []):
        for photo in obs.get("photos", []):
            url = photo.get("url")  # e.g. .../photos/123/square.jpg
            if url:
                urls.append(url.replace("square", size))
    return urls[:limit]


# ---- Wikimedia Commons ------------------------------------------------------

def commons_urls(latin, limit):
    params = {
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": species_query(latin) + " flower",
        "gsrnamespace": "6",
        "gsrlimit": str(limit),
        "prop": "imageinfo",
        "iiprop": "url|mime",
        "iiurlwidth": "1024",
    }
    data = api_get(COMMONS_API, params)
    pages = data.get("query", {}).get("pages", {})
    urls = []
    for page in pages.values():
        info = (page.get("imageinfo") or [{}])[0]
        if not info.get("mime", "").startswith("image/"):
            continue
        url = info.get("thumburl") or info.get("url")
        if url and url.lower().split("?")[0].endswith(ALLOWED_EXT):
            urls.append(url)
    return urls


def fetch_urls(source, latin, limit):
    if source == "inat":
        return inat_urls(latin, limit)
    return commons_urls(latin, limit)


def download(url, dest):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = resp.read()
    with open(dest, "wb") as f:
        f.write(data)


# ---- Modes ------------------------------------------------------------------

def run_catalog(catalog, source, only):
    print("Catalog mode: one best image per species → Assets.xcassets\n")
    done = 0
    for flower in catalog:
        fid, latin = flower["id"], flower["latinName"]
        if only and fid not in only:
            continue
        try:
            urls = fetch_urls(source, latin, 1)
        except Exception as e:  # noqa: BLE001
            print(f"  {fid}: lookup failed: {e}", file=sys.stderr)
            continue
        if not urls:
            print(f"  {fid}: no image found — add one manually.")
            continue
        dest_dir = os.path.join(ASSETS, f"{fid}.imageset")
        os.makedirs(dest_dir, exist_ok=True)
        dest = os.path.join(dest_dir, f"{fid}.jpg")
        try:
            download(urls[0], dest)
            print(f"  ✓ {fid}.jpg")
            done += 1
        except Exception as e:  # noqa: BLE001
            print(f"  {fid}: download failed: {e}", file=sys.stderr)
        time.sleep(0.3)
    print(f"\nDone. {done} catalog image(s) saved. Review them — the auto-picked "
          "'most-faved' shot is usually good but glance at each before shipping.")


def run_training(catalog, source, per_species, only):
    print(f"Training mode: up to {per_species} images per species → TrainingData/  (source: {source})\n")
    total = 0
    for flower in catalog:
        fid, latin = flower["id"], flower["latinName"]
        if only and fid not in only:
            continue
        folder = os.path.join(HERE, fid)
        os.makedirs(folder, exist_ok=True)
        print(f"→ {fid}")
        try:
            urls = fetch_urls(source, latin, per_species)
        except Exception as e:  # noqa: BLE001
            print(f"   lookup failed: {e}", file=sys.stderr)
            continue
        saved = 0
        for i, url in enumerate(urls, start=1):
            ext = os.path.splitext(url.split("?")[0])[1].lower() or ".jpg"
            if ext == ".jpeg":
                ext = ".jpg"
            try:
                download(url, os.path.join(folder, f"{fid}-{i:03d}{ext}"))
                saved += 1
            except Exception as e:  # noqa: BLE001
                print(f"   skip: {e}", file=sys.stderr)
            time.sleep(0.2)
        print(f"   saved {saved} → TrainingData/{fid}/")
        total += saved
    print(f"\nDone. {total} candidate image(s). REVIEW every folder by hand "
          "before training in Create ML.")


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--source", choices=["inat", "commons"], default="inat",
                        help="image source (default: inat = iNaturalist Research Grade)")
    parser.add_argument("--catalog", action="store_true",
                        help="download ONE best image per species into the app asset slots")
    parser.add_argument("--per-species", type=int, default=30,
                        help="training images per species (default 30; ignored with --catalog)")
    parser.add_argument("--only", default="",
                        help="comma-separated catalog ids to limit to")
    args = parser.parse_args()

    only = {s.strip() for s in args.only.split(",") if s.strip()}
    catalog = load_catalog()

    if args.catalog:
        run_catalog(catalog, args.source, only)
    else:
        run_training(catalog, args.source, args.per_species, only)


if __name__ == "__main__":
    main()
