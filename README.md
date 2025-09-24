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

## ⚠️ Disclaimer

This application is for educational and personal use only. Users are responsible for complying with applicable laws and the terms of service of content providers. The authors are not responsible for any misuse of this software.

**Built with ❤️ using Ruby on Rails**
