# SPDX-FileCopyrightText: 2026 Martin Pluskal <martin@pluskal.org>
# SPDX-License-Identifier: GPL-2.0-or-later
"""Plasma Login Manager's greeter: the login background SDDM shows, and a
vendor default that makes it the greeter's wallpaper. The greeter has no
themes of its own (plasma-login-manager v6.8.1 builds its QML in); its colours
and Plasma style follow the global theme an admin applies to it in System
Settings."""

from common import DEFAULTS, ROOT, USER, write
from imaging import login_background, save_jpeg
from targets.wallpapers import ZOOMED

DESKTOP = "plasma"
INSTALL_DIR = "/usr/share/openSUSE-halloween/plasmalogin"
DROP_IN = "30-openSUSE-halloween.conf"


def build(ctx):
    defaults = ROOT / "plasma/plasmalogin/defaults" / DROP_IN
    write(DEFAULTS / "plasmalogin.conf.d" / DROP_IN, defaults.read_text())
    save_jpeg(login_background(ctx.wallpapers, ZOOMED), USER / "openSUSE-halloween/plasmalogin/background.jpg")
