# Einthusanlib Rails App

A modern Ruby on Rails web application that fetches, downloads, and streams movies from Einthusan with real-time progress updates.

## 🛠 Technology Stack

- **Backend**: Ruby on Rails 7.x
- **Database**: SQLite3
- **Frontend**: Turbo, Stimulus
- **Styling**: Bootstrap 5
- **Real-time**: Action Cable (WebSockets)
- **Background Jobs**: ActiveJob
- **File Storage**: Active Storage
- **Movie Downloads**: youtube-dl / yt-dlp

## 📋 Prerequisites

- Ruby 3.x
- Rails 7.x
- Python 3.x (for youtube-dl)
- SQLite3

---

## 🚀 Local Development Setup

Follow these steps to set up the application on your local machine for development.

### 1. Clone the Repository
```bash
git clone https://github.com/alameenkhader/einthusanlib.git
cd einthusanlib
```

### 2. Install Dependencies
```bash
# Install Ruby gems
bundle install

# Install Python libraries (youtube-dl)
python3 -m venv venv
source venv/bin/activate
pip install youtube-dl
```

### 3. Setup Database
```bash
rails db:create
rails db:migrate
rails db:seed
```

### 4. Start the Application
```bash
# Start the Rails server
rails server

# In a separate terminal, start the background job processor
bin/jobs
```
Visit `http://localhost:3000` to access the application.

---

## 🌐 Production Setup (Ubuntu Server)

This guide explains how to deploy the application to a production Ubuntu server using Caddy and Systemd.

### Step 1: Server Preparation

**1. Install Caddy**
```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

**2. Open Firewall Ports**
You must open ports to allow web traffic and maintain access to your server.
```bash
# Always allow SSH first!
sudo ufw allow ssh

# Allow HTTP and HTTPS if you are using a domain name
sudo ufw allow http
sudo ufw allow https

# If you plan to use a custom port like 81, allow it too
# sudo ufw allow 81

sudo ufw enable
```

### Step 2: Deploy Application

**1. Clone the Repository**
Clone the project into a directory on your server (e.g., `/home/your-user/einthusanlib`).
```bash
git clone https://github.com/alameenkhader/einthusanlib.git
cd einthusanlib
```

**2. Install Dependencies**
```bash
# Install Ruby gems
bundle install

# Install Python libraries
python3 -m venv venv
source venv/bin/activate
pip install youtube-dl
```

### Step 3: Production Configuration

**1. Setup the Database**
```bash
RAILS_ENV=production rails db:setup
```
*Note: This command will create, migrate, and seed the database. Ensure your `config/database.yml` is configured for your production environment.*

**2. Precompile Assets**
```bash
RAILS_ENV=production rails assets:precompile
```

**3. Configure Caddy**
Edit the Caddyfile to act as a reverse proxy for the Rails app.
```bash
sudo vi /etc/caddy/Caddyfile
```
Replace its content with one of the following options.

**Option A: Using a Domain (Recommended)**
This is the standard for production. Caddy will automatically handle HTTPS certificates.
```plaintext
your-domain.com {
    reverse_proxy localhost:3000
}
```

**Option B: Using a Port (e.g., 81)**
Use this if you don't have a domain and want to access the app via an IP address. This will use HTTP.
```plaintext
:81 {
    reverse_proxy localhost:3000
}
```
Reload Caddy to apply the changes:
```bash
sudo systemctl reload caddy
```

### Step 4: Create Systemd Services

Create `systemd` services to run the Rails server and background jobs persistently.

**1. Rails Server Service**
Create the file `/etc/systemd/system/einthusanlib-web.service`:
```ini
[Unit]
Description=Einthusanlib Rails App
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/home/your-user/einthusanlib
Environment=RAILS_ENV=production
ExecStart=bundle exec rails server -b 127.0.0.1 -p 3000
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

**2. Background Jobs Service**
Create the file `/etc/systemd/system/einthusanlib-jobs.service`:
```ini
[Unit]
Description=Einthusanlib Background Jobs
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/home/your-user/einthusanlib
Environment=RAILS_ENV=production
ExecStart=bundle exec bin/jobs
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
**Important:** In both files, replace `your-user` and `/home/your-user/einthusanlib` with your actual username and project path.

### Step 5: Start Services

Enable and start the new services.
```bash
# Enable and start the services
sudo systemctl enable --now einthusanlib-web.service
sudo systemctl enable --now einthusanlib-jobs.service

# Verify they are running
sudo systemctl status einthusanlib-web.service
sudo systemctl status einthusanlib-jobs.service
```

### Step 6: Automatic Movie Fetching (Cron Job)

To automatically fetch recent movies, set up a cron job to run the rake task.

1. Open your crontab:
   ```sh
   crontab -e
   ```

2. Add the following line to run the task daily at midnight:
   ```plaintext
   0 0 * * * cd /home/your-user/einthusanlib && bin/rails movies:fetch_recent RAILS_ENV=production
   ```
   *Remember to use your correct project path.*

## ⚠️ Disclaimer

This application is for educational and personal use only. Users are responsible for complying with applicable laws and the terms of service of content providers. The authors are not responsible for any misuse of this software.