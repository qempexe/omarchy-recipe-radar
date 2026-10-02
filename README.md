# Recipe Radar

An [Omarchy](https://omarchy.org) shell bar widget that suggests recipes from what you have in your pantry.

Click the fork-and-knife icon in the bar, add the ingredients you have at home, and get matching recipes with photos, ingredient lists and instructions.

## Features

- **Pantry**: add ingredients with autocomplete (the ingredient list comes from TheMealDB), remove them with a click.
- **Suggestions**: recipes that match your pantry, refreshed whenever the pantry changes.
- **Recipe view**: photo, ingredient list (the ones you already have are highlighted), instructions, and a link to the YouTube video when one exists.
- **Favorites**: star any recipe to save it.
- **Random recipe**: for when you have no idea what to cook.
- **Keyboard friendly**: `Esc` goes back from a recipe, then closes the panel.
- Styled with Omarchy's own theme tokens, so it follows your theme and font.

## Install

```bash
omarchy plugin add https://github.com/qempexe/omarchy-recipe-radar.git --enable --yes
```

Or by hand: copy this directory to `~/.config/omarchy/plugins/io.github.qempexe.recipe-radar/` (the folder name must match the plugin id), then:

```bash
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.qempexe.recipe-radar
```

### Put the icon in the bar

Add the widget to your bar layout in `~/.config/omarchy/shell.json`, under `bar` → `layout` → the section you want (`left`, `center` or `right`):

```json
{ "id": "io.github.qempexe.recipe-radar" }
```

Then restart the shell:

```bash
omarchy restart shell
```

## Usage

| Action | How |
| --- | --- |
| Open / close the panel | Left-click the bar icon |
| Add an ingredient | Type it and press `Enter` (picks the first autocomplete match) |
| Open a recipe | Click it in the list |
| Save / unsave a recipe | Click the star |
| Back / close | `Esc` |

The panel can also be controlled over IPC, for example to bind it to a key:

```bash
omarchy-shell io.github.qempexe.recipe-radar toggle   # open/close
omarchy-shell io.github.qempexe.recipe-radar open
omarchy-shell io.github.qempexe.recipe-radar close
```

## Data and privacy

- Recipes and ingredients come from [TheMealDB](https://www.themealdb.com) through its free public API. Please check their terms for your use case.
- Your pantry and favorites are stored locally in `~/.config/recipe-radar.json`. Nothing else is stored or sent anywhere.
- The only network requests are to `themealdb.com` (search, recipe details, images).

## Limitations

- Suggestions are based on the first three ingredients in your pantry, to keep requests light.
- Recipes are limited to what TheMealDB offers (mostly English, a few hundred recipes).
- Ingredient matching is name-based, so unusual spellings may not match.

## Files

| File | Purpose |
| --- | --- |
| `manifest.json` | Omarchy plugin manifest |
| `BarWidget.qml` | The bar icon; loads the panel |
| `Panel.qml` | The popup panel, data fetching, storage and IPC |
| `RecipeDetail.qml` | Single-recipe view |
| `RecipeRow.qml` | Recipe list row (photo, name, star) |
| `RRButton.qml` | Flat bordered button |
| `SectionLabel.qml` | Small uppercase section heading |

## Development

Plugin files under `~/.config/omarchy/plugins/` are watched, but edits to `Panel.qml` only show up reliably after:

```bash
omarchy restart shell
```

To check the manifest:

```bash
omarchy plugin validate .
```

## Uninstall

```bash
omarchy plugin remove io.github.qempexe.recipe-radar
```

This does not edit `shell.json`: remove the `{ "id": "io.github.qempexe.recipe-radar" }` entry from your bar layout by hand. To delete your saved pantry and favorites, remove `~/.config/recipe-radar.json`.

## Roadmap

- [ ] Rank suggestions by how many of your pantry items they use ("you have 4 of 7")
- [ ] Use all pantry items for suggestions, not just the first three
- [ ] Missing-ingredients view / shopping list
- [ ] Filter by category or cuisine
- [ ] Search recipes by name
- [ ] Arrow-key navigation in lists, `Enter` to open
- [ ] Offline and API-error messages instead of an empty list
- [ ] Cache the ingredient list and recipe details
- [ ] Loading states for recipe details and images
- [ ] Better ingredient matching ("chicken breast" vs "chicken")
- [ ] Export / import pantry and favorites
- [ ] Configurable storage location and optional supporter API key
- [ ] Screenshot and theme gallery
- [ ] Changelog and tagged releases

Ideas and pull requests are welcome.

## License

[MIT](LICENSE)
