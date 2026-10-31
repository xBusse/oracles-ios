#include "gui/widgets.h"
#include <string.h>

int gui_mods(const ModInfo *official, const bool *enabled, int selected, bool playing, const ModInstalled *installed, int installed_count, const char *status, const GuiTheme *t, const GuiFrame *f) {
  gui_begin(page_scale(f));
  int tapped = GUI_NONE;
  PAGE(t, f) {
    if (header(t, "Mods", f->hints ? hint_of(f, "change", "back") : NULL)) tapped = GUI_BACK;
    LIST("ModsList") {
      // The rows loaded mods registered with oracles.setting, grouped by mod. They exist only once a
      // game has loaded its mods, so the section shows while playing. Selection index 2 + i.
      if (playing && mods_setting_count() > 0) {
        section(t, "Mod settings");
        const char *last = NULL;
        for (int i = 0; i < mods_setting_count(); i++) {
          const char *id = mods_setting_mod_id(i);
          if (!last || strcmp(last, id)) { paragraph(gui_str("%s", id), TAG, t->soft, 8, 4); last = id; }
          bool is_bool = mods_setting_kind(i) == MOD_SETTING_BOOL;
          bool on = is_bool && mods_setting_value(i);
          if (tap_row(t, (Row){.id = CLAY_IDI("ModSetting", i), .label = gui_str("%s", mods_setting_name(i)),
              .value = is_bool ? (on ? CLAY_STRING("On") : CLAY_STRING("Off")) : gui_str("%d", mods_setting_number(i)),
              .enabled = true, .selected = selected == 2 + i, .toggle = is_bool ? (on ? 1 : 2) : 0}))
            tapped = GUI_MOD_SETTING + i;
        }
        paragraph(CLAY_STRING("Takes effect right away."), SMALL, t->soft, 8, 0);
      }
      section(t, "Official mods");
      for (int i = 0; i < 2; i++) {
        const ModInfo *info = &official[i];
        bool on = enabled[i];
        CLAY({.layout = {.sizing = {CLAY_SIZING_GROW(0)}, .layoutDirection = CLAY_TOP_TO_BOTTOM},
              .border = {.color = gui_rgb(t->line_strong), .width = CLAY_BORDER_OUTSIDE(1)}}) {
          if (tap_row(t, (Row){.id = CLAY_IDI("OfficialMod", i), .label = gui_str("%s", info->name),
              .value = on ? CLAY_STRING("On") : CLAY_STRING("Off"), .enabled = true,
              .selected = selected == i, .toggle = on ? 1 : 2})) tapped = i;
          if (info->description[0]) paragraph(gui_str("%s", info->description), SMALL, t->paper, 12, 12);
          const char *games = info->ages && info->seasons ? "Ages + Seasons" : info->ages ? "Ages" : "Seasons";
          paragraph(gui_str("%s  /  %s", games, info->changes_game ? "Changes gameplay" : "Overlay only"), TAG, t->soft, 0, 8);
          if (info->author[0] || info->version[0])
            paragraph(gui_str("%s%s%s%s", info->author, info->author[0] && info->version[0] ? "  /  " : "",
                              info->version[0] ? "v" : "", info->version), TAG, t->muted, 0, 12);
        }
      }
      paragraph(playing ? CLAY_STRING("Restart the game from the main menu to apply changes.")
                        : CLAY_STRING("Ready to use. No download needed. Your selection is saved."), SMALL, t->soft, 16, 0);
      if (status && status[0]) paragraph(gui_str("%s", status), SMALL, t->error, 12, 0);
      section(t, "Installed mods");
      if (installed_count < 0)
        paragraph(CLAY_STRING("Could not read the mods folder."), SMALL, t->error, 12, 12);
      else if (!installed_count)
        paragraph(CLAY_STRING("No folder mods installed. Extract a mod into the app's mods folder to list it here."), SMALL, t->soft, 12, 12);
      for (int i = 0; i < installed_count; i++) {
        const ModInstalled *entry = &installed[i];
        const ModInfo *m = &entry->info;
        const char *state = "Loads with a compatible game";
        const char *error = "";
        if (playing) {
          state = "Not loaded in this session";
          for (int j = 0; j < mods_count(); j++) {
            if (strcmp(entry->id, mods_id(j))) continue;
            state = mods_enabled(j) ? "Active" : "Failed to load";
            error = mods_error(j);
            break;
          }
        }
        CLAY({.id = CLAY_IDI("InstalledMod", i),
              .layout = {.sizing = {CLAY_SIZING_GROW(0)}, .layoutDirection = CLAY_TOP_TO_BOTTOM},
              .border = {.color = gui_rgb(t->line_strong), .width = CLAY_BORDER_OUTSIDE(1)}}) {
          paragraph(gui_str("%s", m->name), SMALL, t->paper, 12, 8);
          if (m->description[0]) paragraph(gui_str("%s", m->description), SMALL, t->soft, 0, 8);
          paragraph(gui_str("%s / %s", m->ages && m->seasons ? "Ages + Seasons" : m->ages ? "Ages" : "Seasons",
                            m->changes_game ? "Changes gameplay" : "Overlay only"), TAG, t->soft, 0, 8);
          if (m->author[0] || m->version[0])
            paragraph(gui_str("%s%s%s%s", m->author, m->author[0] && m->version[0] ? " / " : "",
                              m->version[0] ? "v" : "", m->version), TAG, t->muted, 0, 8);
          paragraph(gui_str("%s", state), TAG, t->soft, 0, 12);
          if (*error) paragraph(gui_str("%s", error), SMALL, t->error, 0, 12);
        }
      }
      paragraph(CLAY_STRING("Folder mods load automatically. Restart the game after installing or removing one. Remove its folder to uninstall."), SMALL, t->soft, 12, 0);
    }
  }
  return tapped;
}
