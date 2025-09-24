# Einthusanlib Rails App

A modern Ruby on Rails web application that fetches, downloads, and streams movies from Einthusan with real-time progress updates.

## 🛠 Technology Stack

- **Backend**: Ruby on Rails 7.x
- **Database**: SQLite3
- **Styling**: Bootstrap 5
- **Real-time**: Action Cable (WebSockets) + Turbo Streams
- **Background Jobs**: ActiveJob with Async adapter
- **File Storage**: Active Storage
- **Movie Downloads**: youtube-dl / yt-dlp

## 📋 Prerequisites

- Ruby 3.x
- Rails 7.x
- Python 3.x (for youtube-dl)
- SQLite3

## 🚀 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/alameenkhader/einthusanlib.git
cd einthusanlib
```

### 2. Install Ruby Dependencies
```bash
bundle install
```

### 3. Setup Database
```bash
rails db:create
rails db:migrate
rails db:seed
```

### 4. Install Python Dependencies

#### Using Virtual Environment (Recommended)
```bash
python3 -m venv /app/venv
source /app/venv/bin/activate
pip install youtube-dl # or python3 -m pip install youtube-dl
```

## 🐳 Docker Installation (Alternative)

If you prefer using Docker for a containerized setup:

### 1. Start Docker Container
```bash
docker run -it -p 3000:3000 --name chalaflix -v $(pwd):/app -w /app ubuntu:latest bash
```

### 2. Install System Dependencies
```bash
apt-get update && apt-get install -y build-essential git sqlite3 libsqlite3-dev libyaml-dev nodejs npm ruby-full
```

### 3. Install Ruby Dependencies
```bash
bundle install
```

### 4. Setup Database
```bash
rails db:create
rails db:migrate
rails db:seed
```

### 5. Install Python Dependencies
```bash
apt-get install -y python3 python3-pip python3-venv
python3 -m venv /app/venv
source /app/venv/bin/activate
pip install youtube-dl
```

### 6. Start Rails Server
```bash
rails s -b 0.0.0.0
```

Visit `http://localhost:3000` to access the application.

## 🎯 Usage

### Start the Application
```bash
rails server
```

Visit `http://localhost:3000` to access the application.

## ⏰ Setting Up a Cron Job

To automatically fetch recent movies on a schedule, you can set up a cron job to run the rake task periodically:

1. Open the crontab file for editing:
   ```sh
   crontab -e
   ```

2. Add the following line to schedule the script to run every day at midnight:
   ```plaintext
   0 0 * * * cd /path/to/your/einthusanlib && rails movies:fetch_recent
   ```

3. For Docker environments, use:
   ```plaintext
   0 0 * * * docker exec chalaflix rails movies:fetch_recent
   ```

4. Save and close the crontab file.

## 🌐 Serving with Caddy

### 1. Install Caddy

#### On macOS
```bash
brew install caddy
```

#### On Linux (Ubuntu/Debian)
```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

### 2. How to serve using caddy (Production environment)

1. Update the Caddyfile:
  ```sh
  vi /etc/caddy/Caddyfile
  ```

2. Add the following configuration:
  ```plaintext
  :81 {
    reverse_proxy localhost:3000
  }

  # For production with domain
  # your-domain.com {
  #     reverse_proxy localhost:3000
  # }
  ```

3. **Configure Rails**
  ```bash
  RAILS_ENV=production rails db:migrate
  RAILS_ENV=production rails assets:precompile
  ```

3. **Start services:**
  ```bash
  # Start Rails in production
  RAILS_ENV=production rails server -b 127.0.0.1 -p 3000

  # Reload Caddy
  systemctl reload caddy
  ```

### 6. Systemd Service (Linux)

Create `/etc/systemd/system/einthusanlib.service`:

```ini
[Unit]
Description=Einthusanlib Rails App
After=network.target

[Service]
Type=simple
User=your-user
WorkingDirectory=/path/to/your/einthusanlib
Environment=RAILS_ENV=production
ExecStart=/usr/bin/rails server -b 127.0.0.1 -p 3000
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable einthusanlib
sudo systemctl start einthusanlib
sudo systemctl enable caddy
sudo systemctl start caddy
```

## ⚠️ Disclaimer

This application is for educational and personal use only. Users are responsible for complying with applicable laws and the terms of service of content providers. The authors are not responsible for any misuse of this software.

**Built with ❤️ using Ruby on Rails**
