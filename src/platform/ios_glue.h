#pragma once
// UIKit pieces SDL does not provide on iOS (see ios_glue.m).
#include <SDL3/SDL.h>
#include <stdbool.h>
#include <stddef.h>

// SDL 3.4 has no iOS file dialog: a UIDocumentPickerViewController that hands its pick to cb the
// way SDL_ShowOpenFileDialog would (one path, or NULL when cancelled). The file is a copy in the
// app's own sandbox, so it stays readable after the picker closes.
void ios_show_open_file_dialog(SDL_DialogFileCallback cb, void *userdata);
// The app's Documents folder with a trailing slash; it shows in the Files app.
bool ios_documents_dir(char *out, size_t size);
// A light tap from the Taptic Engine.
void ios_haptic_tick(void);
