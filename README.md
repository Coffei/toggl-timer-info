# Toggl timer info CLI

This simple script allows to you to fetch information about the current running timer in [Toggl
Track](https://toggl.com). It is designed to be used in a WM bars like
[Waybar](https://github.com/Alexays/Waybar).

## Setup

First you need an API token, get one at https://track.toggl.com/profile.

Place the token in the file `.api_token` in the same folder the script is in.

## How to use it

Just run it.

```bash
$ bash run.sh
◉ Running: Some important work (00:07:13)
```

Since the API usage is quite limited on the free plan the script batches the API uses. Data is
refreshed every 180 seconds (can be configured in the script), last response is cached locally.

You can also force refresh the data at any time using the flag `--force-sync`.

Usually you'd integrate this into something like Waybar. In Waybar the configuration can look
something like this.

```config.json
  ...
  "modules-right": [
    ...
    "custom/toggl",
    ...
  ],

  "custom/toggl": {
    "exec": "bash /path/to/toggl-timer-info/run.sh",
    "interval": 1,
    "on-click": "bash /path/to/toggl-timer-info/run.sh --force-sync"
  },
```

This configuration updates the module every second. You can also force refresh by clicking on the
widget (e.g. when you know you made a change, otherwise the change will show up in at most 3
minutes).
