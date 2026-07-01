# Sync Parent Updates

## Combined Listing Variant Picker (targeted)

```bash
./sync-combined-listing-from-parent.sh --diff
./sync-combined-listing-from-parent.sh
```

See `COMBINED_LISTING_FILES.txt` for the full file list.

## Other shared files (manual)

```bash
git fetch upstream
git checkout upstream/main -- sections/hero-slideshow.liquid
# ... etc
git commit -m "Sync parent updates [$(date +%Y-%m-%d)]"
```

See `SYNC_CONFIG.txt` for the hero/header sync list.

## Full parent merge

See README **Section B: Store Deployment** for the complete child update workflow with `.gitattributes` protection.