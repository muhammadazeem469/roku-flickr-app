# Flickr Gallery — Roku Channel

A Roku SceneGraph channel that displays Flickr photos in a multi-row swimlane gallery.

---

## Installation Guide

### Step 1 — Clone the Repository

Make sure you have [Git](https://git-scm.com/) installed, then run:

```bash
git clone https://github.com/muhammadazeem469/roku-flickr-app.git
cd flickr-gallery-roku
```

> Replace `YOUR_USERNAME/flickr-gallery-roku` with the actual repository URL.

---

### Step 2 — Enable Developer Mode on Your Roku Device

1. On your Roku home screen, use the remote to enter this secret key sequence:

   ```
   Home × 3, Up × 2, Right, Left, Right, Left, Right
   ```

2. A **Developer Settings** screen will appear.

3. Click **Enable Installer and Restart**.

4. After the Roku restarts, go back to the same screen and click **Enable Installer**.

---

### Step 3 — Set a Developer Username and Password

1. After enabling developer mode, go to:

   ```
   Settings → System → About
   ```

   Note the **IP address** of your Roku (e.g. `192.168.1.42`).

2. On your computer, open a browser and navigate to:

   ```
   http://<your-roku-ip-address>
   ```

   Example: `http://192.168.1.42`

3. A login popup will appear. Enter:
   - **Username:** `rokudev`
   - **Password:** the password you set when enabling developer mode

   > If you did not set a password yet, the Roku will prompt you to create one the first time you visit this page.

4. You should now see the **Roku Development Application Installer** web interface.

---

### Step 4 — Zip the Project

The zip file must have `manifest` at the **root level** (not inside a subfolder).

On **Mac / Linux**:

```bash
cd flickr-gallery-roku
zip -r ../FlickrGallery.zip .
```

On **Windows (PowerShell)**:

```powershell
cd flickr-gallery-roku
Compress-Archive -Path * -DestinationPath ..\FlickrGallery.zip
```

> **Important:** Open the zip and confirm `manifest`, `components/`, `source/`, and `images/` appear at the top level — not inside another folder.

---

### Step 5 — Install the Channel on Your Roku

#### Option A — Via Browser (Easiest)

1. Go to `http://<your-roku-ip-address>` in your browser and log in.
2. Under **Install Application**, click **Choose File**.
3. Select the `FlickrGallery.zip` file you created.
4. Click **Install**.
5. The channel will launch automatically on your Roku TV.

#### Option B — Via Terminal (curl)

```bash
curl --user rokudev:<your-password> \
     --digest \
     -F "mysubmit=Install" \
     -F "archive=@FlickrGallery.zip" \
     http://<your-roku-ip-address>/plugin_install
```

Example:

```bash
curl --user rokudev:mypassword123 \
     --digest \
     -F "mysubmit=Install" \
     -F "archive=@FlickrGallery.zip" \
     http://192.168.1.42/plugin_install
```

---

### Step 6 — Launch the Channel

- The channel launches **automatically** right after installation.
- To launch it again later, go to your Roku home screen and look under **My Channels → Dev Channel**.

---

## Updating the Channel

After making code changes, re-zip and re-upload using the same steps above. The installer will automatically replace the running version.

---

## Removing the Channel

#### Via Browser:

Go to `http://<your-roku-ip-address>`, log in, and click **Delete**.

#### Via Terminal:

```bash
curl --user rokudev:<your-password> \
     --digest \
     -F "mysubmit=Delete" \
     -F "archive=" \
     http://<your-roku-ip-address>/plugin_install
```

---

## Viewing Debug Logs

To see live logs while the channel is running, connect via telnet **before** launching:

```bash
telnet <your-roku-ip-address> 8085
```

Press `Ctrl + ]` then type `quit` to disconnect.

---

## Requirements

- Roku device (any model, firmware 7.0 or later)
- Computer and Roku on the **same Wi-Fi network**
- Git installed on your computer
