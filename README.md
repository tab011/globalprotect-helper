# GlobalProtect Linux Build & Install Helper

This helper automates building and installing the two GlobalProtect components from the
UMass Lowell distribution tarball, applies a required `<default-browser>` setting,
restarts the `gpd.service`, and launches the GlobalProtect UI.

## 1. Download the PanGPLinux Package

The package is available to UMass Lowell users at:

```
https://downloads.uml.edu/All/VPN/GP/Linux/PanGPLinux-5.3.2-c3.tgz
```

> **Note:** You must be logged in with your UML credentials to access this file.
If your browser prompts for login, complete authentication and then download
the file. Save it to a convenient location, e.g. `~/Downloads`.

If your browser renames the file (e.g., `PanGPLinux-5.3.2-c3(3).tgz`), that’s fine.

## 2. Extract the Tarball

From a terminal:

```bash
cd ~/Downloads
tar -xzf PanGPLinux-5.3.2-c3*.tgz
```

This will create a folder such as:

```
PanGPLinux-5.3.2-c3/
```
or
```
PanGPLinux-5.3.2-c3(3)/
```

Inside that folder, you’ll see two `*.tgz` component archives and matching directories.

## 3. Place the Script in the Same Location

Copy the provided `gp_local_build.sh` script into the extracted directory.

Example:

```bash
cp ~/path/to/gp_local_build.sh ~/Downloads/PanGPLinux-5.3.2-c3(3)/
cd ~/Downloads/PanGPLinux-5.3.2-c3(3)/
```

Make it executable:

```bash
chmod +x gp_local_build.sh
```

## 4. Run the Script

Run the script with `sudo` and specify your VPN portal (if different from default):

```bash
sudo ./gp_local_build.sh myvpn.uml.edu
```

What it does:

1. Finds the component tarballs that already have a same-named folder.
2. Extracts them (safe if already extracted).
3. Runs `make` and then `./install.sh` for each.
4. Ensures `<default-browser>yes</default-browser>` exists in `/opt/paloaltonetworks/globalprotect/GlobalProtect.xml`.
5. Sets the `<Portal>` to the value you specify.
6. Restarts the `gpd.service`.
7. Detects your logged-in desktop user and restarts the GlobalProtect UI.

## 5. Verify

After the script completes:

```bash
sudo systemctl status gpd.service
globalprotect show --status
```

You should see that the service is active and the UI is running.
# globalprotect-helper
