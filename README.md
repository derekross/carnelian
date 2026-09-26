# Carnelian

Publish what you write in [Omawrite](https://github.com/omacom-io/omawrite) to Nostr as a long-form article, from the Omarchy Share menu.

Carnelian is one bash script. It reads a markdown file, uploads any local images to your [Blossom](https://github.com/hzrd149/blossom) servers, builds a [NIP-23](https://github.com/nostr-protocol/nips/blob/master/23.md) article (kind 30023), shows you exactly what will go out, and signs it through [Opal](https://github.com/derekross/opal) so your key never touches the script. It publishes to your own NIP-65 write relays. With no file argument it publishes whatever Omawrite currently has open.

Named for the stone of signet rings, which sealed letters for a few thousand years before Nostr, and to sit beside Opal (signer) and Peridot (sharing) in the Omarchy bar.

## Requirements

- [Omarchy](https://omarchy.org) 4.x with Omawrite
- [nak](https://github.com/fiatjaf/nak): `omarchy pkg aur add nak-bin`
- `jq`, `python3` and `python-yaml` (already on Omarchy)
- [Opal](https://github.com/derekross/opal) for signing. Without it, Carnelian takes a key from `NOSTR_SECRET_KEY` or prompts for one.

## Install

```sh
git clone https://github.com/derekross/carnelian ~/Projects/carnelian
~/Projects/carnelian/dist/install.sh
carnelian setup
```

`install.sh` links `carnelian` into `~/.local/bin` and adds a **Publish to Nostr** group to the Omarchy Share menu. The group is only shown while Omawrite is the focused window, so it does not clutter the menu anywhere else.

`carnelian setup` asks Opal for a `bunker://` link, stores it with a dedicated client key under `~/.config/carnelian/` (mode 600), fetches your relay and Blossom server lists, and Carnelian appears in Opal's Apps list as its own app. The default policy is *manual*, so the first publish opens Opal's approval dialog with the article in it; tick "remember" there if you would rather not approve every post.

The signer and Carnelian talk over relay.ditto.pub, relay.dreamith.to and relay.primal.net. Pass `--relay` to setup to use others. `carnelian test` asks the signer for a signature on a throwaway note that is never sent, so you can confirm the pairing before publishing anything.

## Use

From Omawrite, press **Super + Ctrl + S** and pick **Publish to Nostr**:

- **Publish** opens a floating terminal, prints the title, slug, date, summary and a body preview, asks for confirmation, then signs and sends.
- **Dry run** prints the full event without signing or sending anything.

Or from a terminal:

```sh
carnelian post.md --dry-run          # look before you leap
carnelian post.md                    # preview, confirm, publish
carnelian                            # the file open in Omawrite
carnelian post.md --slug my-slug --relay wss://relay.example.com
carnelian status                     # which signer, relays, servers and file are in play
carnelian test                       # sign a throwaway note through Opal; send nothing
carnelian refresh                    # re-fetch your relay and Blossom server lists
carnelian post.md --rewrite-links    # also write the Blossom URLs back into post.md
```

Carnelian finds the open document through Omawrite's window title and last save directory. If the document has never been saved, it asks you to save first; if it has unsaved changes, it says so and publishes what is on disk.

## Metadata

Front matter is optional. With none, the title is the first `# Heading` (or, failing that, the filename prettified), the slug is the filename minus a `YYYY-MM-DD-` prefix, the date is that prefix, and the summary is the first paragraph.

```markdown
---
title: Goodbye Dock
summary: One paragraph shown in feeds.
image: https://example.com/cover.png
tags: [omarchy, linux]
slug: omarchy-goodbye-dock
date: 2026-09-23
---
```

The H1 is removed from the body because clients render the title tag. Publishing the same slug again replaces the article on relays, so edits are a rerun.

## Images

Image links that point at local files, and a local `image:` cover in the front matter, are uploaded before publishing:

```markdown
![Screenshot of the tiling layout](shots/tiling.png)
```

Paths are relative to the markdown file. The first Blossom server receives the upload and the others mirror it (BUD-04), then the published body carries the blob URLs. Remote URLs are left alone. Uploads are content addressed and cached in `~/.config/carnelian/uploads.json`, so republishing after an edit never re-uploads an unchanged image. The markdown file on disk is not touched unless you pass `--rewrite-links`, which swaps the paths for the URLs and keeps a `.bak` copy. A dry run lists what would be uploaded and uploads nothing.

Opal asks before signing a Blossom authorization and can remember the answer for up to an hour, so tick "remember" on the first image if a post has several.

## Relays and servers

Carnelian publishes to your NIP-65 write relays (kind 10002) and uploads to your Blossom server list (kind 10063), fetched once by `setup` and again by `refresh` or automatically when the cache is a day old. Nothing about you is hard-coded. First match wins:

1. `--relay` and `--server` on the command line.
2. `CARNELIAN_RELAYS` and `CARNELIAN_BLOSSOM_SERVERS` in the config file.
3. Your published lists, cached in `~/.config/carnelian/profile.json`.
4. A small built-in relay list. There is no built-in server list, so an article with local images and no known server stops with a clear message.

`carnelian status` shows which source each list came from.

## Configuration

`~/.config/carnelian/config` is sourced by bash:

```sh
# Relays to publish to. Unset to use your NIP-65 write relays.
CARNELIAN_RELAYS="wss://relay.primal.net wss://relay.damus.io"

# Blossom servers, first is uploaded to, the rest mirror. Unset to use your kind 10063 list.
CARNELIAN_BLOSSOM_SERVERS="https://blossom.example.com"

# Your pubkey, only needed when Carnelian cannot discover it (no Opal, bunker-only).
CARNELIAN_PUBKEY="npub1..."
```

`~/.config/carnelian/bunker` holds the Opal link and `~/.config/carnelian/client-key` the client key. Delete both and rerun `carnelian setup` to pair again, then revoke the old Carnelian entry in Opal.

## Troubleshooting

- **Publishing hangs, and Opal shows Carnelian as "waiting for app".** One of the relays in the bunker link is not reachable from your machine, and nak's NIP-46 client waits on every relay in the link. Carnelian probes each relay for a few seconds before connecting and drops the ones that do not answer, printing `Skipping unreachable signer relay: ...`. If that still fails, run `carnelian status`, or edit the relays in `~/.config/carnelian/bunker`.
- **"publishing failed or timed out".** Opal is locked, or its approval dialog was not answered within the two-minute window. Unlock Opal, run it again, and answer the dialog.
- **Opal shows a duplicate Carnelian.** `carnelian setup` was rerun after the bunker file was deleted. Revoke the older entry in Opal's Apps list.

## Uninstall

```sh
~/Projects/carnelian/dist/uninstall.sh          # command and menu entries
~/Projects/carnelian/dist/uninstall.sh --purge  # also the Opal pairing files
```

## License

MIT
